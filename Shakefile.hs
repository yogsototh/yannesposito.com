{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

import           Protolude

import           Development.Shake
import           Development.Shake.Command
import           Development.Shake.FilePath
import           Development.Shake.Util

import           Control.Monad.Fail
import           Data.Aeson
import Text.Megaparsec
import           Data.Default ( Default(def) )
import qualified Data.Set as Set
import qualified Data.Text as T
import           Text.Mustache
import           Text.Pandoc.Class ( PandocPure, PandocMonad)
import qualified Text.Pandoc.Class as Pandoc
import           Text.Pandoc.Definition ( Pandoc(..)
                                        , Block(..)
                                        , Inline
                                        , nullMeta
                                        , docTitle
                                        , lookupMeta
                                        , docDate
                                        , docAuthors
                                        )
import           Text.Pandoc.Extensions ( getDefaultExtensions )
import           Text.Pandoc.Options ( ReaderOptions(..)
                                     , WriterOptions(..)
                                     , TrackChanges(RejectChanges)
                                     )
import qualified Text.Pandoc.Readers as Readers
import qualified Text.Pandoc.Templates as PandocTemplates
import qualified Text.Pandoc.Writers as Writers

main :: IO ()
main = shakeArgs shOpts buildRules
  where
    shOpts =
      shakeOptions
      { shakeVerbosity  = Chatty
      , shakeLintInside = ["\\"]
      }

-- Configuration
-- Should probably go in a Reader Monad

siteDir :: FilePath
siteDir  = "_site"

optimDir :: FilePath
optimDir = "_optim"

-- BlogPost data structure (a bit of duplication because the metas are in Pandoc)

data BlogPost =
  BlogPost { postTitle :: T.Text
           , postDate :: T.Text
           , postAuthors :: [T.Text]
           , postUrl :: FilePath
           , postToc :: Bool
           , postBody :: Pandoc
           }

inlineToText :: PandocMonad m => [Inline] -> m T.Text
inlineToText inline =
        Writers.writeAsciiDoc def (Pandoc nullMeta [Plain inline])

getBlogpostFromMetas
  :: (MonadIO m, MonadFail m) => [Char] -> Bool -> Pandoc -> m BlogPost
getBlogpostFromMetas path toc pandoc@(Pandoc meta _) = do
        eitherBlogpost <- liftIO $ Pandoc.runIO $ do
                title   <- inlineToText $ docTitle meta
                date    <- inlineToText $ docDate meta
                authors <- mapM inlineToText $ docAuthors meta
                return $ BlogPost title date authors path toc pandoc
        case eitherBlogpost of
                Left  _  -> fail "BAD"
                Right bp -> return bp

sortByPostDate :: [BlogPost] -> [BlogPost]
sortByPostDate =
        sortBy (\b a -> compare (Down (postDate a)) (Down (postDate b)))


build :: FilePath -> FilePath
build = (</>) siteDir

buildRules :: Rules ()
buildRules = do
        cleanRule
        allRule
        getPost <- mkGetPost
        getPosts <- mkGetPosts getPost
        getTemplate <- mkGetTemplate
        let cssDeps = map (siteDir </>) <$> getDirectoryFiles "src" ["css/*.css"]
            -- templateDeps = getDirectoryFiles "templates" ["*.mustache"]
        build "//*.html" %> \out -> do
          css <- cssDeps
          -- templates <- templateDeps
          template <- getTemplate ("templates" </> "main.mustache")
          let srcFile = "src" </> (dropDirectory1 (replaceExtension out "org"))
          liftIO $ putText $ "need: " <> (toS srcFile) <> " <- " <> (toS out)
          need $ css <> [srcFile]
          bp <- getPost srcFile
          eitherHtml <- liftIO $ Pandoc.runIO $ Writers.writeHtml5String (def { writerTableOfContents = (postToc bp) }) (postBody bp)
          case eitherHtml of
            Left _ -> fail "BAD"
            Right innerHtml ->
              let htmlContent = renderMustache template $ object [ "title" .= postTitle bp
                                                                 , "authors" .= postAuthors bp
                                                                 , "date" .= postDate bp
                                                                 , "body" .= innerHtml
                                                                 ]
              in writeFile' out (toS htmlContent)
        build "articles.html" %> \out -> do
                css   <- cssDeps
                posts <- getPosts ()
                need $ css <> map postUrl (sortByPostDate  posts)
                let titles = toS $ T.intercalate "\n" $ map postTitle posts
                writeFile' out titles
        build "css/*.css" %> \out -> do
          let src = "src" </> (dropDirectory1 out)
              dst = out
          liftIO $ putText $ toS $ "src:" <> src <> " => dst: " <> dst
          copyFile' src dst

allRule :: Rules ()
allRule =
  phony "all" $ do
    allOrgFiles <- getDirectoryFiles "src" ["//*.org"]
    let allHtmlFiles = map (flip replaceExtension "html") allOrgFiles
    need (map build (allHtmlFiles <> ["index.html", "articles.html"]))

cleanRule :: Rules ()
cleanRule =
  phony "clean" $ do
    putInfo "Cleaning files in _site and _optim"
    forM_ [siteDir,optimDir] $ flip removeFilesAfter ["//*"]

mkGetTemplate :: Rules (FilePath -> Action Template)
mkGetTemplate = newCache $ \path -> do
  fileContent <- readFile' path
  let res = compileMustacheText "page" (toS fileContent)
  case res of
    Left _ -> fail "BAD"
    Right template -> return template

tocRequested :: Text -> Bool
tocRequested fc =
  let toc = fc & T.lines
               & map T.toLower
               & filter (T.isPrefixOf (T.pack "#+options: "))
               & head
               & fmap (filter (T.isPrefixOf (T.pack "toc:")) . T.words)
  in toc == Just ["toc:t"]

mkGetPost :: Rules (FilePath -> Action BlogPost)
mkGetPost = newCache $ \path -> do
  fileContent  <- readFile' path
  let toc = tocRequested (toS fileContent)
  eitherResult <- liftIO $ Pandoc.runIO $ Readers.readOrg def (toS fileContent)
  case eitherResult of
    Left  _      -> fail "BAD"
    Right pandoc -> getBlogpostFromMetas path toc pandoc

mkGetPosts :: (FilePath -> Action b) -> Rules (() -> Action [b])
mkGetPosts getPost =
  newCache $ \() -> mapM getPost =<< getDirectoryFiles "" ["src/posts//*.org"]

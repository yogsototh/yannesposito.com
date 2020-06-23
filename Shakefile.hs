{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

import           Protolude

import           Development.Shake
import           Development.Shake.Command
import           Development.Shake.FilePath

import           Control.Monad.Fail
import           Data.Aeson
-- import qualified Text.Megaparsec as Megaparsec
import           Data.Default ( Default(def) )
import qualified Data.Text as T
import           Text.Mustache
import           Text.Pandoc.Class (PandocMonad)
import qualified Text.Pandoc.Class as Pandoc
import           Text.Pandoc.Definition ( Pandoc(..)
                                        , Block(..)
                                        , Inline
                                        , nullMeta
                                        , docTitle
                                        , docDate
                                        , docAuthors
                                        )
import           Text.Pandoc.Options ( ReaderOptions(..)
                                     , WriterOptions(..)
                                     , ObfuscationMethod(..)
                                     )
import qualified Text.Pandoc.Readers as Readers
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

srcDir :: FilePath
srcDir = "src"

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
        sortBy (\a b-> compare (Down (postDate a)) (Down (postDate b)))


build :: FilePath -> FilePath
build = (</>) siteDir

genAllDeps :: [FilePattern] -> Action [FilePath]
genAllDeps patterns = do
  allMatchedFiles <- getDirectoryFiles srcDir patterns
  allMatchedFiles &
    filter ((/= "html") . takeExtension) &
    filter (null . takeExtension) &
    map (siteDir </>)  &
    return

buildRules :: Rules ()
buildRules = do
  cleanRule
  -- build "//*" %> copy
  allRule
  getPost <- mkGetPost
  getPosts <- mkGetPosts getPost
  getTemplate <- mkGetTemplate
  alternatives $ do
    -- build "articles.html" %> \out -> do
    --         css   <- genAllDeps ["//*.css"]
    --         posts <- getPosts ()
    --         need $ css <> map postUrl (sortByPostDate posts)
    --         let titles = toS $ T.intercalate "\n" $ map postTitle posts
    --         writeFile' out titles
    build "//*.html" %> genHtmlAction getPost getTemplate
    -- build "//*.org" %> copy
    -- build "//*.jpg" %> copy

copy :: FilePath -> Action ()
copy out = do
  let src = srcDir </> (dropDirectory1 out)
  copyFileChanged src out

genHtml :: (MonadIO m, MonadFail m) => BlogPost -> m Text
genHtml bp = do
  eitherHtml <- liftIO $
    Pandoc.runIO $
      Writers.writeHtml5String
        (def { writerTableOfContents = (postToc bp)
             , writerEmailObfuscation = ReferenceObfuscation
             })
        (postBody bp)
  case eitherHtml of
    Left _ -> fail "BAD"
    Right innerHtml -> return innerHtml

genHtmlAction
  :: (FilePath -> Action BlogPost)
     -> (FilePath -> Action Template) -> [Char] -> Action ()
genHtmlAction getPost getTemplate out = do
  template <- getTemplate ("templates" </> "main.mustache")
  let srcFile = srcDir </> (dropDirectory1 (out -<.> "org"))
  liftIO $ putText $ "need: " <> (toS srcFile) <> " -> " <> (toS out)
  need [srcFile]
  bp <- getPost srcFile
  innerHtml <- genHtml bp
  let htmlContent =
        renderMustache template $ object [ "title" .= postTitle bp
                                         , "authors" .= postAuthors bp
                                         , "date" .= postDate bp
                                         , "body" .= innerHtml
                                         ]
  writeFile' out (toS htmlContent)

allHtmlAction :: Action ()
allHtmlAction = do
    allOrgFiles <- getDirectoryFiles srcDir ["//*.org"]
    let allHtmlFiles = map (-<.> "html") allOrgFiles
    need (map build (allHtmlFiles
                     -- <> ["articles.html"]
                    ))

compressImage :: CmdResult b => FilePath -> Action b
compressImage img = do
  let src = srcDir </> img
      dst = siteDir </> img
  need [src]
  let dir = takeDirectory dst
  dirExists <- doesDirectoryExist dir
  when (not dirExists) $
    command [] "mkdir" ["-p", dir]
  command [] "convert" [src
                       , "-strip"
                       , "-resize","320x320>"
                       , "-interlace","Plane"
                       , "-quality","85"
                       , "-define","filter:blur=0.75"
                       , "-filter","Gaussian"
                       , "-ordered-dither","o4x4,4"
                       , dst ]

allRule :: Rules ()
allRule =
  phony "all" $ do
    allAssets <- filter (/= ".DS_Store") <$> getDirectoryFiles srcDir ["//*.*"]
    forM_ allAssets $ \asset ->
      case (takeExtension asset) of
        ".jpg" -> compressImage asset
        ".jpeg" -> compressImage asset
        ".gif" -> compressImage asset
        ".png" -> compressImage asset
        _ -> copyFileChanged (srcDir </> asset) (siteDir </> asset)
    allHtmlAction

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
  eitherResult <- liftIO $ Pandoc.runIO $ Readers.readOrg (def { readerStandalone = True }) (toS fileContent)
  case eitherResult of
    Left  _      -> fail "BAD"
    Right pandoc -> getBlogpostFromMetas path toc pandoc

mkGetPosts :: (FilePath -> Action b) -> Rules (() -> Action [b])
mkGetPosts getPost =
  newCache $ \() -> mapM getPost =<< getDirectoryFiles "" ["src/posts//*.org"]

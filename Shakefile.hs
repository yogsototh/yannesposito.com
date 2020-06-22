{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

import           Protolude

import           Development.Shake
import           Development.Shake.Command
import           Development.Shake.FilePath
import           Development.Shake.Util

import           Control.Monad.Fail
import           Data.Default                   ( Default(def) )
import qualified Data.Set                      as Set
import qualified Data.Text                     as T
import           Text.Pandoc.Class              ( PandocPure
                                                , PandocMonad
                                                )
import qualified Text.Pandoc.Class             as Pandoc
import           Text.Pandoc.Definition         ( Pandoc(..)
                                                , Block(..)
                                                , Inline
                                                , nullMeta
                                                , docTitle
                                                , docDate
                                                , docAuthors
                                                )
import           Text.Pandoc.Extensions         ( getDefaultExtensions )
import           Text.Pandoc.Options            ( ReaderOptions(..)
                                                , TrackChanges(RejectChanges)
                                                )
import qualified Text.Pandoc.Readers           as Readers
import qualified Text.Pandoc.Writers           as Writers

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
           , postBody :: Pandoc
           }

inlineToText :: PandocMonad m => [Inline] -> m T.Text
inlineToText inline =
        Writers.writeAsciiDoc def (Pandoc nullMeta [Plain inline])

getBlogpostFromMetas
  :: (MonadIO m, MonadFail m) => [Char] -> Pandoc -> m BlogPost
getBlogpostFromMetas path pandoc@(Pandoc meta _) = do
        eitherBlogpost <- liftIO $ Pandoc.runIO $ do
                title   <- inlineToText $ docTitle meta
                date    <- inlineToText $ docDate meta
                authors <- mapM inlineToText $ docAuthors meta
                -- let url = dropExtension path
                return $ BlogPost title date authors path pandoc
        case eitherBlogpost of
                Left  _  -> fail "BAD"
                Right bp -> return bp

sortByPostDate :: [BlogPost] -> [BlogPost]
sortByPostDate =
        sortBy (\b a -> compare (Down (postDate a)) (Down (postDate b)))

buildRules :: Rules ()
buildRules = do
        let build = (</>) siteDir
        cleanRule
        getPost <- mkGetPost
        getPosts <- mkGetPosts getPost
        let cssDeps = map (siteDir </>) <$> getDirectoryFiles "" ["src/css/*.css"]
        build "index.html" %> \out -> do
                css   <- cssDeps
                posts <- getPosts ()
                need $ css <> map postUrl (sortByPostDate  posts)
                let titles = T.unpack $ T.intercalate "\n" $ map postTitle posts
                writeFile' out titles
        -- build "//*.html" %> \out -> do
        --   css <- cssDeps
        --   let orgfile = dropDirectory1 out
        --   post <- getPost orgfile
        build "src/css/*.css" %> \out -> copyFile' (dropDirectory1 out) out

cleanRule :: Rules ()
cleanRule =
  phony "clean" $ do
    putInfo "Cleaning files in _site and _optim"
    forM_ [siteDir,optimDir] $ flip removeFilesAfter ["//*"]

mkGetPost = newCache $ \path -> do
  fileContent  <- readFile' path
  eitherResult <- liftIO $ Pandoc.runIO $ Readers.readOrg def (T.pack fileContent)
  case eitherResult of
    Left  _      -> fail "BAD"
    Right pandoc -> getBlogpostFromMetas path pandoc

mkGetPosts getPost =
  newCache $ \() -> mapM getPost =<< getDirectoryFiles "" ["src/posts//*.org"]

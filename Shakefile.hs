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
main = do
        let
                shOpts = shakeOptions { shakeVerbosity  = Chatty
                                      , shakeLintInside = ["\\"]
                                      }
        shakeArgs shOpts buildRules

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
        sortBy (\a b -> compare (Down (postDate a)) (Down (postDate b)))

buildRules :: Rules ()
buildRules = do
        let     siteDir  = "_site"
                optimDir = "_optim"
                build    = (</>) siteDir
        phony "clean" $ do
                putInfo "Cleaning files in _site and _optim"
                removeFilesAfter siteDir  ["//*"]
                removeFilesAfter optimDir ["//*"]
        getPost <- newCache $ \path -> do
                fileContent  <- readFile' path
                eitherResult <- liftIO $ Pandoc.runIO $ Readers.readOrg
                        def
                        (T.pack fileContent)
                case eitherResult of
                        Left  _      -> fail "BAD"
                        Right pandoc -> getBlogpostFromMetas path pandoc
        getPosts <-
                newCache
                        $ \() -> mapM getPost =<< getDirectoryFiles
                                  ""
                                  ["src/posts//*.org"]
        let     -- hsDeps  = return ["AsciiArt.hs", "Index.hs", "Rot13.hs"]
                cssDeps = map (siteDir </>)
                        <$> getDirectoryFiles "" ["src/css/*.css"]
        build "index.html" %> \out -> do
                -- hs    <- hsDeps
                css   <- cssDeps
                posts <- getPosts ()
                need $ css <> map postUrl posts
                  -- <> [build "atom.xml"]
                let titles = map postTitle posts
                writeFile' out (mconcat (map T.unpack titles))
        build "src/css/*.css" %> \out -> copyFile' (dropDirectory1 out) out


--  "_site//*.html" %> buildPost
--  buildPosts
--  allPosts <- buildPosts
--  buildIndex allPosts
--  buildFeed allPosts
--  copyStaticFiles

-- data Post = Post { postTitle :: T.Text
--                  , postAuthor :: T.Text
--                  , postDate :: T.Text
--                  }
-- 
-- defaultReaderOpts t =
--   def { readerExtensions = getDefaultExtensions t
--       , readerStandalone = True }
-- 
-- orgToHTML :: T.Text -> PandocPure T.Text
-- orgToHTML txt = Readers.readOrg (defaultReaderOpts "org") txt
--   >>= Writers.writeHtml5String def
-- 
-- -- | Load a post, process metadata, write it to output, then return the post object
-- -- Detects changes to either post content or template
-- buildPost :: FilePath -> Action ()
-- buildPost out = do
--   let org = "src/" <> (dropDirectory1 $ out -<.> "org")
--   liftIO . putStrLn $ "Rebuilding post: " <> out
--   postContent <- readFile' org
--   -- load post content and metadata as JSON blob
--   let pandocReturn = Pandoc.runPure $ orgToHTML . T.pack $ postContent
--   case pandocReturn of
--     Left _ -> putError "BAD"
--     Right outData -> writeFile' out (T.unpack outData)

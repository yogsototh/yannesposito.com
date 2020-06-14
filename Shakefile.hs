{-# LANGUAGE OverloadedStrings #-}

import Development.Shake
import Development.Shake.Command
import Development.Shake.FilePath
import Development.Shake.Util

import Data.Default (Default(def))
import qualified Data.Set as Set
import qualified Data.Text as T
import           Text.Pandoc.Class (PandocPure)
import qualified Text.Pandoc.Class as Pandoc
import           Text.Pandoc.Extensions (getDefaultExtensions)
import           Text.Pandoc.Options (ReaderOptions(..),TrackChanges(RejectChanges))
import qualified Text.Pandoc.Readers as Readers
import qualified Text.Pandoc.Writers as Writers

main :: IO ()
main = do
  let shOpts = shakeOptions { shakeVerbosity = Chatty, shakeLintInside = ["\\"] }
  shakeArgs shOpts buildRules

buildRules :: Rules ()
buildRules = do
  phony "clean" $ do
    putInfo "Cleaning files in _site and _optim"
    removeFilesAfter "_site" ["//*"]
    removeFilesAfter "_optim" ["//*"]

  "_site//*.html" %> buildPost
--  buildPosts
--  allPosts <- buildPosts
--  buildIndex allPosts
--  buildFeed allPosts
--  copyStaticFiles

data Post = Post { postTitle :: T.Text
                 , postAuthor :: T.Text
                 , postDate :: T.Text
                 }

defaultReaderOpts t =
  def { readerExtensions = getDefaultExtensions t
      , readerStandalone = True }

orgToHTML :: T.Text -> PandocPure T.Text
orgToHTML txt = Readers.readOrg (defaultReaderOpts "org") txt
  >>= Writers.writeHtml5String def

-- | Load a post, process metadata, write it to output, then return the post object
-- Detects changes to either post content or template
buildPost :: FilePath -> Action ()
buildPost out = do
  let org = "src/" <> (dropDirectory1 $ out -<.> "org")
  liftIO . putStrLn $ "Rebuilding post: " <> out
  postContent <- readFile' org
  -- load post content and metadata as JSON blob
  let pandocReturn = Pandoc.runPure $ orgToHTML . T.pack $ postContent
  case pandocReturn of
    Left _ -> putError "BAD"
    Right outData -> writeFile' out (T.unpack outData)

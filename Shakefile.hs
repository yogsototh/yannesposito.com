{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

import           Protolude

import           Development.Shake
import           Development.Shake.FilePath

import           Data.Time.Format.ISO8601 (iso8601Show)
import qualified Data.Time.Clock as Clock

import           Control.Monad.Fail
import           Data.Aeson
import           Data.Default ( Default(def) )
import qualified Data.Text as T
import           Text.Mustache
import           Text.Pandoc.Class (PandocMonad)
import qualified Text.Pandoc.Class as Pandoc
import           Text.Pandoc.Definition ( Pandoc(..)
                                        , Block(..)
                                        , Inline(..)
                                        , MetaValue(..)
                                        , nullMeta
                                        , docTitle
                                        , docDate
                                        , docAuthors
                                        , lookupMeta
                                        )
import           Text.Pandoc.Options ( ReaderOptions(..)
                                     , WriterOptions(..)
                                     , ObfuscationMethod(..)
                                     , HTMLMathMethod(..)
                                     )

import qualified Text.Pandoc.Readers as Readers
import           Text.Pandoc.Walk (Walkable(..))
import qualified Text.Pandoc.Writers as Writers
import qualified Text.Pandoc.Templates as Templates

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
           , postAuthor :: T.Text
           , postUrl :: FilePath
           , postSrc :: FilePath
           , postTags :: [T.Text]
           , postDescr :: T.Text
           , postToc :: Bool
           , postBody :: Pandoc
           }

inlineToText :: PandocMonad m => [Inline] -> m T.Text
inlineToText inline =
        Writers.writeAsciiDoc def (Pandoc nullMeta [Plain inline])

reformatDate :: Text -> Text
reformatDate = T.takeWhile (/= ' ') . (T.dropAround dateEnvelope)
  where
    dateEnvelope ' ' = True
    dateEnvelope '\n' = True
    dateEnvelope '\t' = True
    dateEnvelope '[' = True
    dateEnvelope ']' = True
    dateEnvelope _ = False

getBlogpostFromMetas
  :: (MonadIO m, MonadFail m) => [Char] -> Bool -> Pandoc -> m BlogPost
getBlogpostFromMetas path toc pandoc@(Pandoc meta _) = do
        eitherBlogpost <- liftIO $ Pandoc.runIO $ do
                title   <- fmap (T.dropEnd 1) $ inlineToText $ docTitle meta
                date    <- fmap reformatDate $ inlineToText $ docDate meta
                author <- case head $ docAuthors meta of
                            Just m -> fmap T.strip $ inlineToText m
                            Nothing -> return ""
                let tags = tagsToList $ lookupMeta "keywords" meta
                    description = descr $ lookupMeta "description" meta
                    url = "/" </> dropDirectory1 path -<.> "org"
                return $ BlogPost title date author url path tags description toc pandoc
        case eitherBlogpost of
                Left  _  -> fail "BAD"
                Right bp -> return bp
  where
    tagsToList (Just (MetaList ms)) = map toStr ms
    tagsToList _ = []
    descr (Just (MetaString t)) = t
    descr _ = ""
    toStr (MetaString t) = t
    toStr (MetaInlines inlines) = T.intercalate " " $ map inlineToTxt inlines
    toStr _ = ""
    inlineToTxt (Str t) = t
    inlineToTxt _ = ""



sortByPostDate :: [BlogPost] -> [BlogPost]
sortByPostDate =
        sortBy (\a b-> compare (postDate b) (postDate a))


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
  fastRule
  allRule
  fullRule
  getPost <- mkGetPost
  getPosts <- mkGetPosts getPost
  getTemplate <- mkGetTemplate
  build "**" %> \out -> do
    let asset = dropDirectory1 out
    case (takeExtension asset) of
        ".html" -> do
          if out == siteDir </> "archive.html"
            then buildArchive getPosts getTemplate out
            else genHtmlAction getPost getTemplate out
        ".pdf" -> do
          txtExists <- doesFileExist (srcDir </> asset)
          if txtExists
            then copyFileChanged (srcDir </> asset) out
            else genPdfAction getPost out
        ".txt" -> do
          fileExists <- doesFileExist (srcDir </> asset)
          if fileExists
            then copyFileChanged (srcDir </> asset) out
            else genAsciiAction getPost out
        ".gmi" -> genGeminiAction getPost out
        ".jpg" -> compressImage asset
        ".jpeg" -> compressImage asset
        ".gif" -> compressImage asset
        ".png" -> compressImage asset
        _ -> copyFileChanged (srcDir </> asset) out
  optimDir </> "rss.xml" %> \_ -> do
    needAll
    command_[] "engine/pre-deploy.sh" []

buildArchive
  :: (() -> Action [BlogPost])
     -> (FilePath -> Action Template) -> [Char] -> Action ()
buildArchive getPosts getTemplate out = do
  css   <- genAllDeps ["//*.css"]
  posts <- fmap sortByPostDate $ getPosts ()
  need $ css <> map postSrc posts
  let
    title :: Text
    title = "#+title: Posts"
    articleList = toS $ T.intercalate "\n" $ map postInfo posts
    fileContent =  title <> "\n\n" <> articleList
  eitherResult <- liftIO $ Pandoc.runIO $ Readers.readOrg (def { readerStandalone = True }) (toS fileContent)
  bp <- case eitherResult of
    Left  _      -> fail "BAD"
    Right pandoc -> getBlogpostFromMetas out False pandoc
  innerHtml <- genHtml bp
  template <- getTemplate ("templates" </> "main.mustache")
  let htmlContent =
        renderMustache template
          $ object [ "title" .= postTitle bp
                   , "author" .= postAuthor bp
                   , "date" .= postDate bp
                   , "tags" .= postTags bp
                   , "description" .= postDescr bp
                   , "body" .= innerHtml
                   ]
  writeFile' out (toS htmlContent)

postInfo :: BlogPost -> Text
postInfo bp =
  "- " <> date <> ": " <> orglink
  where
    date = T.takeWhile (/= ' ') (postDate bp)
    orglink = "[[file:" <> (toS (postUrl bp)) <> "][" <> (postTitle bp) <> "]]"

replaceLinks :: Pandoc -> Pandoc
replaceLinks = walk replaceOrgLink
  where
    replaceOrgLink :: Inline -> Inline
    replaceOrgLink lnk@(Link attr inl (url,txt)) =
      if takeExtension (toS url) == ".org"
      then Link attr inl ((toS (toS url -<.> ".html")),txt)
      else lnk
    replaceOrgLink x = x

orgContentToText :: (MonadIO m, MonadFail m) => Text -> m Text
orgContentToText org = do
  eitherResult <- liftIO $ Pandoc.runIO $ Readers.readOrg (def { readerStandalone = True }) org
  pandoc <- case eitherResult of
              Left  _      -> fail "BAD"
              Right p -> return p
  eitherHtml <- liftIO $ Pandoc.runIO $
    Writers.writeHtml5String (def {writerEmailObfuscation = ReferenceObfuscation}) pandoc
  case eitherHtml of
    Left _ -> fail "BAD"
    Right innerHtml -> return innerHtml

postamble :: (MonadIO m, MonadFail m) => Text -> BlogPost -> m Text
postamble now bp =
  orgContentToText $ unlines $
  [ "@@html:<footer>@@"
  , "@@html:<i>Any comment? Click on my email below and I'll add it.</i>@@"
  , ""
  , "| author | @@html:<span class=\"author\">@@ [[mailto:Yann Esposito <yann@esposito.host>?subject=yblog: " <> (postTitle bp) <> "][Yann Esposito <yann@esposito.host>]] @@html:</span>@@ |"
  , "| tags | " <> T.intercalate " " (map ("#"<>) (postTags bp)) <> " |"
  , "| date | " <> postDate bp <> " |"
  , "| rss | [[file:/rss.xml][RSS]] ([[https://validator.w3.org/feed/check.cgi?url=https%3A%2F%2Fher.esy.fun%2Frss.xml][validate]]) |"
  , "| size | @@html:<span class=\"web-file-size\">XXK (html XXK, css XXK, img XXK)</span>@@ |"
  , "| gz | @@html:<span class=\"gzweb-file-size\">XXK (html XXK, css XXK, img XXK)</span>@@ |"
  , "| generated | " <> now <> " |"
  , ""
  , "@@html:</footer>@@"
  ]

tpltxt :: Text
tpltxt = T.unlines [
  "$if(toc)$"
  , "<nav id=\"$idprefix$TOC\" role=\"doc-toc\">"
  , "$if(toc-title)$"
  , "<h2 id=\"$idprefix$toc-title\">$toc-title$</h2>"
  , "$endif$"
  , "$table-of-contents$"
  , "</nav>"
  , "$endif$"
  , "$body$"
  ]

getPostTpl :: IO (Templates.Template Text)
getPostTpl = do
    etpl <- Templates.compileTemplate "blog.template" tpltxt
    case etpl of
      Left e -> fail e
      Right tpl -> return tpl

genHtml :: (MonadIO m, MonadFail m) => BlogPost -> m Text
genHtml bp = do
  let htmlBody = replaceLinks (postBody bp)
  eitherHtml <- liftIO $ do
    tpl <- getPostTpl
    Pandoc.runIO $ do
      Writers.writeHtml5String
        (def { writerTableOfContents = postToc bp
             , writerTemplate = Just tpl
             , writerTOCDepth = 3
             , writerEmailObfuscation = ReferenceObfuscation
             , writerHTMLMathMethod = MathML
             })
        htmlBody
  body <- case eitherHtml of
    Left _ -> fail "BAD"
    Right innerHtml -> return innerHtml
  now <- liftIO Clock.getCurrentTime
  footer <- postamble (toS (iso8601Show now)) bp
  return (body <> footer)

origin :: Text
origin = "https://her.esy.fun"

genHtmlAction
  :: (FilePath -> Action BlogPost)
     -> (FilePath -> Action Template) -> [Char] -> Action ()
genHtmlAction getPost getTemplate out = do
  let tplname = case takeDirectory1 (dropDirectory1 out) of
                  "posts" -> "post.mustache"
                  "slides" -> "slide.mustache"
                  "drafts" -> "post.mustache"
                  _ -> "main.mustache"
  template <- getTemplate ("templates" </> tplname)
  let srcFile = srcDir </> (dropDirectory1 (out -<.> "org"))
  liftIO $ putText $ "need: " <> (toS srcFile) <> " -> " <> (toS out)
  need [srcFile]
  bp <- getPost srcFile
  innerHtml <- genHtml bp
  let htmlContent =
        renderMustache template
          $ object [ "title" .= postTitle bp
                   , "author" .= postAuthor bp
                   , "date" .= postDate bp
                   , "tags" .= postTags bp
                   , "description" .= postDescr bp
                   , "body" .= innerHtml
                   , "orgsource" .= T.pack (postUrl bp -<.> "org")
                   , "txtsource" .= T.pack (postUrl bp -<.> "txt")
                   , "pdf" .= T.pack (postUrl bp -<.> "pdf")
                   , "permalink" .= T.pack (toS origin <> postUrl bp -<.> "html")
                   ]
  writeFile' out (toS htmlContent)

genAscii :: (MonadIO m, MonadFail m) => BlogPost -> m Text
genAscii bp = do
  eitherAscii <- liftIO $ Pandoc.runIO $ Writers.writePlain def (postBody bp)
  case eitherAscii of
    Left _ -> fail "BAD"
    Right innerAscii -> return innerAscii


genAsciiAction
  :: (FilePath -> Action BlogPost)
     -> [Char] -> Action ()
genAsciiAction getPost out = do
  let srcFile = srcDir </> (dropDirectory1 (out -<.> "org"))
  need [srcFile]
  bp <- getPost srcFile
  innerAscii <- genAscii bp
  let preamble = postTitle bp <> "\n"
                 <> T.replicate (T.length (postTitle bp)) "=" <> "\n\n"
                 <> postAuthor bp <> "\n"
                 <> postDate bp <> "\n"
                 <> toS origin <> toS (postUrl bp) <> "\n\n"
  writeFile' out (toS  (preamble <> toS innerAscii))

genPdfAction :: p -> [Char] -> Action ()
genPdfAction _getPost out = do
  let srcFile = srcDir </> (dropDirectory1 (out -<.> "org"))
  need [srcFile]
  command_ [] "pandoc"
    ["--pdf-engine=xelatex"
    , "--resource-path=" <> takeDirectory srcFile
    , srcFile
    , "-H", "engine" </> "deeplist.tex"
    , "-V", "mainfont:Hoefler Text"
    , "-V", "monofont:Menlo"
    , "-V", "monofontoptions:Scale=0.7"
    , "-o", out ]


genGemini :: (MonadIO m, MonadFail m) => BlogPost -> m Text
genGemini bp = do
  eitherAscii <- liftIO $ Pandoc.runIO $ Writers.writePlain def (postBody bp)
  case eitherAscii of
    Left _ -> fail "BAD"
    Right innerAscii -> return innerAscii

genGeminiAction
  :: (FilePath -> Action BlogPost)
     -> [Char] -> Action ()
genGeminiAction getPost out = do
  let srcFile = srcDir </> (dropDirectory1 (dropDirectory1 (out -<.> "org")))
  need [srcFile]
  bp <- getPost srcFile
  innerGemini <- genGemini bp
  let preamble = "# " <> postTitle bp <> "\n"
                 <> postAuthor bp <> "\n"
                 <> postDate bp <> "\n"
                 <> toS origin <> toS (postUrl bp) <> "\n\n"
  writeFile' out (toS  (preamble <> toS innerGemini))

allHtmlAction :: Action ()
allHtmlAction = do
    allOrgFiles <- getDirectoryFiles srcDir ["//*.org"]
    let allHtmlFiles = map (-<.> "html") allOrgFiles
    need (map build allHtmlFiles)

allPdfAction :: Action ()
allPdfAction = do
    allOrgFiles <- getDirectoryFiles srcDir ["//*.org"]
    let allHtmlFiles = map (-<.> "pdf") allOrgFiles
    need (map build allHtmlFiles)

allAsciiAction :: Action ()
allAsciiAction = do
    allOrgFiles <- getDirectoryFiles srcDir ["//*.org"]
    let allAsciiFiles = map (-<.> "txt") allOrgFiles
    need (map build allAsciiFiles)

allGeminiAction :: Action ()
allGeminiAction = do
    allOrgFiles <- getDirectoryFiles srcDir ["//*.org"]
    let allGeminiFiles = map (("gemini" </>) . (-<.> "gmi")) allOrgFiles
    need (map build allGeminiFiles)

compressImage :: FilePath -> Action ()
compressImage img = do
  let src = srcDir </> img
      dst = siteDir </> img
  need [src]
  let dir = takeDirectory dst
  dirExists <- doesDirectoryExist dir
  when (not dirExists) $
    command [] "mkdir" ["-p", dir]
  command_ [] "convert" [ src
                        , "-strip"
                        , "-resize","960x960>"
                        , "-interlace","Plane"
                        , "-quality","85"
                        , "-define","filter:blur=0.75"
                        , "-filter","Gaussian"
                        , "-ordered-dither","o4x4,4"
                        , dst ]


needFast :: Action ()
needFast = do
  allAssets <- filter (/= ".DS_Store") <$> getDirectoryFiles srcDir ["**"]
  need (map build $ allAssets <> ["archive.html"])
  allHtmlAction

fastRule :: Rules ()
fastRule =
  withTargetDocs "generate html" $
  phony "fast" $
  needFast

needAll :: Action ()
needAll = do
  needFast
  allAsciiAction
  allPdfAction
  allGeminiAction

allRule :: Rules ()
allRule =
  withTargetDocs "generate all, no optim" $
  phony "all" $
  needAll

fullRule :: Rules ()
fullRule =
  withTargetDocs "generate all and optim" $
  phony "full" $
  need [optimDir </> "rss.xml"]

cleanRule :: Rules ()
cleanRule =
  phony "clean" $ do
    putInfo "Cleaning files in _site and _optim"
    forM_ [siteDir,optimDir] $ flip removeFilesAfter ["**"]

mkGetTemplate :: Rules (FilePath -> Action Template)
mkGetTemplate = newCache $ \path -> do
  fileContent <- readFile' path
  header <- readFile' ("templates" </> "header.mustache")
  menu   <- readFile' ("templates" </> "menu.mustache")
  let withIncludes = fileContent & toS & T.replace "{{>header}}" (toS header) & T.replace "{{>menu}}" (toS menu)
      res = compileMustacheText "page" (toS withIncludes)
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

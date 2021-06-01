#!/usr/bin/env runhaskell

 {-# LANGUAGE OverloadedStrings #-}
import Turtle

import Prelude hiding (FilePath)
import qualified Control.Foldl as Fold
import Data.Maybe (fromMaybe)
import System.Console.ANSI
import Turtle.Line (unsafeTextToLine)
import Control.Exception (catches,Handler(..))

main = mainProc `catches` [ Handler handleShellFailed
                          , Handler handleProcFailed
                          ]

handleShellFailed :: ShellFailed -> IO ()
handleShellFailed (ShellFailed cmdLine _) = do
  setSGR [SetColor Foreground Dull Red]
  echo $ ("[FAILED]: " <> unsafeTextToLine  cmdLine)
  setSGR [Reset]
handleProcFailed :: ProcFailed -> IO ()
handleProcFailed (ProcFailed procCmd procArgs _) = do
  setSGR [SetColor Foreground Dull Red]
  echo $ unsafeTextToLine ("[FAILED]: " <> procCmd <> (mconcat procArgs))
  setSGR [Reset]


mainProc :: IO ()
mainProc = do
  -- So we can't have access to $0 in Haskell via stack.
  -- Too bad.
  -- So instead, I'll check I'm in the right directory.
  debug "Checking directory"
  pubdir <- checkDir
  debug "Retrieving revision number"
  rev <- fold (inshell "git rev-parse --short HEAD" empty) Fold.head
  debug ("Revision number retrieved: " <> fromMaybe "unknow" rev)
  debug $ unsafeTextToLine $ "cd " <> (format fp pubdir)
  cd pubdir
  pwd >>= echo . unsafeTextToLine . format fp
  dshells "rm -rf .git"
  dshells "git init ."
  dshell ("git remote add upstream " <> mainRepository)
  dshells "git fetch --depth 1 upstream gh-pages"
  dshells "git reset upstream/gh-pages"
  dshells "git add -A ."
  echo "Commit and publish"
  dshells ("git commit -m \"publishing at rev " <> lineToText (fromMaybe "unknow" rev) <> "\"")
  echo "Don't `git push` this time"
  dshells "git push -q upstream HEAD:gh-pages"

debug :: Line -> IO ()
debug txt = do
  setSGR [SetColor Foreground Dull Yellow]
  echo txt
  setSGR [Reset]

dshells :: Text -> IO ()
dshells x = do
  debug $ unsafeTextToLine x
  shells x empty

dshell :: Text -> IO ExitCode
dshell x = do
  debug $ unsafeTextToLine x
  shell x empty

checkDir :: IO FilePath
checkDir = do
  toolsExists <- testdir "engine"
  if (not toolsExists)
     then exit (ExitFailure 1)
     else return "_site"

mainRepository :: Text
mainRepository = "git@github.com:yogsototh/yannesposito.com.git"

cloneIfNeeded :: FilePath -> IO ()
cloneIfNeeded pubdir = do
  contentExists <- testdir pubdir
  when (not contentExists) $
       procs "git"
             [ "clone"
             , "-b", "gh-pages"
             , mainRepository
             , format fp pubdir]
             empty

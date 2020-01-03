{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Protolude

import qualified MyLib (someFunc)

main :: IO ()
main = do
  putText "Hello Haskell!"
  MyLib.someFunc

{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Protolude

import qualified MyLib (genPassword)

main :: IO ()
main = do
  pwd <- MyLib.genPassword
  putText pwd

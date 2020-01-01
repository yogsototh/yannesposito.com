{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module MyLib (genPassword) where

import           Protolude

import           Data.Char     (chr,ord)
import qualified System.Random as Random

genPassword :: IO Text
genPassword = do
  let stdgen = Random.mkStdGen 0
      numbers = take 10 (Random.randoms stdgen)
      password = toS [ chr ( (n `mod` 27) + ord 'a') | n <- numbers ]
  return password

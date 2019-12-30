{-# LANGUAGE NoImplicitPrelude #-}
module MyLib (someFunc) where

import Protolude

someFunc :: IO ()
someFunc = putStrLn "someFunc"

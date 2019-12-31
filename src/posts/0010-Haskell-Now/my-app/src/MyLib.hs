{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
module MyLib (someFunc) where

import Protolude

someFunc :: IO ()
someFunc = putText "someFunc"

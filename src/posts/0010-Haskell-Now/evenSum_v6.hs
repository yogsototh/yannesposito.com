-- Version 6
-- foldl' isn't accessible by default
-- we need to import it from the module Data.List
import Data.List
evenSum l = foldl' mysum 0 (filter even l)
  where mysum acc value = acc + value

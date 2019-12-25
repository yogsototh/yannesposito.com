-- Version 7
-- Generally it is considered a good practice
-- to import only the necessary function(s)
import Data.List (foldl')
evenSum l = foldl' (\x y -> x+y) 0 (filter even l)

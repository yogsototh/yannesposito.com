import Data.Maybe
import Text.Read (readMaybe)

getListFromString :: String -> Maybe [Integer]
getListFromString str = readMaybe $ "[" ++ str ++ "]"

askUser :: IO [Integer]
askUser = do
  putStrLn "Enter a list of numbers (separated by comma):"
  input <- getLine
  let maybeList = getListFromString input
  case maybeList of
      Just l  -> return l
      Nothing -> askUser

main :: IO ()
main = do
  list <- askUser
  print $ sum list

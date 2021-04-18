import Data.Maybe
import Text.Read (readMaybe)

getListFromString :: String -> Maybe [Integer]
getListFromString str = readMaybe $ "[" ++ str ++ "]"

main :: IO ()
main = do
  putStrLn "Enter a list of numbers (separated by comma):"
  input <- getLine
  let maybeList = getListFromString input
  case maybeList of
    Just l  -> print (sum l)
    Nothing -> putStrLn "Bad format. Good Bye."

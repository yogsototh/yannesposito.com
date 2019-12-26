import Data.Maybe
import Text.Read (readMaybe)

getListFromString :: String -> Maybe [Integer]
getListFromString str = readMaybe $ "[" ++ str ++ "]"
askUser :: IO [Integer]
askUser =
    putStrLn "Enter a list of numbers (sep. by commas):" >>
    getLine >>= \input ->
    let maybeList = getListFromString input in
      case maybeList of
        Just l -> return l
        Nothing -> askUser

main :: IO ()
main = askUser >>=
  \list -> print $ sum list

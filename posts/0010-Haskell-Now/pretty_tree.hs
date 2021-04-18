import           Data.Tree (Tree,Forest(..))
import qualified Data.Tree as Tree

data BinTree a = Empty
               | Node a (BinTree a) (BinTree a)
               deriving (Eq,Ord,Show)

treeFromList :: (Ord a) => [a] -> BinTree a
treeFromList [] = Empty
treeFromList (x:xs) = Node x (treeFromList (filter (<x) xs))
                      (treeFromList (filter (>x) xs))

-- | Function to transform our internal BinTree type to the
-- type of Tree declared in Data.Tree (from containers package)
-- so that the function Tree.drawForest can use
binTreeToForestString :: (Show a) => BinTree a -> Forest String
binTreeToForestString Empty = []
binTreeToForestString (Node x left right) =
  [Tree.Node (show x) ((binTreeToForestString left) ++ (binTreeToForestString right))]

-- | Function that given a BinTree print a representation of it in the console
prettyPrintTree :: (Show a) => BinTree a -> IO ()
prettyPrintTree = putStrLn . Tree.drawForest . binTreeToForestString

main = do
  putStrLn "Int binary tree:"
  prettyPrintTree $ treeFromList [7,2,4,8,1,3,6,21,12,23]
  putStrLn "\nNote we could also use another type\n"
  putStrLn "String binary tree:"
  prettyPrintTree $
    treeFromList ["foo","bar","baz","gor","yog"]
  putStrLn "\nAs we can test equality and order trees, we can make tree of trees!\n"
  putStrLn "\nBinary tree of Char binary trees:"
  prettyPrintTree (treeFromList
                    (map treeFromList ["foo","bar","zara","baz","foo"]))

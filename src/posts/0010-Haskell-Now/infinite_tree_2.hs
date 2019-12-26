  import           Data.Tree (Tree,Forest(..))
  import qualified Data.Tree as Tree

  data BinTree a = Empty
                 | Node a (BinTree a) (BinTree a)
                 deriving (Eq,Ord,Show)

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

  -- | take all element of a BinTree up to some depth
  treeTakeDepth _ Empty = Empty
  treeTakeDepth 0 _     = Empty
  treeTakeDepth n (Node x left right) = let
            nl = treeTakeDepth (n-1) left
            nr = treeTakeDepth (n-1) right
            in
                Node x nl nr

iTree = Node 0 (dec iTree) (inc iTree)
        where
           dec (Node x l r) = Node (x-1) (dec l) (dec r)
           inc (Node x l r) = Node (x+1) (inc l) (inc r)

-- apply a function to each node of Tree
treeMap :: (a -> b) -> BinTree a -> BinTree b
treeMap f Empty = Empty
treeMap f (Node x left right) = Node (f x)
                                     (treeMap f left)
                                     (treeMap f right)

infTreeTwo :: BinTree Int
infTreeTwo = Node 0 (treeMap (\x -> x-1) infTreeTwo)
                    (treeMap (\x -> x+1) infTreeTwo)

main = prettyPrintTree $ treeTakeDepth 4 infTreeTwo

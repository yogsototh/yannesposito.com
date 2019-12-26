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

nullTree = Node 0 nullTree nullTree

-- take all element of a BinTree
-- up to some depth
treeTakeDepth _ Empty = Empty
treeTakeDepth 0 _     = Empty
treeTakeDepth n (Node x left right) = let
          nl = treeTakeDepth (n-1) left
          nr = treeTakeDepth (n-1) right
          in
              Node x nl nr

main = prettyPrintTree (treeTakeDepth 4 nullTree)

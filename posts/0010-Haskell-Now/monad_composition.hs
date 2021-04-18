import Control.Monad ((>=>))

f :: Int -> [Int]
f n = [n, n+1]

g :: Int -> [String]
g n = [show n,">"++show (n+1)]

main = print $ (f >=> g) 2

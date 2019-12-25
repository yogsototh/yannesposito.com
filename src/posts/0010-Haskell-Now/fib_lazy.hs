fib :: [Integer]
fib = 1:1:zipWith (+) fib (tail fib)

main = traverse_ print (take 20 (drop 200 fib))

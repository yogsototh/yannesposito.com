import Debug.Trace

-- like + but each time this is evaluated print a trace
tracedPlus x y = trace ("> " ++ show x ++ " + " ++ show y) (x + y)

fib :: [Integer]
fib = 1:1:zipWith tracedPlus fib (tail fib)

main = do
  print (fib !! 10)
  print (fib !! 12)

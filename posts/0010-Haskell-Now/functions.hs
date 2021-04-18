square :: Num a => a -> a
square x = x^2

square' x = (^) x 2

square'' x = (^2) x

square''' = (^2)

absolute :: (Ord a, Num a) => a -> a
absolute x = if x >= 0 then x else -x

absolute' x
    | x >= 0 = x
    | otherwise = -x

main = do
      print $ square 10
      print $ square' 10
      print $ square'' 10
      print $ square''' 10
      print $ absolute 10
      print $ absolute (-10)
      print $ absolute' 10
      print $ absolute' (-10)

data Expr = Num Double
          | Var Name
          | Mul Expr Expr
          | Add Expr Expr
          | Sin Expr
          | Cos Expr

type Name = String

instance Arbitrary Expr where
  arbitrary = sized arbExpr

instance Show Expr where
   show = showExpr

showExpr :: Expr -> String
showExpr (Num f )     = show f
showExpr (Mul m n)    = show m ++ "*" ++ show n
showExpr (Add m n)    =
  case m of
    (Mul _ _) -> case n of
      (Mul _ _) -> "(" ++ show m ++ ") + (" ++ show n ++ ")"
      otherwise  -> "(" ++ show m ++ ") +" ++ show n
    otherwise -> show m ++ "+" ++ show n
showExpr (Sin x)      =
  case x of
    (Mul _ _ ) -> "Sin(" ++ show x ++ ")"
    (Add _ _ ) ->  "Sin(" ++ show x ++ ")"
    otherwise -> "Sin" ++ show x
showExpr (Cos x)      =
  case x of
    (Mul _ _ ) -> "Cos(" ++ show x ++ ")"
    (Add _ _ ) ->  "Cos(" ++ show x ++ ")"
    otherwise -> "Cos" ++ show x
showExpr (Var x)      = x

eval :: Expr -> Double -> Double
eval (Num n) k      = n
eval (Var x) k      = k
eval (Mul m n) k    = (eval m k) * (eval n k)
eval (Add n m) k    = (eval n k) + (eval m k)
eval (Sin n) k      = sin (eval n k)
eval (Cos n) k      = cos (eval n k)


prop_showReadExpression :: Expr -> Bool
prop_showReadExpression expr = stringsEqual (readExpr expr) (showExpr expr)
        where
          stringsEqual :: String -> String -> Bool
          stringsEqual (x,[]) (y,[]) = x==y
          stringsEqual [] _ = false
          stringsEqual _ [] = false
          stringsEqual (x:xs) (y:ys) = x==y && stringsEqual xs ys

arbExpr :: Int -> Gen Expr
arbExpr oneof[rMul,rAdd,rBin]
    where
      rMul = undefined

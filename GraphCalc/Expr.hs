import Parsing
import Data.Maybe
import Test.QuickCheck

data Expr = Num Double
          | Var Name
          | Mul Expr Expr
          | Add Expr Expr
          | Sin Expr
          | Cos Expr
          deriving(Eq)

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
      (Mul _ _) -> "(" ++ show m ++ ")+(" ++ show n ++ ")"
      otherwise  -> "(" ++ show m ++ ")+" ++ show n
    otherwise -> show m ++ "+" ++ show n
showExpr (Sin x)      =
  case x of
    (Mul _ _ ) -> "sin(" ++ show x ++ ")"
    (Add _ _ ) ->  "sin(" ++ show x ++ ")"
    otherwise -> "sin" ++ show x
showExpr (Cos x)      =
  case x of
    (Mul _ _ ) -> "cos(" ++ show x ++ ")"
    (Add _ _ ) ->  "cos(" ++ show x ++ ")"
    otherwise -> "cos" ++ show x
showExpr (Var x)      = x

eval :: Expr -> Double -> Double
eval (Num n) k      = n
eval (Var x) k      = k
eval (Mul m n) k    = (eval m k) * (eval n k)
eval (Add n m) k    = (eval n k) + (eval m k)
eval (Sin n) k      = sin (eval n k)
eval (Cos n) k      = cos (eval n k)



readExpr :: String -> Expr
readExpr input = fst (fromJust (parse expr input))

{-
digit   ::= {1..9}
number  ::= digit{digit}
-}

number :: Parser Double
number = do n <- oneOrMore digit
            return (read n)

{-
char      ::= {a..Z}
string    ::= char{char}
-}

string :: String -> Parser String
string str = do c <- sequence [char s | s <- str]
                return c

{- BNF:
expr      ::= term "+" expr | term.
term      ::= factor "*" term | factor.
factor    ::= number | "(" expr ")" | function.
function  ::= "sin" number | "sin(" expr ")" | "cos" number | "cos(" expr ")"
-}

expr, term, factor, function :: Parser Expr

expr = leftAssoc Add term (char '+')

term = leftAssoc Mul factor (char '*')

factor = (Num <$> readsP) <|> char '(' *> expr <* char ')' <|> function <|> (Var <$> (string "x"))

function = (Sin <$> (string "sin" *> factor)) <|> (Cos <$> (string "cos" *> factor))
            <|> (Sin <$> (string "sin(" *> expr <* char ')')) <|> (Cos <$> (string "cos(" *> expr <* char ')'))

leftAssoc :: (t->t->t) -> Parser t -> Parser sep -> Parser t
leftAssoc op item sep = do  i:is <- chain item sep
                            return (foldl op i is)

prop_showReadExpression :: Double -> Expr -> Bool
prop_showReadExpression n expr =  (eval (readExpr (showExpr expr)) n) ~== (eval expr n)

(~==) :: Double -> Double -> Bool
(~==) x y = (abs(x-y)) <= eps
          where
            eps = 10


range = 100

arbExpr :: Int -> Gen Expr
arbExpr size = frequency [(1,rNum), (1, rVar), (size, rBin size), (size, rFunc size)]
  where
    rNum = elements [Num n | n<-[1..range]]
    rVar = elements [Var n |n <-["x"]]
    rBin size = do op <- elements[Add,Mul]
                   e1 <- arbExpr (size `div` 2)
                   e2 <- arbExpr (size `div` 2)
                   return (op e1 e2)
    rFunc size = do op <- elements[Sin,Cos]
                    e1 <- arbExpr (size `div` 2)
                    return (op e1 )

> {-# LANGUAGE GeneralizedNewtypeDeriving #-}  -- necessário para: deriving(Num)

> import Control.Applicative
> import qualified Data.List as DL
> import Data.Ratio                 -- Rational

--------------------------------------------------------------------

No capítulo 8 falamos sobre tipos e como definir tipos novos 
especializados para as nossas aplicações.

--------------------------------------------------------------------

A forma mais simples é o que se chama de sinónimos de tipo (type
synonyms) onde apenas se associa um novo nome a um tipo já existente. 

A sintaxe é:

  type <sinónimo> = <tipo já existente>

Nós temos usado um destes sinónimos definido no Prelude:

  type String = [Char]
  
Assim, as funções que recebem listas de chars podem ser também
descritas como recebendo strings. Para o Haskell é a mesma coisa. 
Um eg:

> ttail :: String -> [Char]
> ttail xs = tail (tail xs)

Main> ttail "abc"
"c"

Isto é possível porque o 'type' não cria novos tipos, só cria
novos nomes para algo que já existe.

Normalmente o objectivo do 'type' é melhorar a legibilidade 
do código, nomeadamente das assinaturas das funções.

O 'type' também funciona com tipos polimórficos, ie, com os 
'a's e 'b's que surgem nas assinaturas das funções polimórficas.

Por exemplo, se quisermos retirar a 2a componente de um triplo,
poderíamos fazer desta forma:

> get2nd :: (a,b,c) -> b
> get2nd (_,y,_) = y

Reparem que a função get2nd é polimórfica, as componentes do
triplo podem ser de qualquer tipo.

Podemos definir um sinónimo para este tuplo para ser mais
fácil ler o código:

> type Triplo a b c = (a,b,c)

E agora a nossa função ficaria:

> get2nd' :: Triplo a b c -> b
> get2nd' (_,y,_) = y

Estas duas definições são idênticas:

Main> get2nd (1,'a',False)
'a'

Main> get2nd' (1,'a',False)
'a'

Se quisermos dizer que uma função só pode receber, por exemplo,
um triplo de inteiros, escreveríamos assim:

> somaComponentes :: Triplo Int Int Int -> Int
> somaComponentes (x,y,z) = x+y+z

Main> somaComponentes (3, 400, 10)
413

Os sinónimos podem ajudar a criar novos sinónimos:

> type Ponto3D = Triplo Double Double Double

> getY :: Ponto3D -> Double
> getY = get2nd'

Main> getY (1.0, 2.0, 3.0)
2.0

--------------------------------------------------------------------

Para criar novos tipos usamos o comando 'data'

Eg:

> data Booleano = Verdadeiro | Falso

O operador | (lê-se 'or') separa as diferentes formas de definir o 
respectivo tipo

> data Answer = Yes | No | Unknown

A estas formas designamos por construtores.

Os construtores podem ter parâmetros:

> data Shape = Circle Double
>            | Rect Double Double

Notar que os construtores são funções:

Main> :t Circle
Circle :: Double -> Shape

Main> :t Rect
Rect :: Double -> Double -> Shape

Podemos definir funções para este novo tipo:

> area :: Shape -> Double
> area (Circle r) = pi * r^2
> area (Rect a b) = a * b

e valores:

> unitSquare :: Shape
> unitSquare = Rect 1 1

Outro eg:

> data PodeSer = Opcao1 Double  | Opcao2 String
>     deriving (Show)

Main> ps1 = Opcao1 10
Main> ps2 = Opcao2 String

> safeSqrt :: Double -> PodeSer
> safeSqrt n 
>    | n < 0     = Opcao2 "erro: valor negativo da raíz quadrada"
>    | otherwise = Opcao1 (sqrt n)

Main> safeSqrt 10
Opcao1 3.1622776601683795

Main> safeSqrt (-1)
Opcao2 "erro: valor negativo da raíz quadrada"


---

As próprias definições de tipos também podem ter parâmetros:

> data Maybe' a = Nothing' | Just' a
>    deriving (Show)

eg uso:

> procura :: Eq a => a -> [(a,b)] -> Maybe' b
> procura _ [] = Nothing'
> procura x ((key,info):ys)
>    | x == key  = Just' info
>    | otherwise = procura x ys

Main> procura 4 [(4,"a")]
Just' "a"

Main> procura 3 [(4,"a")]
Nothing'

--------------------------------------------------------------------

Nos tipos enumerados há uma ordem implícita dos valores:

> data Week = Mon | Tue | Wed | Thu | Fri | Sat | Sun
>   deriving (Show, Enum)

Main> [Mon .. Wed]   -- precisa de espaços
[Mon,Tue,Wed]

Main> [Fri ..]
[Fri,Sat,Sun]

--------------------------------------------------------------------

Nos tipos recursivos usamos o próprio tipo na sua definição:

> data Nat = Zero | Succ Nat
>    deriving (Show)

> int2nat :: Integer -> Nat
> int2nat 0 = Zero
> int2nat n = Succ (int2nat (n-1))

Main> int2nat 2
Succ (Succ Zero)

> add :: Nat -> Nat -> Nat
> add   Zero   m = m
> add (Succ n) m = Succ (add n m)

> mul :: Nat -> Nat -> Nat
> mul  Zero _    = Zero
> mul (Succ n) m = add m (mul n m)

Main> add (int2nat 2) (int2nat 1)
Succ (Succ (Succ Zero))

Main> mul (int2nat 2) (int2nat 3)
Succ (Succ (Succ (Succ (Succ (Succ Zero)))))

Outro eg:

> data Expr = Val  Int
>           | Add  Expr Expr
>           | Mult Expr Expr
>    deriving (Show)

> eval :: Expr -> Int
> eval (Val n)      = n
> eval (Add  e1 e2) = eval e1 + eval e2
> eval (Mult e1 e2) = eval e1 * eval e2

Main> eval $ Add (Val 1) (Mult (Val 2) (Val 4))
9

--------------------------------------------------------------------

Várias estruturas de dados definem-se com tipos recursivos, como a lista:

> data Lista a = Vazio | L a (Lista a)
>     deriving (Show)

> cabeca :: Lista t -> t
> cabeca (L x _) = x

> cauda :: Lista t -> Lista t
> cauda (L _ xs) = xs

Main> cabeca (L 4 (L 5 Vazio))
4

Main> cauda (L 4 (L 5 Vazio))
L 5 Vazio

---

ou as árvores binárias:

> data Tree a = EmptyTree | Node (Tree a) a (Tree a)
>     deriving (Show)

> find :: Eq a => a -> Tree a -> Bool
> find _    EmptyTree    = False
> find x (Node lf nd rg) = x == nd || find x lf || find x rg

se a árvore for de pesquisa, o find pode ser mais eficiente:

> find' :: Ord a => a -> Tree a -> Bool
> find' _ EmptyTree = False
> find' x (Node lf nd rg)
>   | x == nd = True
>   | x < nd  = find x lf 
>   | x > nd  = find x rg

Podemos criar funções 'fold' para outros tipos de dados:

> foldTree :: (b -> a -> b -> b) -> b -> Tree a -> b
> foldTree _ v EmptyTree       = v
> foldTree f v (Node lf nd rg) = 
>              f (foldTree f v lf) nd (foldTree f v rg)

eg uso:

> count = foldTree (\accL nd accR -> accL + 1 + accR) 0

> depth = foldTree (\accL nd accR -> 1 + max accL accR) 0

--------------------------------------------------------------------

Os tipos podem ser mutuamente recursivos:

> type Name      = [String]
> type Address   = [String]

> data Person = Adult Name Address
>             | Child Name Report

> type Responsibles = [Person]
> type Grades = [(String,Int)]
> data Report = R Grades Responsibles

--------------------------------------------------------------------

Existe uma síntaxe que simplifica o uso de tipos com estrutura 
mais complexa:

> data Person' = P { firstName :: String,
>                    lastName  :: String,
>                    age       :: Int,
>                    height    :: Double 
>                  } deriving (Show)

Podemos criar valores desta forma:

> p = P {firstName = "Ana", lastName = "Silva", age = 50, height = 1.62 }

e aceder aos dados usando getters produzidos automaticamente:

Main> firstName p
"Ana"

*Main> age p
50

--------------------------------------------------------------------

Temos usado o deriving (Show) para tornar os nossos tipos apresentáveis,
mas podemos usar no deriving outros typeclasses:

nota: vou redefinir o tipo, senão o Haskell queixava-se porque já definimos
a lista acima. Aproveito para criar um operador em substituição do 
construtor L, para terem um eg diferente.

> data List a = Null | a :-: (List a)
>     deriving (Show, Eq, Ord)

> infixr 5 :-:    -- associatividade à direita e precedência 5

Para conferir a precendência dos operadores Haskell, visitar
  https://www.haskell.org/onlinereport/decls.html#fixity

eg uso:

> lt1 = 6 :-: 3 :-: Null
> lt2 = 3 :-: 6 :-: Null

Main> lt1 == lt2
False

Main> Null < lt1  -- usa ordem lexicográfica pela ordem dos construtores
True

Main> lt1 < lt2
False
  
--------------------------------------------------------------------

O deriving (Read) permite que se faça parsing de strings para valores

> data Tree' a = EmptyTree' | Node' (Tree' a) a (Tree' a)
>     deriving (Show, Read)

Main> read "Node' EmptyTree' 5 EmptyTree'" :: Tree' Int
Node' EmptyTree' 5 EmptyTree'

Main> read "Node' EmptyTree' 5 EmptyTree'" :: Tree' Double
Node' EmptyTree' 5.0 EmptyTree'

--------------------------------------------------------------------

Por vezes o deriving automático do Haskell não nos dá o que queremos.
É possível implementar como o nosso tipo passa a ser uma instância 
do typeclass.

Eg, queremos que o nosso tipo Lista 

> data Lista' a = Vazio' | L' a (Lista' a)

considere que duas listas são iguais se tiverem o mesmo tamanho:

> instance Eq (Lista' a) where
>    lt1 == lt2 = tamanho lt1 == tamanho lt2
>       where
>         tamanho Vazio'    = 0
>         tamanho (L' _ xs) = 1 + tamanho xs

Main> L' 1 Vazio' == L' 2 Vazio'
True

A sintaxe para instanciar um tipo numa typeclass é:

instance TypeClass OMeuTipo where
    <definicao das funcoes que a typeclass exige>
    
Como vimos, o Eq só pede que se faça o (==). 

Já a implementação do (/=) sai de graça:

Main> L' 1 Vazio' /= L' 2 Vazio'
False

--------------------------------------------------------------------

Para instanciar à typeclass Show precisamos de definir a função show.
De notar que para a lista ser apresentável, os seus elementos também
têm de o ser. Essa pré-condição refere-se no cabeçalho:

> instance Show a => Show (Lista' a) where
>     show Vazio' = "<>"
>     show list   = "<" ++ present list ++ ">"
>         where
>            present Vazio'        = ""
>            present (L' x Vazio') = show x
>            present (L' x xs)     = show x ++ "," ++ present xs

Main> Vazio'
<>

Main> L' 2 (L' 4 Vazio')
<2,4>

--------------------------------------------------------------------

Já o typeclass Ord exige que se implemente a função 

    compare :: a -> a -> Ordering
    
onde Ordering é um tipo enumerado já definido

    data Ordering = LT | EQ | GT
    
e cujos valores vamos usar para comparar um valor X com outro Y 
e dizer se X é maior, menor ou igual que Y.

Vamos instanciar a nossa lista como Ord usando a ordem lexicográfica,
como nas strings.

De reparar que agora precisamos que os elementos que a lista armazena
também sejam comparáveis!

> instance Ord a => Ord (Lista' a) where
>    compare Vazio' Vazio'       = EQ
>    compare Vazio'    _         = LT
>    compare (L' x xs) (L' y ys)
>      | cmpVals == EQ = compare xs ys
>      | otherwise     = cmpVals
>        where
>           cmpVals = compare x y

Implementando esta função, os operadores relacionais saem de graça:

Main> L' 1 Vazio' <= L' 2 Vazio'
True

Main> L' 3 Vazio' > L' 2 (L' 4 Vazio')
True

Main> max (L' 4 Vazio') (L' 2 (L' 4 Vazio'))
<4>

--------------------------------------------------------------------

Um eg de instanciação à classtype Num (definimos o tipo Nat acima):

> sub :: Nat -> Nat -> Nat
> sub   Zero     Zero   = Zero
> sub   Zero   (Succ _) = error "non defined subtraction"
> sub    n       Zero   = n
> sub (Succ n) (Succ m) = sub n m

> instance Num Nat where
>     fromInteger = int2nat
>     x + y       = add x y
>     x - y       = sub x y
>     x * y       = mul x y
>     abs         = id
>     signum Zero = 0
>     signum _    = 1   

Main> Succ Zero + Succ Zero
Succ (Succ Zero)

--------------------------------------------------------------------

No Haskell também podemos definir novos typeclasses.

Vejamos como se define o Eq:

       class Eq a where
           (==) :: a -> a -> Bool
           (/=) :: a -> a -> Bool
           x == y = not (x /= y)
           x /= y = not (x == y)

Depois do cabeçalho incluímos uma lista de funções que fazem
parte da sua interface, e podemos até incluir definições default.

Neste caso, o (/=) é definido à custa do (==) (ou vice versa). 
É por isso que basta definir o (==) para usarmos o (/=) (ou vice-versa)

--------------------------------------------------------------------

Vamos fazer uma typeclass nova, uma espécie de booleano genérico:

> class YesNo a where
>    yesno :: a -> Bool

Podemos instanciar tipos a esta classe:

> instance YesNo Int where
>    yesno 0 = False
>    yesno _ = True

> instance YesNo [a] where
>    yesno [] = False
>    yesno _  = True

> instance YesNo Bool where
>    yesno = id

> instance YesNo (Maybe a) where
>    yesno (Just _) = True
>    yesno Nothing  = False

Podemos criar funções que aceitam valores deste typeclass:

> yesnoIf :: (YesNo y) => y -> a -> a -> a
> yesnoIf val yesResult noResult = if yesno val then yesResult else noResult

Main> yesnoIf [] "YEAH!" "NO!"
"NO!"

--------------------------------------------------------------------

Como eg mais concreto, vamos definir um novo typeclass para 
representar fracções. 

Este typeclass tem a seguinte interface:

> class Frac a where
>   rd   :: a -> a         -- simplificar uma fracção
>   plus :: a -> a -> a    -- f1 + f2
>   mult :: a -> a -> a    -- f1 * f2
>   recp :: a -> a         -- 1/f1

ou seja, para um tipo para ser considerado fracção tem de implementar 
a simplificação de fracções, a soma, o produto e ainda o recíproco.

Vamos agora fazer um tipo e instânciá-lo a Frac:

> data Fr = F Integer Integer  -- representam o numerador e o denominador

> instance Frac Fr where
>   rd (F n d) = F (div n m) (div d m)
>                  where
>                  m = mdc n d
>                  mdc x y = if y==0 then x else mdc y (mod x y)
>
>   plus (F n1 d1) (F n2 d2) = rd (F (n1*d2+n2*d1) (d1*d2))
>    
>   mult (F n1 d1) (F n2 d2) = rd (F (n1*n2) (d1*d2))
>    
>   recp (F n d) = rd (F d n)

Também podemos fazer com que o tipo seja apresentável, equiparável, 
e ordenável:

> instance Show Fr where
>   show (F n d) = show n ++ "/" ++ show d

> instance Eq Fr where
>   (F n1 d1) == (F n2 d2) = n1*d2 == n2*d1

> instance Ord Fr where
>   compare (F n1 d1) (F n2 d2)
>      | n1*d2 <  n2*d1 = LT
>      | n1*d2 == n2*d1 = EQ
>      | otherwise      = GT

Agora podemos experimentar o seu uso:

Main> plus (F 7 15) (F 9 15)
16/15

Main> recp (F 4 6)
3/2

Podemos também torná-lo instância de número:

> instance Num Fr where
>     fromInteger n = F n 1
>     f1 + f2       = plus f1 f2
>     f1 - f2       = plus f1 (mult f2 (F (-1) 1))
>     f1 * f2       = mult f1 f2
>     abs (F n d)   = if n*d < 0 then F (-n) d else F n d
>     signum (F n d)
>         | n == 0  = 0
>         | n*d < 0 = -1
>         | n*d > 0 = 1

Main> F 1 2 - F 4 5
-3/10

--------------------------------------------------------------------

Um outro typeclass que não falámos até agora é o Functor
que inclui os tipos aos quais podemos mapear funções.

    class Functor f where
        fmap :: (a -> b) -> f a -> f b
        
O tipo lista [a] é um destes casos, dado que faz sentido mapear uma 
função aos seus elementos (é o que faz o map!). Assim:

    instance Functor [] where
        fmap = map 
      
Main> fmap (*2) [1..3]
[2,4,6]

Main> f1 = fmap (replicate 3)
Main> f1 [1..4]
[[1,1,1],[2,2,2],[3,3,3],[4,4,4]]

Podemos definir uma função que recebe um functor com números e 
mapeia-os para o dobro:

> fdobro :: (Num a, Functor f) => f a -> f a
> fdobro = fmap (*2)

Main> fdobro [1..3]
[2,4,6]

Outra instância de Functor é o tipo Maybe a:

A sua instanciação é a seguinte:

    instance Functor Maybe where
        fmap f Nothing  = Nothing
        fmap f (Just x) = Just (f x)

Main> fdobro (Just 1)
Just 2

Esta typeclass é importante para abstrair o mapear de estruturas de dados:

> instance Functor Tree where
>       fmap _ EmptyTree       = EmptyTree
>       fmap f (Node lf nd rg) = Node (fmap f lf) (f nd) (fmap f rg)

Agora podemos mapear uma função a todos os nós de uma árvore binária. Eg:

Main> fdobro (Node EmptyTree 5 (Node EmptyTree 10 EmptyTree))
Node EmptyTree 10 (Node EmptyTree 20 EmptyTree)

Outro eg: 

> fshow :: (Show a, Functor f) => f a -> f String
> fshow = fmap show

*Main> fshow [1,2,3]
["1","2","3"]

*Main> fshow (Just 5)
Just "5"

Main> fshow (Node EmptyTree 5 (Node EmptyTree 10 EmptyTree))
Node EmptyTree "5" (Node EmptyTree "10" EmptyTree)

--------------------------------------------------------------------

O uso de fmap deve seguir algumas regras, nomeadamente:

    1) fmap id = id

    Se f for a identidade, a estrutura original deve permanecer inalterada

    2) fmap (f . g) = fmap f . fmap g
    
    Fazer o mapa da composição de duas funções deve ser o mesmo que fazer o 
    mapa de uma e depois da outra    

Um mapeamento que segue estas regras dá garantias de não haver comportamentos 
estranhos após o mapeamento.

--------------------------------------------------------------------

As funções unárias também são functores, onde o fmap é a composição. 

  fmap f g

devolve a função composta f.g

Por eg,

Main> fmap (*3) (+100) 5
315

Main> fmap ((*3).(+100)) (*2) 5
330

Se não dermos a 2ª função, fmap devolve uma função que fica 
à espera de um functor e devolve outro functor:

Main> fdobro (+1) 6   -- (+1) é o functor que esperávamos
14

Main> fdobro (\b -> if b then 1.0 else 0.0) True
2.0

--------------------------------------------------------------------
                          extra matéria PP
--------------------------------------------------------------------

*** Aplicativos

Os applicative functors são uma generalização dos functores.

O operador fmap recebe uma função que aplica ao valor de um dado functor

    fmap :: Functor f => (a -> b) -> f a -> f b
    
Mas se tivermos um functor com uma função 'a->b', não a podemos aplicar 
a um functor com um 'a'

Main> Just (*3) `fmap` Just 5
<interactive> error: ...

É neste contexto que se introduz o typeclass Applicative:

    class (Functor f) => Applicative f where  
        pure :: a -> f a  
        (<*>) :: f (a -> b) -> f a -> f b  

Se observarmos a assinatura do <*> já podemos fazer o que não conseguíamos
com o fmap:
        
Main> Just (*3) <*> Just 5
Just 15

A outra operação do Applicative é o pure que 'embrulha' um dado
valor no respectivo aplicativo:

Main> pure (*3) <*> Just 5
Just 15

Este eg está de acordo com a instanciação do Maybe:

    instance Applicative Maybe where  
        pure = Just  
        Nothing  <*>     _     = Nothing  
        (Just f) <*> something = fmap f something  

Outro eg:

Main> pure (+) <*> Just 3 <*> Just 5  
Just 8

--------------------------------------------------------------------

De notar que se embrulhamos um valor com pure, obtemos um aplicativo.
Ora, todos os aplicativos são functores. Isto diz-nos que dada uma
função f,

    pure f <*> x
    
aplica a função f a x e devolve um functor. Isto é o mesmo que 

    fmap f x
    
Eg,

Main> a = pure (+) <*> Just 3
Main> a <*> Just 5
Just 8

Main> b = fmap (+) (Just 3)
Main> b <*> (Just 5)
Just 8
       
O módulo Control.Applicative introduz um operador sinónimo de fmap:

    (<$>) :: Functor f => (a -> b) -> f a -> f b
    
E podemos escrever expressões mais concisas:

Main> (+) <$> Just 3 <*> Just 5
Just 8

Main> (++) <$> Just "hello " <*> Just "world"  
Just "hello world"

--------------------------------------------------------------------

Vejamos a instanciação default para listas:

    instance Applicative [] where  
        pure x = [x]  
        fs <*> xs = [f x | f <- fs, x <- xs]
        
A implementação é através de uma lista por compreensão que produz
todos os resultados possíveis. A semântica dada a esta instanciação
é da computação não-determinista (isto está fora do âmbito da cadeira).

Main>  [(*0),(+100),(^2)] <*> [1,2,3] 
[0,0,0,101,102,103,1,4,9]

Main> fs = (*) <$> [1,2]   -- fs é a lista [(*1),(*2)]
Main> fs <*> [10,30]
[10,30,20,60]

--------------------------------------------------------------------

Vejamos a instanciação default para funções unárias:

    instance Applicative ((->) r) where  
        pure x = (\_ -> x)  
        f <*> g = \x -> f x (g x) 
       
O pure cria uma função constante:

Main> pure 3 undefined
3

Já para o <*> o aplicativo de duas funções é uma função que faz
mais sentido quando o primeiro argumento é uma função binária:

Main> f =  pure (1+) <*> (*2)   -- exemplo com duas funções unárias
Main> f 4
9               -- porque 1+4*2 == 9

Main> f = f = pure (+) <*> (*3) <*> (^2)  -- exemplo com função binária
Main> f 4
28              -- porque (4*3) + (4^2)

O próximo eg cria uma lista de três funções que são a seguir avaliadas 
para o valor 5:

Main> (\x y z -> [x,y,z]) <$> (+3) <*> (*2) <*> (`mod` 2) $ 5
[8,10,1]

Estão disponíveis as funções liftA que ajudam a escrevem este padrão comum:

Main> liftA (1+) (*2) 4
9

Main> liftA2 (+) (*3) (^2) 4
28

Main> liftA3 (\x y z -> [x,y,z]) (+3) (*2) (`mod` 2) 5
[8,10,1]

A função que processa com <*> todos os valores numa lista

    sequenceA :: (Applicative f) => [f a] -> f [a]  
    sequenceA = foldr (liftA2 (:)) (pure [])  
    
Egs:

Main> sequenceA [Just 3, Just 2, Just 1]
Just [3,2,1]

Main> sequenceA [(+3),(+2),(+1)] 3
[6,5,4]

Main> and $ sequenceA [(>4),(<10),odd] 7
True    

Main> sequenceA [[1,2,3],[4,5]]
[[1,4],[1,5],[2,4],[2,5],[3,4],[3,5]]

Main> fs = sequenceA [[(+1),(*2)], [(*100)]]
Main> :t fs
fs :: Num a => [[a -> a]]   -- fs == [[(+1),(*100)],[(*2),(*100)]]
Main> map (map ($4)) fs
[[5,400],[8,400]]     

Main> sequenceA [getLine, getLine, getLine]
hello
world
!!
["hello","world","!!"]

--------------------------------------------------------------------

Os aplicativos também possuem leis a cumprir pelo programador:

    pure id <*> v = v
    
    pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
    
    pure f <*> pure x = pure (f x)
    
    u <*> pure y = pure ($ y) <*> u
  
--------------------------------------------------------------------

*** Monóides

Um monóide (G,*,e) é um conjunto de valores G com um operador binário '*' 
e um elemento 'e' que possui as seguintes propriedades:

    - a operação '*' é fechada, ie, se a,b pertencem a G, a*b pertence a G
    - 'e' é o elemento neutro de '*', ie, e*a == a*e == e
    - '*' é associativa, ie, a*(b*c) == (a*b)*c
    
Muitos objectos matemáticos são monóides, como (N,0,+) ou (N,1,*).

Também muitos conceitos das linguagens de programação são monóides. 
Exemplo de monóides:

 * as listas em (lista vazia, concatenação)
 * as strings em (string vazia, concatenação)
 * os sets em (conjunto vazio, união)
 * os booleanos em (falso, disjunção)
 * os booleanos em (verdadeiro, conjunção)
 * as matrizes n x n em (matriz diagonal n x n, multiplicação de matrizes)
 * as funções com assinatura a -> a em (identidade, composição)

Na maior parte das linguagens isto é implicíto, mas não é esse o caso no
Haskell, onde se pode explorar esta abstracção

Para tal, existe um typeclass para instanciar tipos como monóides:

   class Monoid m where
      mempty  :: m
      mappend :: m -> m -> m
      mconcat :: [m] -> m
      mconcat = foldr mappend mempty  -- definição default

mempty corresponde ao elemento neutro, e mappend ao operador associativo.

mconcat é um operador que aplica a função sequencialmente a uma lista de 
elementos. Esta aplicação sequencial é implementada por default por um
foldr!

Como as listas são monóides para a concatenação, a forma como se instancia
é a seguinte:

    instance Monoid [a] where
       mempty      = []
       mappend x y = x ++ y
       mconcat     = concat

---
       
A instanciação do monóide de booleanos em (falso, disjunção)

> newtype Any = Any Bool

> instance Monoid Any where  
>    mempty = Any False  
>    Any x `mappend` Any y = Any (x || y)  

---
       
Quando podemos ter mais que um monóide, como no caso dos inteiros 
para (0,+) e (1,*) temos de usar um truque, dado que só se pode 
instanciar um tipo a uma classtype uma vez.

Para isso usamos uma outra forma de criar tipos, o comando newtype.
O newtype é parecido com o data mas só pode ter um construtor com
um argumento, no máximo. Isto significa que o novo tipo e o tipo
do argumento estão em correspondência directa (são isomorfos).

Não parece muito útil, mas dá jeito aqui:

> newtype Sum = MS Int
>   deriving (Show, Eq, Enum, Num)  
>  
> instance Monoid Sum where
>   mempty = MS 0
>   mappend (MS x) (MS y) = MS (x + y)


> newtype Product = MP Int
>   deriving (Show, Eq, Enum, Num)
>  
> instance Monoid Product where
>   mempty = MP 1
>   mappend (MP x) (MP y) = MP (x * y)  
  
Eg:

Main> mconcat [] :: Sum          -- devolve o elemento neutro
MS 0

Main> mconcat [1..5] :: Sum      -- mconcat aplica a soma à lista
MS 15

Main> mconcat [] :: Product
MP 1

Main> mconcat [1..5] :: Product  -- mconcat aplica o produto à lista
MP 120

ou usando um map:

Main> mconcat $ map MP [1..5]
MP 120

Como nos functores, o programador precisa de respeitar as regras que 
definem o monóide (o Haskell não faz isso por nós), ou seja:

    1) x `mappend` mempty == mempty `mappend` x == x

    2) (x `mappend` y) `mappend` z == x `mappend` (y `mappend` z)

--------------------------------------------------------------------

Convenciou-se que (<>) é o operador sinónimo de mappend:

> infixr 6 <>
> 
> (<>) :: Monoid a => a -> a -> a
> (<>) = mappend

--------------------------------------------------------------------

Para o monóide das funções (a -> a) em (função identidade, composição):

> newtype Endo a = Endo { evalEndo :: a -> a }   -- Endo é abreviatura de endomorfismo
> 
> instance Monoid (Endo a) where
>    mempty                  = Endo id
>    Endo f `mappend` Endo g = Endo (f . g)

Eg:
 
Main> evalEndo (Endo (*2) <> Endo (+1) <> Endo (*10)) 100
2002
Main> ef = mconcat $ map Endo [(*2),(+1),(*10)]
Main> evalEndo ef 100
2002

--------------------------------------------------------------------

Com o typeclass Monoid podemos abstrair funções que acumulam
resultados de uma operação:

> accumulate3 :: Monoid m => m -> m -> m -> m
> accumulate3 a b c = a <> b <> c

Main> accumulate3 [1] [2] [4]
[1,2,4]

Main> accumulate3 (MS 1) (MS 2) (MS 4)
MS 7

--------------------------------------------------------------------

Para ver algumas aplicações de Monoid leiam:
 https://en.wikibooks.org/wiki/Haskell/Foldable
 http://blog.sigfpe.com/2009/01/haskell-monoids-and-their-uses.html
 http://apfelmus.nfshost.com/articles/monoid-fingertree.html


--------------------------------------------------------------------

*** Mónadas

No typeclass Functor aplicamos funções a valores no contexto de um functor:

    (<$>) :: Functor f => (a -> b) -> f a -> f b

No typeclass Applicative podes aplicar funções também elas no mesmo contexto:

    (<*>) :: Applicative f => f (a -> b) -> f a -> f b

No passo seguinte queremos ter um valor no contexto, e aplicá-lo a uma
função que recebe um valor normal e cria um novo valor no contexto:

    (>>=) :: Monad m => m a -> (a -> m b) -> m b
    
Esta operação como se vê na assinuta faz parte do typeclass Monad:

    class Monad m where  
      return :: a -> m a  
      (>>=) :: m a -> (a -> m b) -> m b  

(o typeclass tem mais duas funções, (>>) e fail, ambas com definições default)

Se compararmos as três operações (usando a versão flip de >>=) observamos
as semelhanças:

    (<$>) :: Functor f     =>   (a -> b) -> f a -> f b
    (<*>) :: Applicative f => f (a -> b) -> f a -> f b
    (=<<) :: Monad m       => (a -> m b) -> m a -> m b

Comparando expressões similares:
    
Main> (+3) <$> Just 5
Just 8

Main> pure (+3) <*> Just 5
Just 8

Main> return 3 >>= \a -> Just(a+5) 
Just 8

Para funcionar desta forma, eis a instanciação de Maybe:

    instance Monad Maybe where  
        return x      = Just x  
        Nothing >>= f = Nothing  
        Just x >>= f  = f x  
        fail _        = Nothing  

--------------------------------------------------------------------

O tipo lista também é uma mónada:

    instance Monad [] where  
        return x = [x]  
        xs >>= f = concat (map f xs)  
        fail _   = []  

Aqui o >>= aplica a função f aos elementos da lista, fazendo um concat
no fim para se obter uma nova lista.

Eg:

Main> [1..4] >>= replicate 3
[1,1,1,2,2,2,3,3,3,4,4,4]

Main> [1..4] >>= \n -> replicate n n
[1,2,2,3,3,3,4,4,4,4]

Main> [1..4] >>= \n -> replicate n n >>= \x -> [-x,x]
[-1,1,-2,2,-2,2,-3,3,-3,3,-3,3,-4,4,-4,4,-4,4,-4,4]

De notar que os argumentos são conhecidos adiante, e que o comportamento
de não-determinismo (calcular todas as possibilidades) continua a funcionar,
como nos aplicativos:

Main> [1,3,5] >>= \n -> take n ['a'..'z']
"aabcabcde"

Main> [1,3,5] >>= \n -> take n ['a'..'z'] >>= \c -> return (n,c)
[(1,'a'),(3,'a'),(3,'b'),(3,'c'),(5,'a'),(5,'b'),(5,'c'),(5,'d'),(5,'e')]

A computação equivalente no formato do:

Main> :{
Main| do
Main|   n <- [1,3,5]
Main|   c <- take n ['a'..'z']
Main|   return (n,c)
Main| :}
[(1,'a'),(3,'a'),(3,'b'),(3,'c'),(5,'a'),(5,'b'),(5,'c'),(5,'d'),(5,'e')]

Se isto faz lembrar listas por compreensão, não é coincidência! Estas
são apenas açucar sintático para o uso de listas como mónadas.

O seguinte exemplo mostra como usar esta característica não-determinista
das listas para gerar todas as combinações e depois filtrar aquelas
que queremos:

> guarded :: Bool -> [a] -> [a]
> guarded True xs = xs
> guarded False _ = []
> 
> multiplyTo :: Int -> [(Int, Int)]
> multiplyTo n = 
>  do x <- [1..n]
>     y <- [x..n]
>     guarded (x*y == n) $
>        return (x, y)

Main> multiplyTo 16
[(1,16),(2,8),(4,4)]

--------------------------------------------------------------------

As mónadas também têm leis a cumprir:
   
      return x >>= f  ==  f x
    
       m >>= return   ==  m

    (m >>= f) >>= g   ==   m >>= (\x -> f x >>= g)      associatividade

--------------------------------------------------------------------

Exemplo tirado do fim de http://learnyouahaskell.com/for-a-few-monads-more

> newtype Prob a = Prob { getProb :: [(a,Rational)] } 
>    deriving Show  

> instance Functor Prob where  
>    fmap f (Prob xs) = Prob $ map (\(x,p) -> (f x,p)) xs  

Main> fmap (++"!") $ Prob [("yes",1%2)]
Prob {getProb = [("yes!",1 % 2)]}

O Haskell exige a instanciação do Applicative:

> instance Applicative Prob where  
>    pure x  = Prob [(x,1%1)]  
>    Prob ((f,_):_) <*> (Prob xs) = fmap f (Prob xs) -- not sure...

Main> Prob [((+1),0)] <*> Prob [(1,1%2),(2,1%2)]
Prob {getProb = [(2,1 % 2),(3,1 % 2)]}

> instance Monad Prob where  
>    return   = pure
>    m >>= f  = flatten (fmap f m)  
>     where
>       flatten :: Prob (Prob a) -> Prob a  
>       flatten (Prob xs) = Prob $ concat $ map multAll xs  
>       multAll (Prob innerxs,p) = map (\(x,r) -> (x,p*r)) innerxs  
>    fail _   = Prob []  

Eg:

> data Coin = Heads | Tails deriving (Show, Eq)  
>   
> coin :: Prob Coin  
> coin = Prob [(Heads,1%2),(Tails,1%2)]  
>   
> loadedCoin :: Prob Coin  
> loadedCoin = Prob [(Heads,1%10),(Tails,9%10)]  

> flipThree :: Prob Bool  
> flipThree = do  
>     a <- coin  
>     b <- coin  
>     c <- loadedCoin  
>     return (all (==Tails) [a,b,c])  

Main> flipThree
Prob {getProb = [(False,1 % 40),(False,9 % 40),(False,1 % 40),(False,9 % 40),(False,1 % 40),(False,9 % 40),(False,1 % 40),(True,9 % 40)]}

> condense :: Eq a => Prob a -> Prob a
> condense xs = Prob [ (e, sumEvent e)  | e <- events ]
>   where
>     events = DL.nub $ map fst $ getProb xs
>     sumEvent event = sum [ p | (e,p) <- getProb xs, e == event]

Main> condense flipThree
Prob {getProb = [(False,31 % 40),(True,9 % 40)]}

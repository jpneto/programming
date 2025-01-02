O exerc�cio VI.1 pede a cria��o de um m�dulo Set usando 
a representa��o de listas ordenadas sem repeti��es.

Este seria o cabe�alho (juntei umas fun��es extra):

> module Set (Set, 
>             empty, 
>             null, 
>             singleton,
>             size,
>             insert, 
>             remove, 
>             member, 
>             filter,
>             union, 
>             intersection,
>             difference,
>             partition,
>             list2set
>        ) where

no cliente usar 

  import qualified Set as S
  
para evitar conflitos de nomes como null que tamb�m existe no Prelude.

Aqui vamos esconder as fun��es null e filter do Prelude
para evitar conflitos de nomes neste m�dulo.

> import Prelude hiding (filter, null)

No entanto, como vamos precisar do filter mais adiante, podemos
tamb�m importar o Prelude de forma qualificada.

> import qualified Prelude as P

Estes dois imports em conjunto significam que podemos aceder 
a todas as fun��es do Prelude, mas apenas o null e filter precisam 
ser prefixados por 'P.'

Vamos tamb�m importar o Data.List:

> import qualified Data.List as DL
     
Como pedido no enunciado, a implementa��o � com listas

> data Set a = S [a]

Relembrar que S � o construtor de valores do tipo Set.

A sua assinatura:

Main> :t S
S :: [a] -> Set a

Vamos come�ar a definir as fun��es:

> empty :: Set a
> empty = S []

> null :: Set a -> Bool
> null (S []) = True
> null _      = False
 
> singleton :: a -> Set a
> singleton x = S [x]
 
> member :: Ord a => a -> Set a -> Bool
> member _ (S [])     = False
> member x (S (y:ys)) = x==y || (x>y && member x (S ys))

> size :: Set a -> Int
> size (S xs) = length xs

Agora fa�amos o insert (n�o esquecer que a inser��o tem
de respeitar a ordena��o da lista, e a n�o exist�ncia
de duplicados) .

Vamos tentar definir a fun��o recursivamente sobre os conjuntos:

insert :: Ord a => a -> Set a -> Set a
insert x (S []) = S [x]
insert x (S (y:ys) 
  | x < y  = S (x:y:ys)
  | x == y = S (y:ys)
  | x > y  = ???
  
Como se faz se o x > y? Tem de se mandar inserir o x no resto do 
conjunto e depois voltar a colocar o y na cabe�a da lista

  | x > y  =  insHead y (insert x (S ys))
  where
    insHead y (S ys) = S (y:ys)

Ugh! Not pretty!    

Uma melhor forma � extrair a lista por pattern matching e 
fazer as contas apenas com listas. No fim 'embrulhamos' 
a lista resultante no S e devolvemos esse valor conjunto.

  insert :: Ord a => a -> Set a -> Set a
  insert x (S xs) = S (ins x xs)
    where
      ins x []     = [x]
      ins x (y:ys)
        | x==y      = y:ys
        | x<y       = x:y:ys
        | otherwise = y:ins x ys

Se fizermos o remove acabamos por repetir o mesmo processo:
        
  remove :: Ord a => a -> Set a -> Set a
  remove x (S xs) = S (rem x xs)
    where
      rem _ []   = []
      rem x (y:ys) 
        | x < y     = y:ys
        | x == y    = ys
        | otherwise = y:rem x ys
        
Ora h� aqui uma ideia (extrair, aplicar, embrulhar) que
pode ser abstra�da numa fun��o:

> liftS :: ([a] -> [b]) -> Set a -> Set b
> liftS f (S xs) = S (f xs)

E refazemos as fun��es usando esta nova fun��o:

> insert :: Ord a => a -> Set a -> Set a
> insert x set = liftS (ins x) set
>   where
>     ins x []     = [x]
>     ins x (y:ys)
>       | x < y     = x:y:ys
>       | x == y    = y:ys
>       | otherwise = y:ins x ys

> remove :: Ord a => a -> Set a -> Set a
> remove x set = liftS (rem x) set
>   where
>     rem _ []   = []
>     rem x (y:ys) 
>       | x < y     = y:ys
>       | x == y    = ys
>       | otherwise = y:rem x ys

O filter pode ser definido da mesma forma:

> filter ::  Ord a => (a -> Bool) -> Set a -> Set a
> filter p set1 = liftS (P.filter p) set1

As fun��es que se seguem recebem duas listas que t�m
de ser extra�das, avaliadas e embrulhado o valor final.
Podemos criar uma vers�o do liftS com dois argumentos:

> liftS2 :: ([a] -> [b] -> [c]) -> Set a -> Set b -> Set c
> liftS2 f (S xs) (S ys) = S (f xs ys)

Seguem-se as opera��es de manipula��o de dois conjuntos:

> union :: Ord a => Set a -> Set a -> Set a
> union set1 set2 = liftS2 uni set1 set2
>   where
>     uni [] ys         = ys
>     uni xs []         = xs
>     uni (x:xs) (y:ys)
>       | x < y     = x : uni xs (y:ys)
>       | x == y    = x : uni xs ys
>       | otherwise = y : uni (x:xs) ys
 
> intersection :: Ord a => Set a -> Set a -> Set a
> intersection set1 set2 = liftS2 int set1 set2
>   where
>     int [] ys = []
>     int xs [] = []
>     int (x:xs) (y:ys) 
>       | x < y     = int xs (y:ys)
>       | x == y    = x : int xs ys
>       | otherwise = int (x:xs) ys
 
> difference :: Ord a => Set a -> Set a -> Set a
> difference set1 set2 = liftS2 diff set1 set2
>   where
>     diff xs [] = xs
>     diff [] ys = []
>     diff (x:xs) (y:ys)
>       | x < y     = x : diff xs (y:ys)
>       | x == y    = diff xs ys
>       | otherwise = diff (x:xs) ys

A parti��o e o list2set s�o definidas � custa de foldr's:
 
> partition :: (a -> Bool) -> Set a -> (Set a, Set a)
> partition p (S xs) = (S ys, S zs)
>   where
>     (ys,zs) = foldr (\x (ps,nps) -> if p x then (x:ps,nps) 
>                                            else (ps, x:nps)) ([],[]) xs    

> list2set :: Ord a => [a] -> Set a
> list2set = foldr insert empty

E a instancia��o no Eq e Show:

> instance Eq a => Eq (Set a) where
>    (S xs) == (S ys) = xs == ys

> instance Show a => Show (Set a) where
>   show (S xs) = "{" ++ printSet xs ++ "}"
>     where
>       printSet []     = " "
>       printSet [x]    = show x
>       printSet (x:xs) = show x ++ "," ++ printSet xs

Seguem alguns valores para se poder experimentar as opera��es

> s1 = list2set [1..6]
> s2 = list2set [6,3,9,5,7,12,87,1]  
> s3 = list2set "fefrgw"    

----------------------------------------------------------------------------

Outra inst�ncia que pode dar jeito � da typeclass Functor:

> instance Functor Set where
>   fmap f (S xs) = S $ map f xs
   
A fun��o fmap permite mapear uma fun��o a todos os elementos

Main> fmap (*2) s1
{2,4,6,8,10,12}

Tamb�m o podemos fazer com o liftS:

Main> liftS (map (*2)) s1
{2,4,6,8,10,12}

No entanto, as fun��es liftS permitem aplicar a valores conjunto 
uma maior variedade de fun��es que a mera aplica��o do fmap:

Main> liftS (\(y:ys) -> (y-1):ys) s1  -- subtrair 1 ao menor elemento do conjunto
{0,2,3,4,5,6}

Main> liftS2 zip s3 s1
{('e',1),('f',2),('g',3),('r',4),('w',5)}

Estas fun��es s�o t�o �teis que se poderia considerar export�-las tamb�m.

No entanto, ser� preciso ter aten��o com o uso das fun��es lift
para n�o invalidar a invariante do tipo Set, que � dos elementos 
guardados estarem organizados por ordem crescente e n�o haver
duplicados.

Egs de mau uso:

Main> insert 5 $ liftS reverse s1
{5,6,5,4,3,2,1}

Main> liftS (map (\x -> if even x then 1 else 0)) s1
{0,1,0,1,0,1}

Aqui temos de tomar a decis�o de deixar essa responsabilidade ao
cliente, ou tormarmos medidas para manter a validade da invariante.
Se quisermos manter a invariante, uma solu��o seria substituir 
a implementa��o dos lift's por

  liftS :: Ord b => ([a] -> [b]) -> Set a -> Set b
  liftS f (S xs) = S (DL.sort . DL.nub $ f xs)
 
  liftS2 :: Ord c => ([a] -> [b] -> [c]) -> Set a -> Set b -> Set c
  liftS2 f (S xs) (S ys) = S (DL.sort . DL.nub $ f xs ys)
  
ie, por cada aplica��o de uma fun��o, a nova lista � reordenada.

Agora os exemplos que falharam j� devolvem conjuntos v�lidos:

Main> insert 5 $ liftS reverse s1
{1,2,3,4,5,6}

Main> liftS (map (\x -> if even x then 1 else 0)) s1
{0,1}

O custo a pagar est� na complexidade de muitas fun��es O(n)  
passarem a O(n.log n)


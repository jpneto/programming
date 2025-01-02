> import qualified Data.Map as M
> import Data.List
> import Data.Ord   -- uses comparing

-- to install Memoize
-- bash> cabal update
-- bash> cabal install Memoize

> import qualified Data.Function.Memoize as F

----------------------------------------------------------
----------------------------------------------------------
----------------------------------------------------------

Em Haskell, quando um valor � calculado ele fica guardado para 
o caso de ser necess�rio. Se esse valor est� numa lista, os 
elementos anteriores tiveram de ser calculados e ficam assim 
guardados  (pelo menos at� ao pr�ximo garbage collection).

Eg:

Main> let nats = [1..]
(0.00 secs, 0 bytes)

Main> nats!!1000000
1000001
(0.14 secs, 35679224 bytes)

Main> nats!!99999
100000
(0.00 secs, 515680 bytes)

-------------

Podemos aproveitar esta caracter�stica  para criar vers�es 
memorizadas de fun��es recursivas.

A seguinte fun��o cria uma lista infinita com todos os fibs e 
pede o n-�simo valor. Como os anteriores t�m de ser calculados
antes, eles est�o dispon�veis para consulta.
       
> mem_fib :: Int -> Integer         
> mem_fib = get_fib
>    where                       
>      get_fib n = fibs !! n
>      fibs = map fib [0..]        
>      fib 0 = 0
>      fib 1 = 1                 
>      fib n = get_fib(n-2) + get_fib(n-1) 

Ou seja, durante a computa��o a lista fibs permanece e o Haskell 
guarda os seus valores para o caso de serem necess�rios, ie, faz 
a memoriza��o por n�s.

Outra solu��o com a mesma t�cnica mas usando um zipWith:

> mem_fib1 n = fibs!!n
>   where
>     fibs = 0:1:(zipWith (+) fibs (tail fibs))

Uma outra t�cnica � guardar as solu��es num hash map. Para isso
usamos o m�dulo Data.Map.

> mem_fib2 n = snd . (!!n) . (M.toList) $ fibs
>     where
>         fibs :: M.Map Int Integer
>         fibs = M.fromAscList [(i, fib i) | i <- [0..n]]
>         fib 0 = 0
>         fib 1 = 1
>         fib n = fibs M.! (n-1) + fibs M.! (n-2)        

Neste eg criamos uma lista de n pares (i, fib i) por compreens�o
e guardamos numa lista (fromAscList converte uma lista crescente
num mapa). Cada elemento desta lista avalia fib e como os pares
est�o a ser calculados de forma crescente, os valores anteriores 
encontram-se dispon�veis para consulta e para serem usados no
c�lculo dos pares seguintes.

-------------------------------------------------------

Outra alternativa � usar o operador de ponto fixo, fix
(https://en.wikibooks.org/wiki/Haskell/Fix_and_recursion):

> fix :: (a -> a) -> a
> fix f = let x = f x in x

> fix' :: ((a -> b) -> (a -> b)) -> (a -> b)  -- defini��o alternativa
> fix' f = f (fix' f)

Temos de criar uma fun��o de ordem superior que chama a 
fun��o em quest�o:

> fib_rec :: (Int -> Integer) -> Int -> Integer
> fib_rec f 0 = 0
> fib_rec f 1 = 1
> fib_rec f n = f (n-1) + f (n-2)

A fun��o fib normal seria definida da seguinte forma:

> fix_fib = fix fib_rec  -- vers�o n�o memorizada

Isto s� funciona devido � lazy eval, sen�o seria uma recurs�o infinita.

Agora criamos uma fun��o que abstrai a cria��o dos valores

> memoize :: (Int -> a) -> (Int -> a)
> memoize f = (map f [0..] !!)

E podemos definir a vers�o memorizada:

> mem_fib3 :: Int -> Integer
> mem_fib3 = fix (memoize . fib_rec)

Este funcionamento est� dispon�vel no m�dulo Data.Function.Memoize.

O m�dulo disponibiliza a fun��o memoFix similar a fix, 
mas j� devolvendo uma vers�o memorizada:

> mem_fib4 :: Int -> Integer
> mem_fib4 = F.memoFix fib_rec

Outra op��o � usar a fun��o 'memoize' deste m�dulo. Aqui temos de 
ter aten��o que a fun��o recursiva ter� de pedir os valores
� fun��o memorizada:

> mem_fib5 :: Int -> Integer
> mem_fib5 = F.memoize fib
>   where
>     fib :: Int -> Integer
>     fib 0 = 0
>     fib 1 = 1
>     fib n = mem_fib5 (n-1) + mem_fib5 (n-2)

Existem as variantes memoize2, memoize3, etc. para memorizar
fun��es com mais argumentos.

Btw, se ainda n�o se fartaram da sequ�ncia de Fibonacci, passem
por aqui: https://wiki.haskell.org/The_Fibonacci_sequence

---------------------------------

Vejamos um exemplo diferente do fib: a conjectura de Collatz.

Uma fun��o que devolve o caminho da sequ�ncia de Collatz de um dado n�mero
aparece no livro do Lipovaca:

> chain :: Integer -> [Integer]
> chain 1 = [1]
> chain n
>   | even n = n : chain (div n 2)
>   | odd n  = n : chain (3*n+1)

Para verificar os caminhos de um intervalo usamos: 

    map chain [1..20]
    
Seja o problema 14 do Projeto Euler (https://projecteuler.net/)
que pergunta qual o n�mero < 1.000.000 que possui a maior cadeia. 
Neste caso, se tent�ssemos avaliar

    maximum $ map (length.chain) [1..1000000]

esta avalia��o iria demorar imenso tempo, porque estar�amos a 
calcular todas as cadeias sem aproveitar computa��es. E podemos 
aproveitar! Por exemplo, 

    (length.chain) 1000 == 1 + (length.chain) 500
    
ie, se soubermos o tamanho da cadeia de 500, basta somar 1 
para encontrar o tamanho da cadeia de 1000.
    
A solu��o seguinte utiliza a t�cnica de usar um mapa para 
devolver o n�mero <= n que possui a maior cadeia. Aqui s� 
guardamos a dimens�o das cadeias at� um milh�o. Todas as 
outras calculamos novamente, se for o caso.

> mem_max_chain n = fst . maximumBy (comparing snd) . M.toList $ chains
>   where
>     chains :: M.Map Integer Integer
>     chains = M.fromAscList [(i, collatz i) | i <- [1..n]]
>     collatz 1 = 0
>     collatz i = 1 + if next <= n then chains M.! next 
>                                  else collatz next
>        where
>           next = if even i then div i 2 else 3*i+1

Se testarmos esta fun��o:

Main> mem_max_chain 1000000
837799
(7.57 secs, 2,084,414,944 bytes)

Menos de 8 segundos. Nada mau!!

Outra solu��o � usar o memoize do m�dulo Memoize. Aqui criou-se
para cada inst�ncia do problema um triplo que guarda a informa��o
necess�ria 

  (i, dimens�o da cadeia de i, �ndice da maior cadeia entre 1..i)

A fun��o memorizada max_chain calcula este triplo:

> mem_max_chain2 n = get3rd $ f_mem n
>   where
>      get2nd = \(_,y,_) -> y
>      get3rd = \(_,_,z) -> z
>      f_mem = F.memoize max_chain
>        where
>           max_chain :: Integer -> (Integer, Integer, Integer)
>           max_chain 1 = (1, 1, 1)
>           max_chain i = (i, size_chain_i, idx_max_i)
>              where
>                 next         = if even i then div i 2 else 3*i+1
>                 size_chain_i = 1 + get2nd (f_mem next)
>                 idx_max_prev =     get3rd (f_mem (i-1))
>                 idx_max_i    = if size_chain_i > get2nd (f_mem idx_max_prev)
>                                   then i else idx_max_prev

Esta computa��o tem a mesma complexidade da anterior mas � mais complicada.
Como seria esperado, demora um pouco mais:

Main> mem_max_chain2 1000000
837799
(26.85 secs, 4,616,698,088 bytes)

----------------------------

Refs:

https://wiki.haskell.org/Memoization

https://hackage.haskell.org/package/containers-0.4.0.0/docs/Data-Map.html
http://hackage.haskell.org/package/memoize-0.6/docs/Data-Function-Memoize.html
http://hackage.haskell.org/package/base-4.9.0.0/docs/Data-Ord.html#v:comparing
http://hackage.haskell.org/package/base-4.9.0.0/docs/Data-List.html

http://stackoverflow.com/questions/11466284
http://stackoverflow.com/questions/23214296
http://stackoverflow.com/questions/13849721
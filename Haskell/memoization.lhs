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

Em Haskell, quando um valor é calculado ele fica guardado para 
o caso de ser necessário. Se esse valor está numa lista, os 
elementos anteriores tiveram de ser calculados e ficam assim 
guardados  (pelo menos até ao próximo garbage collection).

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

Podemos aproveitar esta característica  para criar versões 
memorizadas de funções recursivas.

A seguinte função cria uma lista infinita com todos os fibs e 
pede o n-ésimo valor. Como os anteriores têm de ser calculados
antes, eles estão disponíveis para consulta.
       
> mem_fib :: Int -> Integer         
> mem_fib = get_fib
>    where                       
>      get_fib n = fibs !! n
>      fibs = map fib [0..]        
>      fib 0 = 0
>      fib 1 = 1                 
>      fib n = get_fib(n-2) + get_fib(n-1) 

Ou seja, durante a computação a lista fibs permanece e o Haskell 
guarda os seus valores para o caso de serem necessários, ie, faz 
a memorização por nós.

Outra solução com a mesma técnica mas usando um zipWith:

> mem_fib1 n = fibs!!n
>   where
>     fibs = 0:1:(zipWith (+) fibs (tail fibs))

Uma outra técnica é guardar as soluções num hash map. Para isso
usamos o módulo Data.Map.

> mem_fib2 n = snd . (!!n) . (M.toList) $ fibs
>     where
>         fibs :: M.Map Int Integer
>         fibs = M.fromAscList [(i, fib i) | i <- [0..n]]
>         fib 0 = 0
>         fib 1 = 1
>         fib n = fibs M.! (n-1) + fibs M.! (n-2)        

Neste eg criamos uma lista de n pares (i, fib i) por compreensão
e guardamos numa lista (fromAscList converte uma lista crescente
num mapa). Cada elemento desta lista avalia fib e como os pares
estão a ser calculados de forma crescente, os valores anteriores 
encontram-se disponíveis para consulta e para serem usados no
cálculo dos pares seguintes.

-------------------------------------------------------

Outra alternativa é usar o operador de ponto fixo, fix
(https://en.wikibooks.org/wiki/Haskell/Fix_and_recursion):

> fix :: (a -> a) -> a
> fix f = let x = f x in x

> fix' :: ((a -> b) -> (a -> b)) -> (a -> b)  -- definição alternativa
> fix' f = f (fix' f)

Temos de criar uma função de ordem superior que chama a 
função em questão:

> fib_rec :: (Int -> Integer) -> Int -> Integer
> fib_rec f 0 = 0
> fib_rec f 1 = 1
> fib_rec f n = f (n-1) + f (n-2)

A função fib normal seria definida da seguinte forma:

> fix_fib = fix fib_rec  -- versão não memorizada

Isto só funciona devido à lazy eval, senão seria uma recursão infinita.

Agora criamos uma função que abstrai a criação dos valores

> memoize :: (Int -> a) -> (Int -> a)
> memoize f = (map f [0..] !!)

E podemos definir a versão memorizada:

> mem_fib3 :: Int -> Integer
> mem_fib3 = fix (memoize . fib_rec)

Este funcionamento está disponível no módulo Data.Function.Memoize.

O módulo disponibiliza a função memoFix similar a fix, 
mas já devolvendo uma versão memorizada:

> mem_fib4 :: Int -> Integer
> mem_fib4 = F.memoFix fib_rec

Outra opção é usar a função 'memoize' deste módulo. Aqui temos de 
ter atenção que a função recursiva terá de pedir os valores
à função memorizada:

> mem_fib5 :: Int -> Integer
> mem_fib5 = F.memoize fib
>   where
>     fib :: Int -> Integer
>     fib 0 = 0
>     fib 1 = 1
>     fib n = mem_fib5 (n-1) + mem_fib5 (n-2)

Existem as variantes memoize2, memoize3, etc. para memorizar
funções com mais argumentos.

Btw, se ainda não se fartaram da sequência de Fibonacci, passem
por aqui: https://wiki.haskell.org/The_Fibonacci_sequence

---------------------------------

Vejamos um exemplo diferente do fib: a conjectura de Collatz.

Uma função que devolve o caminho da sequência de Collatz de um dado número
aparece no livro do Lipovaca:

> chain :: Integer -> [Integer]
> chain 1 = [1]
> chain n
>   | even n = n : chain (div n 2)
>   | odd n  = n : chain (3*n+1)

Para verificar os caminhos de um intervalo usamos: 

    map chain [1..20]
    
Seja o problema 14 do Projeto Euler (https://projecteuler.net/)
que pergunta qual o número < 1.000.000 que possui a maior cadeia. 
Neste caso, se tentássemos avaliar

    maximum $ map (length.chain) [1..1000000]

esta avaliação iria demorar imenso tempo, porque estaríamos a 
calcular todas as cadeias sem aproveitar computações. E podemos 
aproveitar! Por exemplo, 

    (length.chain) 1000 == 1 + (length.chain) 500
    
ie, se soubermos o tamanho da cadeia de 500, basta somar 1 
para encontrar o tamanho da cadeia de 1000.
    
A solução seguinte utiliza a técnica de usar um mapa para 
devolver o número <= n que possui a maior cadeia. Aqui só 
guardamos a dimensão das cadeias até um milhão. Todas as 
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

Se testarmos esta função:

Main> mem_max_chain 1000000
837799
(7.57 secs, 2,084,414,944 bytes)

Menos de 8 segundos. Nada mau!!

Outra solução é usar o memoize do módulo Memoize. Aqui criou-se
para cada instância do problema um triplo que guarda a informação
necessária 

  (i, dimensão da cadeia de i, índice da maior cadeia entre 1..i)

A função memorizada max_chain calcula este triplo:

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

Esta computação tem a mesma complexidade da anterior mas é mais complicada.
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
> import Data.List

Este é um resumo da aula teórica desta 5a feira. Podem fazer copy-paste
deste texto para um ficheiro de texto com extensão .lhs. O Haskell
para além dos ficheiros .hs normais, reconhece um modo literato 
onde podemos escrever texto normalmente (como aqui) e apenas as linhas 
prefixadas por '>' são interpretadas.

A definição recursiva mais direta nem sempre é a indicada dado que 
pode implicar uma computação de complexidade excessiva.

Eg, a definição recursiva da sequência de Fibonacci

> fib :: Integer -> Integer
> fib 0 = 1
> fib 1 = 1
> fib n = fib (n-1) + fib (n-2)

tem complexidade exponencial, O(1.618^n)   [número de ouro, \Phi = 1.618...]

Se quisermos experimentar o desempenho da função, escrevam primeiro 
na linha de comandos do interpretador, o comando 

    :set +s
    
para que o GHC nos possa dar estatísticas de uso de recursos
seja de tempo, seja de memória alocada.

Os seguintes valores, no meu PC, deram:

Main> fib 35
14930352
(31.89 secs, 2881047504 bytes)

Main> fib 36
24157817
(51.78 secs, 4661615112 bytes)

Main> fib 37
39088169
(83.21 secs, 7541952256 bytes)

Podemos observar a complexidade exponencial no tempo a mais que está
a demorar.

Se a definição recursiva mais directa não funciona, precisamos ser mais cuidadosos 
e definir recursivamente de outra forma. Neste caso:

> fib' :: Integer -> Integer
> fib' n = fib2 1 1 n
>   where
>     fib2 a _ 0 = a
>     fib2 a b n = fib2 b (a+b) (n-1) 

que possui complexidade linear.

Para comparar com os valores anteriores, a seguinte expressão calcula os 
primeiros 101 números da sequência:

Main> map fib' [0..100]
[1,1,2,3,5,8,13,21,34,55,89,144,233, ... 573147844013817084101]
(0.03 secs, 2573816 bytes)

nb: introduzimos a função map no capítulo 6 do livro.

----------------------------------------------------

A resolução linear anterior usa argumentos extra para passar informação 
entre os diversos níveis de recursão. É uma técnica muito flexível 
que nos permite simular o uso de variáveis locais típicas em ciclos.

Por exemplo, seja o seguinte método Java:

  int findAndCount(int elem2find, int[] v) {
      int count = 0;

      for(int i=0; i<v.length; i++)
        if (v[i] == elem2find)
          count++;

      return count;
  }
  
Se quisermos espelhar esta computação em Haskell podemos fazer:

> findAndCount :: Int -> [Int] -> Int
> findAndCount elem2find v = find 0 0
>   where
>      find i count 
>        | i < length v = if (v!!i==elem2find) then find (i+1) (count+1)
>                                              else find (i+1)  count
>        | otherwise     = count

Claro que não precisamos de argumentos extra neste exemplo e podemos 
definir uma versão recursiva mais sucinta onde no passo da recursão 
simplificamos a lista:

> findAndCount' :: Int -> [Int] -> Int
> findAndCount' _ [] = 0
> findAndCount' elem2find (x:xs) =
>      (if x == elem2find then 1 else 0) + findAndCount' elem2find xs 

Esta 2a solução até é mais rápida porque evitamos usar o operador (!!)
que possui complexidade linear (as listas não possuem um acesso indexado
rápido, ao contrário dos vectores).

Mas ainda podemos ser mais sucintos usando funções de ordem superior
que iremos falar no capítulo 6:

> findAndCount'' :: Int -> [Int] -> Int
> findAndCount'' elem2find = length.filter(==elem2find)

----------------------------------------------------

Existe uma outra técnica paralela à dos argumentos extra,
é a técnica de usar tuplos para devolver vários resultados.

> fib'' :: Integer -> Integer
> fib'' n = snd $ fibTup n
>   where
>      fibTup 0 = (0,1)
>      fibTup n = (b,a+b)
>        where
>          (a,b) = fibTup (n-1)

outro exemplo, para calcular a média de uma lista de doubles:

> average :: [Double] -> Double
> average = uncurry (/) . sumlen 
>   where
>     sumlen [x]    = (x,1)
>     sumlen (x:xs) = (x+z, 1+n)
>       where
>         (z,n) = sumlen xs
>     uncurry f (x,y) = f x y


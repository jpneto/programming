> import Data.List

Este � um resumo da aula te�rica desta 5a feira. Podem fazer copy-paste
deste texto para um ficheiro de texto com extens�o .lhs. O Haskell
para al�m dos ficheiros .hs normais, reconhece um modo literato 
onde podemos escrever texto normalmente (como aqui) e apenas as linhas 
prefixadas por '>' s�o interpretadas.

A defini��o recursiva mais direta nem sempre � a indicada dado que 
pode implicar uma computa��o de complexidade excessiva.

Eg, a defini��o recursiva da sequ�ncia de Fibonacci

> fib :: Integer -> Integer
> fib 0 = 1
> fib 1 = 1
> fib n = fib (n-1) + fib (n-2)

tem complexidade exponencial, O(1.618^n)   [n�mero de ouro, \Phi = 1.618...]

Se quisermos experimentar o desempenho da fun��o, escrevam primeiro 
na linha de comandos do interpretador, o comando 

    :set +s
    
para que o GHC nos possa dar estat�sticas de uso de recursos
seja de tempo, seja de mem�ria alocada.

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

Podemos observar a complexidade exponencial no tempo a mais que est�
a demorar.

Se a defini��o recursiva mais directa n�o funciona, precisamos ser mais cuidadosos 
e definir recursivamente de outra forma. Neste caso:

> fib' :: Integer -> Integer
> fib' n = fib2 1 1 n
>   where
>     fib2 a _ 0 = a
>     fib2 a b n = fib2 b (a+b) (n-1) 

que possui complexidade linear.

Para comparar com os valores anteriores, a seguinte express�o calcula os 
primeiros 101 n�meros da sequ�ncia:

Main> map fib' [0..100]
[1,1,2,3,5,8,13,21,34,55,89,144,233, ... 573147844013817084101]
(0.03 secs, 2573816 bytes)

nb: introduzimos a fun��o map no cap�tulo 6 do livro.

----------------------------------------------------

A resolu��o linear anterior usa argumentos extra para passar informa��o 
entre os diversos n�veis de recurs�o. � uma t�cnica muito flex�vel 
que nos permite simular o uso de vari�veis locais t�picas em ciclos.

Por exemplo, seja o seguinte m�todo Java:

  int findAndCount(int elem2find, int[] v) {
      int count = 0;

      for(int i=0; i<v.length; i++)
        if (v[i] == elem2find)
          count++;

      return count;
  }
  
Se quisermos espelhar esta computa��o em Haskell podemos fazer:

> findAndCount :: Int -> [Int] -> Int
> findAndCount elem2find v = find 0 0
>   where
>      find i count 
>        | i < length v = if (v!!i==elem2find) then find (i+1) (count+1)
>                                              else find (i+1)  count
>        | otherwise     = count

Claro que n�o precisamos de argumentos extra neste exemplo e podemos 
definir uma vers�o recursiva mais sucinta onde no passo da recurs�o 
simplificamos a lista:

> findAndCount' :: Int -> [Int] -> Int
> findAndCount' _ [] = 0
> findAndCount' elem2find (x:xs) =
>      (if x == elem2find then 1 else 0) + findAndCount' elem2find xs 

Esta 2a solu��o at� � mais r�pida porque evitamos usar o operador (!!)
que possui complexidade linear (as listas n�o possuem um acesso indexado
r�pido, ao contr�rio dos vectores).

Mas ainda podemos ser mais sucintos usando fun��es de ordem superior
que iremos falar no cap�tulo 6:

> findAndCount'' :: Int -> [Int] -> Int
> findAndCount'' elem2find = length.filter(==elem2find)

----------------------------------------------------

Existe uma outra t�cnica paralela � dos argumentos extra,
� a t�cnica de usar tuplos para devolver v�rios resultados.

> fib'' :: Integer -> Integer
> fib'' n = snd $ fibTup n
>   where
>      fibTup 0 = (0,1)
>      fibTup n = (b,a+b)
>        where
>          (a,b) = fibTup (n-1)

outro exemplo, para calcular a m�dia de uma lista de doubles:

> average :: [Double] -> Double
> average = uncurry (/) . sumlen 
>   where
>     sumlen [x]    = (x,1)
>     sumlen (x:xs) = (x+z, 1+n)
>       where
>         (z,n) = sumlen xs
>     uncurry f (x,y) = f x y


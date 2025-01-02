> {-# LANGUAGE BangPatterns #-}       -- veremos adiante o que significa

--------------------------------------------------------------------------------

A avaliação de uma expressão, desde que termine e se respeite as 
precedências, não depende da ordem pela qual estas funções são invocadas.

Por exemplo, seja a função sucessor:

    succ x = x+1
    
se quisermos avaliar succ (2*3) podemos fazê-lo de duas formas:

    succ (2*3)
    succ 6
    6 + 1
    7
    
    succ (2*3)
    (2*3) + 1
    6 + 1
    7

Qualquer forma de avaliar uma expressão, desde que termine, 
irá produzir o mesmo resultado.

Isto é possível porque no Haskell a avaliação de expressões não 
produz efeitos secundários.

Esta propriedade não é satisfeita numa linguagem onde existem 
efeitos secundários. Por exemplo a expressão Java:

    i + ++i;

produz resultados diferentes se avaliarmos primeiro a parte direita ou 
a parte esquerda (dado que ++i produz o efeito secundário de alterar 
o estado da variável i).    
    
--------------------------------------------------------------------------------    

A avaliação de uma expressão pode ser realizada de diferentes formas.

Seja a função

    mult (x,y) = x*y

e a expressão mult(1+2, 2+3).

Vamos chamar a uma expressão que pode ser simplificada como redex 
(reducible expression). Neste exemplo há três redexs: 1+2, 2+3 e mult(1+2,2+3). 

Qual fazer primeiro?

A abordagem de linguagens como o Java, Python ou C é de avaliar 
as redexs mais interiores e, dentro dessas, começar pela esquerda. 
Assim, esta estratégia de avaliação dar-nos-ia:

    mult(1+2, 2+3)
    mult(3, 2+3)
    mult(3, 5)
    3 * 5
    15

Esta estratégia garante que os valores dos parâmetros estão sempre 
avaliados quando a função é avaliada. Chamamos a esta estratégia 
avaliação estrita, ou gananciosa (strict or eager evaluation).

Outra estratégia é começar pelos redexs mais exteriores e, dentro desses, 
da esquerda para a direita. Vamos voltar a avaliar a expressão:

    mult(1+2, 2+3)
    (1+2) * (2+3)
    3 * (2+3)
    3 * 5
    15
    
A esta estratégia chamamos de avaliação preguiçosa (lazy evaluation) 
sendo a avaliação utilizada por default pelo Haskell.

--------------------------------------------------------------------------------

Vamos repetir a avaliação na versão currificada da multiplicação

    mult = \x y -> x*y
    
Avaliação estrita:    

    mult (1+2) (2+3)
    mult 3 (2+3)          -- mult 3 é o redex mais à esquerda
    (\y -> 3*y) (2+3)
    (\y -> 3*y) 5
    3 * 5
    15
    
Avaliação preguiçosa:

    mult (1+2) (2+3)
    (1+2) * (2+3)
    3 * (2+3)
    3 * 5
    15

--------------------------------------------------------------------------------

A lazy eval tem algumas vantagens em relação à strict eval.

Se uma função não precisa calcular todos os argumentos, poupam-se 
computações:

    f x y = if x>0 then 2*x else x+y
    
Façamos uma avaliação:    
    
    f 3 (2^1000)
    if 3>0 then 2*3 else 3+(2^1000)
    if True then 2*3 else 3+(2^1000)
    2*3
    6
    
Na strict eval teríamos de calcular a potência antes de avaliar f

Isto significa que certas avaliações podem terminar usando lazy 
eval mas não com strict eval:

    f 3 undefined
    if 3>0 then 2*3 else 3+undefined
    if True then 2*3 else 3+undefined
    2*3
    6

Na strict eval ter-se-ia de avaliar o 2º argumento antes de 
avaliar f, o que resultaria num erro.

A strict eval tem uma vantagem sobre a lazy eval, o número de redexs a 
simplificar pode ser menor:

    sq x = x * x
    
com strict eval:
    
    sq (2+3)
    sq 5
    5 * 5
    25
    
com lazy eval:

    sq (2+3)
    (2+3) * (2+3)
    5 * (2+3)
    5 * 5
    25
    
Mas existe uma forma de melhorar o desempenho da avaliação preguiçosa. 
Um interpretador é capaz de perceber quando uma expressão é duplicada. 
Quando isso ocorre, ao avaliar a expressão pela primeira vez, 
o interpretador substitui todas as cópias da expressão pelo resultado 
obtido. O Haskell utiliza esta estratégia optimizada.

Desta forma, a avaliação anterior tem menos simplificações:

    sq (2+3)
    (2+3) * (2+3)
    5 * 5
    25

Quando usamos pattern matching, também aqui a lazy eval vai buscar 
apenas o necessário:

    f (x:xs) (y:ys) = x+y
    
avaliando:
    
    f [1..1000] [2..1000]
    f (1:[2..1000]) (2:[3..1000])
    1 + 2
    3
    
--------------------------------------------------------------------------------

Um outro ganho ocorre quando se aplica uma lista sobre várias funções.

Por exemplo, a seguinte avaliação:

    sum (map (^2) [1..n])
    sum (1^2 : map (^2) [2..n])
    sum (1^2 : map (^2) [2..n])
    1^2 + sum (map (^2) [2..n])
    1^2 + sum (2^2 : map (^2) [3..n])
    1^2 + 2^2 + sum (map (^2) [3..n])
    ...
    1^2 + 2^2 + 3^2 + ... n^2
    ...

apenas percorre a lista uma vez, ao contrário da strict eval que 
percorreria duas vezes.

--------------------------------------------------------------------------------

Outro eg que seria ineficiente com a strict eval, mas que se pode fazer 
em lazy eval:

> head' (x:_) = x

> isort []     = []
> isort (x:xs) = ins x (isort xs)
>       where
>           ins x []     = [x]
>           ins x (y:xs) = if x<y then x:y:xs 
>                                 else y:ins x xs

> min' :: Ord a => [a] -> a   -- função que devolve o mínimo de uma lista
> min' = head' . isort

ou seja, estamos a sugerir que para encontrar o mínimo de uma lista, 
faça-se uma ordenação crescente e tire-se a cabeça do resultado!! 
Em strict eval este algoritmo é O(n^2) mas o mínimo pode ser implementado 
em O(n) dado que basta uma passagem pela lista para encontrar o menor valor.

Porém:

    min' [10,1,7]
    (head' . isort)  [10,1,7]
    head' (isort [10,1,7])
    head' (ins 10 (isort [1,7]))
    ...
    head' (ins 10 (ins 1 (ins 7 [])))
    head' (ins 10 (ins 1 [7])
    head' (ins 10 [1,7])
    head' (1 : ins 10 [7])
    1
    
ou seja, a lista foi atravessada uma vez. O ins vai puxando o menor elemento 
para a cabeça da lista, e no momento em que ele está na cabeça, o head pode 
ser avaliado e tudo o resto que falta fazer (ordenar o resto da lista) pode 
ser abandonado. A nossa implementação do mínimo afinal é O(n)!

--------------------------------------------------------------------------------

Outra vantagem muito significativa, que já temos referido nas aulas, é a 
capacidade de representar estruturas infinitas.

Por exemplo:

    ones = 1 : ones

    take 0 _  = []
    take n [] = []
    take n (x:xs) = x : take (n-1) xs
    
Se avaliarmos:

    take 2 ones
    take 2 (1:ones)
    1 : take 1 ones
    1 : take 1 (1:ones)
    1 : 1 : take 0 ones
    1 : 1 : []
    [1,1]

Na avaliação estrita esta expressão resultaria num ciclo infinito, dado 
que iria tentar avaliar a lista ones inteira, o que não é possível!

Do ponto de vista da lazy eval, ones é uma lista potencialmente infinita, 
que pode ser avaliada parcialmente mas não totalmente. E esta capacidade 
de avaliar parcialmente uma expressão faz toda a diferença.

--------------------------------------------------------------------------------

A lazy eval permite libertar o programador de certas preocupações com a 
memória para se focar nos algoritmos.

No seguinte exemplo vamos produzir a lista infinita de todos os primos 
usando o antigo algoritmo grego conhecido por Crivo de Eratóstenes e que 
funciona da seguinte forma:

1º) Listam-se todos os números > 1

  primos:
  lista:  2 3 4 5 6 7 8 9 10 11 12 13 14 ...
  
2º) Guarda-se o 1º elemento desta lista e retiram-se todos os seus mútiplos:

  primos: 2
  lista:    3   5   7   9    11    13    ...
    
3º) Repete-se 2º)

  primos: 2 3
  lista:        5   7        11    13    ...

  primos: 2 3 5
  lista:            7        11    13    ...

  primos: 2 3 5 7
  lista:                     11    13    ...

  ...
  
Como programar este algoritmo em  Haskell?

> primes :: [Int ]
> primes = sieve [2..]
>     where
>        sieve :: [Int] -> [Int]
>        sieve (p:xs) = p : sieve [x | x <- xs, x `mod` p /= 0]

Cada invocação de sieve cria uma lista infinita com todos os números 
dados excepto aqueles que são multiplos de p.

Main> take 20 $ primes
[2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71]

Este algoritmo não é eficiente mas mostra como um algoritmo que usa um 
ciclo infinito para produzir uma lista infinita pode ser programado 
via lazy eval.

Se tentássemos simular o mesmo em Java, teríamos que nos preocupar com 
arrays de dimensão limitada, e de como aumentar a sua dimensão se o 
utilizador precisasse de primos maiores. Aqui toda essa gestão é automática.

--------------------------------------------------------------------------------

Avaliação estrita em Haskell

Também é possível usar avaliação estrita no Haskell, não estamos restritos 
apenas a uma estratégia de avaliação de expressões. 

Para tal existe a função 'seq' do Prelude:

    seq :: a -> b -> b   
    
Esta função avalia o primeiro argumento antes de devolver o segundo.

É através desta função que se pode introduzir a avaliação estrita para 
melhorar o desempenho em certos casos onde a lazy eval não é a melhor opção.

De notar que se fizermos seq x x isso é o mesmo que avaliar x dado que 
o Haskell quando avalia uma expressão substitui todas as sauas cópias 
pelo resultado.

A função que se costuma usar é o operador ($!) definido da seguinte forma:

    ($!) :: (a -> b) -> a -> b   
    f $! x = x `seq` f x
    
Este é um operador infixo com associatividade à direita, ie, 

    x $! y $! z   ==    x $! (y $! z) 

A função
    
    f x = g $! h $! x  
    
avalia primeiro a expressão 'x', depois avalia (h x) e só depois 
aplica o resultado a 'g'

Comparemos a avaliação de sq (2+3) e sq $! (2+3)

    sq (2+3)
    (2+3) * (2+3)
    5 * 5
    25
    
    sq $! (2+3)
    sq 5
    5 * 5
    25
    
No exemplo seguinte temos três implementações de uma função que calcula 
a dimensão de uma lista:

> len :: [a] -> Int       -- definição recursiva habitual
> len   []   = 0
> len (x:xs) = len xs + 1

Esta implementação falha para listas muito grandes dado que as chamadas 
recursivas vão-se acumulando na pilha de invocações:

Main> len [1..20000000]    -- stack overflow

vejamos como os redexs estão a ser simplificados:

  len [1..20000000]
  len [2..20000000] + 1
  (len [3..20000000] + 1) + 1
  ((len [4..20000000] + 1) + 1) + 1
  ...

Podemos tentar usar recursão terminal para evitar acumular chamadas 
recursivas, mas temos um problema similar dado que o Haskell, por ser 
lazy, não soma os 1s:

> len2 xs = len' xs 0     -- definição com recursão terminal
>   where
>    len' :: [a] -> Int -> Int
>    len'   []   acc = acc
>    len' (x:xs) acc = len' xs (1 + acc)


Main> len2 [1..20000000]   -- stack overflow

  len2 [1..20000000]
  len' [1..20000000] 0
  len' [2..20000000] (1+0)
  len' [3..20000000] (1+1+0)
  len' [4..20000000] (1+1+1+0)
  ...

A solução é forçar o Haskell a somar o valor acumulado antes de avaliar a 
próxima recursão. Isto limita a dimensão das expressões prevenindo 
o stack overflow:

> len3 xs = len' xs 0     -- definição com recursão terminal estrita
>   where
>    len'   []   acc = acc
>    len' (x:xs) acc = len' xs $! (1 + acc)


Main> len3 [1..200000]   -- ok!

  len3 [1..20000000]
  len' [1..20000000] 0
  len' [2..20000000] 1
  len' [3..20000000] 2
  len' [4..20000000] 3
  ...

ref: http://www.haskell.org/haskellwiki/Performance/Accumulating_parameter

--------------------------------------------------------------------------------

Há um ponto importante quando se usa o ($!) em estruturas de dados. 
A avaliação que o Haskell faz é apenas o necessário para se perceber 
que não é undefined (ie, que a expressão pode ser avaliada e não dá erro). 
Por exemplo, para avaliar uma lista, o Haskell apenas avalia a cabeça da 
lista. Logo, usar ($!) não implica que tudo é estritamente avaliado.

Se quisermos essse comportamente pode-se usar o operador ($!!) e a 
função 'deepseq' que se encontram no módulo Control.DeepSeq. 
Não iremos aprofundar esta temática.

--------------------------------------------------------------------------------

Existe uma extensão do Haskell, chamada "bang patterns", onde podemos 
definir que certos pattern matches são para ser avaliados estritamente. 
Para isso é preciso colocar no início do programa a linha 

  {-# LANGUAGE BangPatterns #-}  
  
(agora já podem ligar à primeira linha deste ficheiro)

Para informar o Haskell que um argumento é estrito devemos prefixá-lo com !

       Eg normal             |          Exemplo com !
-----------------------------+-------------------------------------
                             |   
 f x y = y                   |     f !x y = y
                             |    
Main> f undefined 3          |    Main> f undefined 3
3                            |    *** Exception: Prelude.undefined


A seguinte definição do len faz o mesmo que a função len3 mas usa este prefixo:

> len4 xs = len' xs 0     -- definição com recursão terminal estrita
>   where
>    len'  []     acc = acc
>    len' (x:xs) !acc = len' xs (1 + acc)

Main> len4 [1..20000000]
20000000

ref: https://downloads.haskell.org/~ghc/7.8.4/docs/html/users_guide/bang-patterns.html

--------------------------------------------------------------------------------

O problema de stack overflow também ocorre quando processamos listas com fold's.

A versão len2 com recursão terminal pode ser implementada pelo foldl 
que, pela sua definição, processa a expressão com recursividade terminal:

> len2' :: [a] -> Int
> len2' = foldl (\acc x -> 1+acc) 0

e que produz o mesmo problema:

Main> len2' [1..20000000]
*** Exception: stack overflow

Nestes casos podemos usar a versão estrita do foldl, foldl', que 
está disponível no módulo Data.List mas que implementamos aqui:

> foldl' f z []     =  z
> foldl' f z (x:xs) =  (foldl' f $! f z x) xs

A versão estrita do len passa a ser

> len3' :: [a] -> Int
> len3' = foldl' (\acc x -> 1+acc) 0

e este já funciona para valores maiores

Main> len3' [1..20000000]
20000000

--------------------------------------------------------------------------------

Outro eg:

> mysum :: [Integer] -> Integer
> mysum = foldr (+) 0

  mysum (+) 0 [1..10]
  foldr (+) 0 (1:[2..10]) 
  1+foldr (+) 0 (2:[3..10]) 
  1+(2+foldr (+) 0 (3:[4..10])) 
  ...

O foldr não tendo recursão terminal, acumula as chamadas recursivas 
no operador (+)

Solução com foldl:

> mysum2 :: [Integer] -> Integer
> mysum2 = foldl (+) 0

O foldl tem recursão terminal mas o acumulador vai acumulando as somas que 
só serão avaliadas no fim. Esta expressão acaba por gastar demasiada memória:

  mysum2 [1..10]
  foldl (+) 0         (1:[2..10])
  foldl (+) (0+1)     (2:[3..10])
  foldl (+) (0+1+2)   (3:[4..10]) 
  foldl (+) (0+1+2+3) (4:[5..10]) 
  ...
  
O ideal seria ir avaliando as somas para que o acumulador fosse apenas 
o valor do somatório actual. Aqui entra o foldl'

> mysum3 :: [Integer] -> Integer
> mysum3 = foldl' (+) 0 

Agora temos o comportamento desejado:

  mysum3 [1..10] 
  foldl (+) 0 (1:[2..10])
  foldl (+) 1 (2:[3..10])
  foldl (+) 3 (3:[4..10])
  foldl (+) 6 (4:[5..10]) 
  ...
  
Façamos uma experiência:
  
Main> mysum [1..20000000]
*** Exception: stack overflow

Main> mysum2 [1..20000000]
*** Exception: stack overflow

Main> mysum3 [1..20000000]
200000010000000  

ref: http://www.haskell.org/haskellwiki/Stack_overflow

--------------------------------------------------------------------------------

Estruturas cíclicas

As estruturas de dados podem ser definidas recursivamente, como no
caso das listas e das árvores binárias. Estas estruturas, porém,
não precisam ter uma base de recursão.

A lista

> ones = 1:ones

representa uma estrutura infinita definida por um ciclo. Se 
avaliarmos os primeiros elementos:

ones
  = 1:ones
  = 1:1:ones
  = 1:1:1:ones
  = ...
  
Podemos representar esta lista pelo seguinte diagrama:
                
                  +------+
              +-->|  1:  |---+----> ones
              |   +------+   |
              +--------------+
     
O Haskell, por mais elementos que sejam avaliados, apenas precisa 
alocar um 1.
          
Já a definição:

> ones' = repeat' 1
>   where
>      repeat' x = x : repeat' x
  
vai crescendo à medida que é avaliado, porque o Haskell não consegue
intuir que se trata do mesmo valor:

ones'
  = 1:repeat' 1
  = 1:1:repeat' 1
  = ...

Uma comparação de desempenho:
  
Main> ones !! 1000000
1
(0.00 secs, 87,232 bytes)

Main> ones' !! 1000000
1
(0.42 secs, 64,088,528 bytes)

Do ponto de vista semântico não há qualquer diferença entre estas
duas definições. Nenhuma função conseguiria distinguir entre as duas.

Uma lista cíclica constitui um 'loop na memória', necessitando
apenas de espaço constante para ser guardada.

Se as listas cíclicas são listas infinitas, nem todas as listas
infinitas têm uma versão cíclica (eg, a lista dos números primos).

Esta discussão não tem a ver com o Haskell (a linguagem é agnóstica 
nestas questões) mas com as estratégias do GHC para optimizar a 
avaliação de expressões.

---

Outro exemplo, agora com dois argumentos:

> cyclic = let x = 0 : y  -- versão cíclica
>              y = 1 : x
>          in  x

                                                                                
                 +-------+          +-------+
             +-->|   1:  |--------->|   0:  |------> cyclic
             |   +-------+          +-------+
             |                          |
             +--------------------------+
  
> cyclic' = repeat' 0 1   -- versão não cíclica
>   where
>      repeat' x y = x : y : repeat' x y

Main> cyclic !! 1000000
0
(0.05 secs, 29,760 bytes)

Main> cyclic' !! 1000000
0
(0.28 secs, 36,027,992 bytes)

---

Outro exemplo: a função iterate do Prelude produz a seguinte lista infinita

    iterate f x = x : f x : f (f x) : ...
    
Uma possível definição recursiva seria

> iterate' f x = x : map f (iterate' f x)

mas esta definição não cria uma estrutura cíclica (temos a chamada
recursiva da função na expressão). A seguinte já o faz:

> iterate'' f x = xs
>   where
>     xs = x : map f xs  -- map f (x:xs) = f x : map f xs

Em diagrama: 

                   +---------+      +---------+
             +---->|  map f  |----->|   x:    |-----> xs
             |     +---------+      +----+----+
             |                           |
             +---------------------------+

Main> iterate' (*2) 1 !! 10000
199506311...
(2.06 secs, 5,910,198,264 bytes)

Main> iterate'' (*2) 1 !! 10000
199506311...
(0.02 secs, 10,628,184 bytes)

Existe porém um preço a pagar. Nas listas cíclicas o Haskell mantém
a lista inteira em memória, enquanto nas listas infinitas a garbage
collection pode funcionar e manter apenas um número limitado de 
elementos da lista. Para listas que vão crescendo (como no caso do
iterate) isto pode tornar-se um problema.

ref: http://stackoverflow.com/questions/25498431

--------------------------------------------------------------------------------

Redes de Fluxos (stream networks, também chamadas process networks)

Estas listas podem servir para modelar fluxos de informação (streams). 

Neste primeiro exemplo queremos receber uma lista infinita de inteiros e 
devolver uma lista de somas parciais. 

Por exemplo,

Main> take 20 $ runSums [1..]
[0,1,3,6,10,15,21,28,36,45,55,66,78,91,105,120,136,153,171,190]

devolve uma lista cujo elemento no indíce i corresponde à soma dos 
primeiros i elementos da lista dada.

Ora isto significa que para calcular o próximo elemento da lista 
final, basta ir buscar a soma anterior e juntar o próximo elemento. 
No caso acima teríamos:

    [0, 0+1, 1+2, 3+3, 6+4, 10+5, 15+6, 21+7, 28+8, ...]
                             ^ ^
    soma até agora ----------+ |
    próximo elemento ----------+

Podemos representar este processo num diagrama onde há dois fluxos, 
o fluxo de entrada (a lista dada) e um fluxo com as somas realizadas 
até então (que inicia-se no zero). Para juntar os dois fluxos, somando 
elemento a elemento, podemos usar a função zipWith (+)

            +-------------+               +--------+
   ins ---->| zipWith (+) +-------------->|   0:   +---+--> outs
            +-------------+               +--------+   |
                     ^                                 |
                     |                                 |
                     +---------------------------------+

Em código Haskell esta ideia traduz-se em:

> runSums :: [Integer] -> [Integer]        
> runSums ins = outs
>   where
>       outs = 0:zipWith (+) ins outs
      
Outro eg, para criar um fluxo com todos os factoriais podemos 
multiplicar o próprio fluxo dos factoriais (que começamos com 
o 0!=1) com o fluxo dos números naturais, ie,

    [1, 1*1, 1*2, 2*3, 6*4, 24*5, 120*6, 720*7, ... ]
                                   ^  ^
    produtório até agora ----------+  |
    próximo elemento -----------------+
    
Em diagrama:
      
      +-------------+               +--------+
      | zipWith (*) +-------------->|  1:    +---+---> outs
      +-------------+               +--------+   |
           ^   ^                                 |
           |   |                                 |
           |   +---------------------------------+
           |
         [1..]

e em código:
       
> facts :: [Integer]                    
> facts = outs
>   where
>       outs = 1:zipWith (*) [1..] outs

O próximo diagrama calcula o fluxo que representa a sequência 
de Fibonacci:

   +-------------+               +--------+
   | zipWith (+) +-------------->|  1:1:  +---+--+---> outs
   +-------------+               +--------+   |  |
       ^    ^                                 |  |
       |    |                                 |  |
       |    +---------------------------------+  |
       |                +---------+              |
       +----------------+  tail   +<-------------+
                        +---------+

A ideia aqui é aproveitar o próprio fluxo duas vezes, mas 
atrasar uma delas, para somar os dois fluxos:

outs      == [1,1,2,3,5, 8,13,21,34,55, 89,144,233,377,610,...]
tail outs == [1,2,3,5,8,13,21,34,55,89,144,233,377,610,...]

Passo a passo ocorre o seguinte (o zipWith vai buscar as 
cabeças dos dois fluxos e soma-as):

                 outs         tail outs       fibs
zipWith (+)   [1,1,...]        [1,...]        [1,1]
zipWith (+)   [1,2,...]        [2,...]        [1,1,2]
zipWith (+)   [2,3,...]        [3,...]        [1,1,2,3]
zipWith (+)   [3,5,...]        [5,...]        [1,1,2,3,5]
...

o próximo número do fluxo é calculado pela soma dos dois valores 
anteriores (dado que tail atrasa um deles), ie, a definição da 
sequência de Fibonacci.

Em Haskell:
             
> fibs :: [Integer]             
> fibs = outs
>   where
>       outs = 1:1:zipWith (+) outs (tail outs)

---

As redes de processos permitem uma programação orientada a fluxos, 
com fluxos progressivamente mais complexos criados pela combinação 
de fluxos mais simples.

Main> take 10 $ runSums facts
[0,1,2,4,10,34,154,874,5914,46234]

Eg, a seguinte rede de processos efectua a fusão ordenada de 
dois fluxos ordenados:

> merge :: Ord a => [a] -> [a] -> [a]
> merge (x:xs) (y:ys) 
>   | x < y  = x : merge xs (y:ys)
>   | x > y  = y : merge (x:xs) ys
>   | x == y = x : merge xs ys

Podemos usá-la para combinar os fluxos anteriores:

Main> take 20 $ merge fibs facts
[1,1,2,3,5,6,8,13,21,24,34,55,89,120,144,233,377,610,720,987]

Main> takeWhile (<5000) $ filter even $ merge fibs facts
[2,6,8,24,34,120,144,610,720,2584]

Reparar que o merge não possui base da recursão, dado que se 
assumiu que os fluxos são infinitos. Se não for esse o caso, 
basta incluir as bases da recursão para lidar com listas vazias.
> {-# LANGUAGE BangPatterns #-}       -- veremos adiante o que significa

--------------------------------------------------------------------------------

A avalia��o de uma express�o, desde que termine e se respeite as 
preced�ncias, n�o depende da ordem pela qual estas fun��es s�o invocadas.

Por exemplo, seja a fun��o sucessor:

    succ x = x+1
    
se quisermos avaliar succ (2*3) podemos faz�-lo de duas formas:

    succ (2*3)
    succ 6
    6 + 1
    7
    
    succ (2*3)
    (2*3) + 1
    6 + 1
    7

Qualquer forma de avaliar uma express�o, desde que termine, 
ir� produzir o mesmo resultado.

Isto � poss�vel porque no Haskell a avalia��o de express�es n�o 
produz efeitos secund�rios.

Esta propriedade n�o � satisfeita numa linguagem onde existem 
efeitos secund�rios. Por exemplo a express�o Java:

    i + ++i;

produz resultados diferentes se avaliarmos primeiro a parte direita ou 
a parte esquerda (dado que ++i produz o efeito secund�rio de alterar 
o estado da vari�vel i).    
    
--------------------------------------------------------------------------------    

A avalia��o de uma express�o pode ser realizada de diferentes formas.

Seja a fun��o

    mult (x,y) = x*y

e a express�o mult(1+2, 2+3).

Vamos chamar a uma express�o que pode ser simplificada como redex 
(reducible expression). Neste exemplo h� tr�s redexs: 1+2, 2+3 e mult(1+2,2+3). 

Qual fazer primeiro?

A abordagem de linguagens como o Java, Python ou C � de avaliar 
as redexs mais interiores e, dentro dessas, come�ar pela esquerda. 
Assim, esta estrat�gia de avalia��o dar-nos-ia:

    mult(1+2, 2+3)
    mult(3, 2+3)
    mult(3, 5)
    3 * 5
    15

Esta estrat�gia garante que os valores dos par�metros est�o sempre 
avaliados quando a fun��o � avaliada. Chamamos a esta estrat�gia 
avalia��o estrita, ou gananciosa (strict or eager evaluation).

Outra estrat�gia � come�ar pelos redexs mais exteriores e, dentro desses, 
da esquerda para a direita. Vamos voltar a avaliar a express�o:

    mult(1+2, 2+3)
    (1+2) * (2+3)
    3 * (2+3)
    3 * 5
    15
    
A esta estrat�gia chamamos de avalia��o pregui�osa (lazy evaluation) 
sendo a avalia��o utilizada por default pelo Haskell.

--------------------------------------------------------------------------------

Vamos repetir a avalia��o na vers�o currificada da multiplica��o

    mult = \x y -> x*y
    
Avalia��o estrita:    

    mult (1+2) (2+3)
    mult 3 (2+3)          -- mult 3 � o redex mais � esquerda
    (\y -> 3*y) (2+3)
    (\y -> 3*y) 5
    3 * 5
    15
    
Avalia��o pregui�osa:

    mult (1+2) (2+3)
    (1+2) * (2+3)
    3 * (2+3)
    3 * 5
    15

--------------------------------------------------------------------------------

A lazy eval tem algumas vantagens em rela��o � strict eval.

Se uma fun��o n�o precisa calcular todos os argumentos, poupam-se 
computa��es:

    f x y = if x>0 then 2*x else x+y
    
Fa�amos uma avalia��o:    
    
    f 3 (2^1000)
    if 3>0 then 2*3 else 3+(2^1000)
    if True then 2*3 else 3+(2^1000)
    2*3
    6
    
Na strict eval ter�amos de calcular a pot�ncia antes de avaliar f

Isto significa que certas avalia��es podem terminar usando lazy 
eval mas n�o com strict eval:

    f 3 undefined
    if 3>0 then 2*3 else 3+undefined
    if True then 2*3 else 3+undefined
    2*3
    6

Na strict eval ter-se-ia de avaliar o 2� argumento antes de 
avaliar f, o que resultaria num erro.

A strict eval tem uma vantagem sobre a lazy eval, o n�mero de redexs a 
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
    
Mas existe uma forma de melhorar o desempenho da avalia��o pregui�osa. 
Um interpretador � capaz de perceber quando uma express�o � duplicada. 
Quando isso ocorre, ao avaliar a express�o pela primeira vez, 
o interpretador substitui todas as c�pias da express�o pelo resultado 
obtido. O Haskell utiliza esta estrat�gia optimizada.

Desta forma, a avalia��o anterior tem menos simplifica��es:

    sq (2+3)
    (2+3) * (2+3)
    5 * 5
    25

Quando usamos pattern matching, tamb�m aqui a lazy eval vai buscar 
apenas o necess�rio:

    f (x:xs) (y:ys) = x+y
    
avaliando:
    
    f [1..1000] [2..1000]
    f (1:[2..1000]) (2:[3..1000])
    1 + 2
    3
    
--------------------------------------------------------------------------------

Um outro ganho ocorre quando se aplica uma lista sobre v�rias fun��es.

Por exemplo, a seguinte avalia��o:

    sum (map (^2) [1..n])
    sum (1^2 : map (^2) [2..n])
    sum (1^2 : map (^2) [2..n])
    1^2 + sum (map (^2) [2..n])
    1^2 + sum (2^2 : map (^2) [3..n])
    1^2 + 2^2 + sum (map (^2) [3..n])
    ...
    1^2 + 2^2 + 3^2 + ... n^2
    ...

apenas percorre a lista uma vez, ao contr�rio da strict eval que 
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

> min' :: Ord a => [a] -> a   -- fun��o que devolve o m�nimo de uma lista
> min' = head' . isort

ou seja, estamos a sugerir que para encontrar o m�nimo de uma lista, 
fa�a-se uma ordena��o crescente e tire-se a cabe�a do resultado!! 
Em strict eval este algoritmo � O(n^2) mas o m�nimo pode ser implementado 
em O(n) dado que basta uma passagem pela lista para encontrar o menor valor.

Por�m:

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
para a cabe�a da lista, e no momento em que ele est� na cabe�a, o head pode 
ser avaliado e tudo o resto que falta fazer (ordenar o resto da lista) pode 
ser abandonado. A nossa implementa��o do m�nimo afinal � O(n)!

--------------------------------------------------------------------------------

Outra vantagem muito significativa, que j� temos referido nas aulas, � a 
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

Na avalia��o estrita esta express�o resultaria num ciclo infinito, dado 
que iria tentar avaliar a lista ones inteira, o que n�o � poss�vel!

Do ponto de vista da lazy eval, ones � uma lista potencialmente infinita, 
que pode ser avaliada parcialmente mas n�o totalmente. E esta capacidade 
de avaliar parcialmente uma express�o faz toda a diferen�a.

--------------------------------------------------------------------------------

A lazy eval permite libertar o programador de certas preocupa��es com a 
mem�ria para se focar nos algoritmos.

No seguinte exemplo vamos produzir a lista infinita de todos os primos 
usando o antigo algoritmo grego conhecido por Crivo de Erat�stenes e que 
funciona da seguinte forma:

1�) Listam-se todos os n�meros > 1

  primos:
  lista:  2 3 4 5 6 7 8 9 10 11 12 13 14 ...
  
2�) Guarda-se o 1� elemento desta lista e retiram-se todos os seus m�tiplos:

  primos: 2
  lista:    3   5   7   9    11    13    ...
    
3�) Repete-se 2�)

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

Cada invoca��o de sieve cria uma lista infinita com todos os n�meros 
dados excepto aqueles que s�o multiplos de p.

Main> take 20 $ primes
[2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71]

Este algoritmo n�o � eficiente mas mostra como um algoritmo que usa um 
ciclo infinito para produzir uma lista infinita pode ser programado 
via lazy eval.

Se tent�ssemos simular o mesmo em Java, ter�amos que nos preocupar com 
arrays de dimens�o limitada, e de como aumentar a sua dimens�o se o 
utilizador precisasse de primos maiores. Aqui toda essa gest�o � autom�tica.

--------------------------------------------------------------------------------

Avalia��o estrita em Haskell

Tamb�m � poss�vel usar avalia��o estrita no Haskell, n�o estamos restritos 
apenas a uma estrat�gia de avalia��o de express�es. 

Para tal existe a fun��o 'seq' do Prelude:

    seq :: a -> b -> b   
    
Esta fun��o avalia o primeiro argumento antes de devolver o segundo.

� atrav�s desta fun��o que se pode introduzir a avalia��o estrita para 
melhorar o desempenho em certos casos onde a lazy eval n�o � a melhor op��o.

De notar que se fizermos seq x x isso � o mesmo que avaliar x dado que 
o Haskell quando avalia uma express�o substitui todas as sauas c�pias 
pelo resultado.

A fun��o que se costuma usar � o operador ($!) definido da seguinte forma:

    ($!) :: (a -> b) -> a -> b   
    f $! x = x `seq` f x
    
Este � um operador infixo com associatividade � direita, ie, 

    x $! y $! z   ==    x $! (y $! z) 

A fun��o
    
    f x = g $! h $! x  
    
avalia primeiro a express�o 'x', depois avalia (h x) e s� depois 
aplica o resultado a 'g'

Comparemos a avalia��o de sq (2+3) e sq $! (2+3)

    sq (2+3)
    (2+3) * (2+3)
    5 * 5
    25
    
    sq $! (2+3)
    sq 5
    5 * 5
    25
    
No exemplo seguinte temos tr�s implementa��es de uma fun��o que calcula 
a dimens�o de uma lista:

> len :: [a] -> Int       -- defini��o recursiva habitual
> len   []   = 0
> len (x:xs) = len xs + 1

Esta implementa��o falha para listas muito grandes dado que as chamadas 
recursivas v�o-se acumulando na pilha de invoca��es:

Main> len [1..20000000]    -- stack overflow

vejamos como os redexs est�o a ser simplificados:

  len [1..20000000]
  len [2..20000000] + 1
  (len [3..20000000] + 1) + 1
  ((len [4..20000000] + 1) + 1) + 1
  ...

Podemos tentar usar recurs�o terminal para evitar acumular chamadas 
recursivas, mas temos um problema similar dado que o Haskell, por ser 
lazy, n�o soma os 1s:

> len2 xs = len' xs 0     -- defini��o com recurs�o terminal
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

A solu��o � for�ar o Haskell a somar o valor acumulado antes de avaliar a 
pr�xima recurs�o. Isto limita a dimens�o das express�es prevenindo 
o stack overflow:

> len3 xs = len' xs 0     -- defini��o com recurs�o terminal estrita
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

H� um ponto importante quando se usa o ($!) em estruturas de dados. 
A avalia��o que o Haskell faz � apenas o necess�rio para se perceber 
que n�o � undefined (ie, que a express�o pode ser avaliada e n�o d� erro). 
Por exemplo, para avaliar uma lista, o Haskell apenas avalia a cabe�a da 
lista. Logo, usar ($!) n�o implica que tudo � estritamente avaliado.

Se quisermos essse comportamente pode-se usar o operador ($!!) e a 
fun��o 'deepseq' que se encontram no m�dulo Control.DeepSeq. 
N�o iremos aprofundar esta tem�tica.

--------------------------------------------------------------------------------

Existe uma extens�o do Haskell, chamada "bang patterns", onde podemos 
definir que certos pattern matches s�o para ser avaliados estritamente. 
Para isso � preciso colocar no in�cio do programa a linha 

  {-# LANGUAGE BangPatterns #-}  
  
(agora j� podem ligar � primeira linha deste ficheiro)

Para informar o Haskell que um argumento � estrito devemos prefix�-lo com !

       Eg normal             |          Exemplo com !
-----------------------------+-------------------------------------
                             |   
 f x y = y                   |     f !x y = y
                             |    
Main> f undefined 3          |    Main> f undefined 3
3                            |    *** Exception: Prelude.undefined


A seguinte defini��o do len faz o mesmo que a fun��o len3 mas usa este prefixo:

> len4 xs = len' xs 0     -- defini��o com recurs�o terminal estrita
>   where
>    len'  []     acc = acc
>    len' (x:xs) !acc = len' xs (1 + acc)

Main> len4 [1..20000000]
20000000

ref: https://downloads.haskell.org/~ghc/7.8.4/docs/html/users_guide/bang-patterns.html

--------------------------------------------------------------------------------

O problema de stack overflow tamb�m ocorre quando processamos listas com fold's.

A vers�o len2 com recurs�o terminal pode ser implementada pelo foldl 
que, pela sua defini��o, processa a express�o com recursividade terminal:

> len2' :: [a] -> Int
> len2' = foldl (\acc x -> 1+acc) 0

e que produz o mesmo problema:

Main> len2' [1..20000000]
*** Exception: stack overflow

Nestes casos podemos usar a vers�o estrita do foldl, foldl', que 
est� dispon�vel no m�dulo Data.List mas que implementamos aqui:

> foldl' f z []     =  z
> foldl' f z (x:xs) =  (foldl' f $! f z x) xs

A vers�o estrita do len passa a ser

> len3' :: [a] -> Int
> len3' = foldl' (\acc x -> 1+acc) 0

e este j� funciona para valores maiores

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

O foldr n�o tendo recurs�o terminal, acumula as chamadas recursivas 
no operador (+)

Solu��o com foldl:

> mysum2 :: [Integer] -> Integer
> mysum2 = foldl (+) 0

O foldl tem recurs�o terminal mas o acumulador vai acumulando as somas que 
s� ser�o avaliadas no fim. Esta express�o acaba por gastar demasiada mem�ria:

  mysum2 [1..10]
  foldl (+) 0         (1:[2..10])
  foldl (+) (0+1)     (2:[3..10])
  foldl (+) (0+1+2)   (3:[4..10]) 
  foldl (+) (0+1+2+3) (4:[5..10]) 
  ...
  
O ideal seria ir avaliando as somas para que o acumulador fosse apenas 
o valor do somat�rio actual. Aqui entra o foldl'

> mysum3 :: [Integer] -> Integer
> mysum3 = foldl' (+) 0 

Agora temos o comportamento desejado:

  mysum3 [1..10] 
  foldl (+) 0 (1:[2..10])
  foldl (+) 1 (2:[3..10])
  foldl (+) 3 (3:[4..10])
  foldl (+) 6 (4:[5..10]) 
  ...
  
Fa�amos uma experi�ncia:
  
Main> mysum [1..20000000]
*** Exception: stack overflow

Main> mysum2 [1..20000000]
*** Exception: stack overflow

Main> mysum3 [1..20000000]
200000010000000  

ref: http://www.haskell.org/haskellwiki/Stack_overflow

--------------------------------------------------------------------------------

Estruturas c�clicas

As estruturas de dados podem ser definidas recursivamente, como no
caso das listas e das �rvores bin�rias. Estas estruturas, por�m,
n�o precisam ter uma base de recurs�o.

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
          
J� a defini��o:

> ones' = repeat' 1
>   where
>      repeat' x = x : repeat' x
  
vai crescendo � medida que � avaliado, porque o Haskell n�o consegue
intuir que se trata do mesmo valor:

ones'
  = 1:repeat' 1
  = 1:1:repeat' 1
  = ...

Uma compara��o de desempenho:
  
Main> ones !! 1000000
1
(0.00 secs, 87,232 bytes)

Main> ones' !! 1000000
1
(0.42 secs, 64,088,528 bytes)

Do ponto de vista sem�ntico n�o h� qualquer diferen�a entre estas
duas defini��es. Nenhuma fun��o conseguiria distinguir entre as duas.

Uma lista c�clica constitui um 'loop na mem�ria', necessitando
apenas de espa�o constante para ser guardada.

Se as listas c�clicas s�o listas infinitas, nem todas as listas
infinitas t�m uma vers�o c�clica (eg, a lista dos n�meros primos).

Esta discuss�o n�o tem a ver com o Haskell (a linguagem � agn�stica 
nestas quest�es) mas com as estrat�gias do GHC para optimizar a 
avalia��o de express�es.

---

Outro exemplo, agora com dois argumentos:

> cyclic = let x = 0 : y  -- vers�o c�clica
>              y = 1 : x
>          in  x

                                                                                
                 +-------+          +-------+
             +-->|   1:  |--------->|   0:  |------> cyclic
             |   +-------+          +-------+
             |                          |
             +--------------------------+
  
> cyclic' = repeat' 0 1   -- vers�o n�o c�clica
>   where
>      repeat' x y = x : y : repeat' x y

Main> cyclic !! 1000000
0
(0.05 secs, 29,760 bytes)

Main> cyclic' !! 1000000
0
(0.28 secs, 36,027,992 bytes)

---

Outro exemplo: a fun��o iterate do Prelude produz a seguinte lista infinita

    iterate f x = x : f x : f (f x) : ...
    
Uma poss�vel defini��o recursiva seria

> iterate' f x = x : map f (iterate' f x)

mas esta defini��o n�o cria uma estrutura c�clica (temos a chamada
recursiva da fun��o na express�o). A seguinte j� o faz:

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

Existe por�m um pre�o a pagar. Nas listas c�clicas o Haskell mant�m
a lista inteira em mem�ria, enquanto nas listas infinitas a garbage
collection pode funcionar e manter apenas um n�mero limitado de 
elementos da lista. Para listas que v�o crescendo (como no caso do
iterate) isto pode tornar-se um problema.

ref: http://stackoverflow.com/questions/25498431

--------------------------------------------------------------------------------

Redes de Fluxos (stream networks, tamb�m chamadas process networks)

Estas listas podem servir para modelar fluxos de informa��o (streams). 

Neste primeiro exemplo queremos receber uma lista infinita de inteiros e 
devolver uma lista de somas parciais. 

Por exemplo,

Main> take 20 $ runSums [1..]
[0,1,3,6,10,15,21,28,36,45,55,66,78,91,105,120,136,153,171,190]

devolve uma lista cujo elemento no ind�ce i corresponde � soma dos 
primeiros i elementos da lista dada.

Ora isto significa que para calcular o pr�ximo elemento da lista 
final, basta ir buscar a soma anterior e juntar o pr�ximo elemento. 
No caso acima ter�amos:

    [0, 0+1, 1+2, 3+3, 6+4, 10+5, 15+6, 21+7, 28+8, ...]
                             ^ ^
    soma at� agora ----------+ |
    pr�ximo elemento ----------+

Podemos representar este processo num diagrama onde h� dois fluxos, 
o fluxo de entrada (a lista dada) e um fluxo com as somas realizadas 
at� ent�o (que inicia-se no zero). Para juntar os dois fluxos, somando 
elemento a elemento, podemos usar a fun��o zipWith (+)

            +-------------+               +--------+
   ins ---->| zipWith (+) +-------------->|   0:   +---+--> outs
            +-------------+               +--------+   |
                     ^                                 |
                     |                                 |
                     +---------------------------------+

Em c�digo Haskell esta ideia traduz-se em:

> runSums :: [Integer] -> [Integer]        
> runSums ins = outs
>   where
>       outs = 0:zipWith (+) ins outs
      
Outro eg, para criar um fluxo com todos os factoriais podemos 
multiplicar o pr�prio fluxo dos factoriais (que come�amos com 
o 0!=1) com o fluxo dos n�meros naturais, ie,

    [1, 1*1, 1*2, 2*3, 6*4, 24*5, 120*6, 720*7, ... ]
                                   ^  ^
    produt�rio at� agora ----------+  |
    pr�ximo elemento -----------------+
    
Em diagrama:
      
      +-------------+               +--------+
      | zipWith (*) +-------------->|  1:    +---+---> outs
      +-------------+               +--------+   |
           ^   ^                                 |
           |   |                                 |
           |   +---------------------------------+
           |
         [1..]

e em c�digo:
       
> facts :: [Integer]                    
> facts = outs
>   where
>       outs = 1:zipWith (*) [1..] outs

O pr�ximo diagrama calcula o fluxo que representa a sequ�ncia 
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

A ideia aqui � aproveitar o pr�prio fluxo duas vezes, mas 
atrasar uma delas, para somar os dois fluxos:

outs      == [1,1,2,3,5, 8,13,21,34,55, 89,144,233,377,610,...]
tail outs == [1,2,3,5,8,13,21,34,55,89,144,233,377,610,...]

Passo a passo ocorre o seguinte (o zipWith vai buscar as 
cabe�as dos dois fluxos e soma-as):

                 outs         tail outs       fibs
zipWith (+)   [1,1,...]        [1,...]        [1,1]
zipWith (+)   [1,2,...]        [2,...]        [1,1,2]
zipWith (+)   [2,3,...]        [3,...]        [1,1,2,3]
zipWith (+)   [3,5,...]        [5,...]        [1,1,2,3,5]
...

o pr�ximo n�mero do fluxo � calculado pela soma dos dois valores 
anteriores (dado que tail atrasa um deles), ie, a defini��o da 
sequ�ncia de Fibonacci.

Em Haskell:
             
> fibs :: [Integer]             
> fibs = outs
>   where
>       outs = 1:1:zipWith (+) outs (tail outs)

---

As redes de processos permitem uma programa��o orientada a fluxos, 
com fluxos progressivamente mais complexos criados pela combina��o 
de fluxos mais simples.

Main> take 10 $ runSums facts
[0,1,2,4,10,34,154,874,5914,46234]

Eg, a seguinte rede de processos efectua a fus�o ordenada de 
dois fluxos ordenados:

> merge :: Ord a => [a] -> [a] -> [a]
> merge (x:xs) (y:ys) 
>   | x < y  = x : merge xs (y:ys)
>   | x > y  = y : merge (x:xs) ys
>   | x == y = x : merge xs ys

Podemos us�-la para combinar os fluxos anteriores:

Main> take 20 $ merge fibs facts
[1,1,2,3,5,6,8,13,21,24,34,55,89,120,144,233,377,610,720,987]

Main> takeWhile (<5000) $ filter even $ merge fibs facts
[2,6,8,24,34,120,144,610,720,2584]

Reparar que o merge n�o possui base da recurs�o, dado que se 
assumiu que os fluxos s�o infinitos. Se n�o for esse o caso, 
basta incluir as bases da recurs�o para lidar com listas vazias.
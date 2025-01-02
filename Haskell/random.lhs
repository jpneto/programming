> import Data.List
> import System.Random
> import Control.Monad
> import Text.Printf (printf)

A geração de aleatoriedade no Haskell não pode existir no contexto
das funções. A aleatoriadade exige algum tipo de estado para poder 
gerar valores distintos.

Como no caso do IO, os processos aleatórios são definidos numa mónada.

A typeclass RandomGen é a interface comum dos geradores aleatórios.

Existe um gerador default designado StdGen. A forma normal para criar
um StdGen é através da função mkStrGen que cria um gerador novo dada
uma semente inteira

  mkStdGen :: Int -> StdGen

> seed = 123
> aGenerator = mkStdGen seed

Neste tutorial não iremos criar outros tipos de RandomGen.

--------------------------------------------------------------------

Para gerarmos valores aleatórios de um tipo T, é preciso que 
o tipo T seja instância de outra typeclasse: Random. 
Os vários tipos primitivos já foram definidos como suas instâncias.

Assim, para gerar uma lista de valores aleatórios podemos usar

  randoms :: (RandomGen g, Random a) => g -> [a]
  
ou seja, dado um gerador g, é possível gerar valores de um tipo 'a'
qualquer desde que 'a' seja instância de Random
  
Main> take 6 $ randoms aGenerator :: [Int]
[1038851507,1834550796,2046247850,1709637579,2011955188,-2110545476]

Main> take 6 $ randoms aGenerator :: [Bool]
[True,True,True,False,False,False]

Outra função útil é randomRs  

  randomRs :: (RandomGen g, Random a) => (a, a) -> g -> [a]
  
que gera valores entre um dado intervalo:
    
Main> take 16 $ randomRs (3,6) aGenerator :: [Int]
[6,4,6,5,5,5,5,6,3,3,6,5,6,6,6,5]

Main> take 4 $ randomRs (0.0,1.0) aGenerator
[0.7804356004944119,0.31085185007462024,0.31833394271081894,0.363270105065991]

De notar que o randoms e randomRs são funções puras. Para o mesmo gerador,
as funções devolvem os mesmos valores:

Main> take 16 $ randomRs (3,6) aGenerator :: [Int]
[6,4,6,5,5,5,5,6,3,3,6,5,6,6,6,5]

Main> take 16 $ randomRs (3,6) aGenerator :: [Int]
[6,4,6,5,5,5,5,6,3,3,6,5,6,6,6,5]

A ideia é ir actualizando o gerador que passamos para estas funções.
Veremos adiante como fazer.

--------------------------------------------------------------------

O equivalente, no contexto IO, é a função randomRIO

  randomRIO :: Random a => (a, a) -> IO a
  
onde se define no par (a,a) o intervalo válido para a geração 
de valores

> run01:: Int -> Int -> Int -> IO ()
> run01 n minVal maxVal =
>   do xs <- replicateM n (randomRIO (minVal,maxVal))
>      mapM_ print xs

Main> run01 4 1 6    -- pedir 4 lançamentos de um dado de seis faces
2
5
1
5

--------------------------------------------------------------------

O módulo disponibiliza um gerador aleatório global. 
Para ir buscá-lo usamos 

  getStdGen :: IO StdGen

Um exemplo:

> run02 = 
>   do g <- getStdGen
>      print $ take 10 (randomRs ('a','z') g)

Main> run02
"qbewpjjezb"

Main> run02
"qbewpjjezb"

O resultado não muda porque este gerador é inicializado no início da sessão
(daria valores diferentes se executado em sessões diferentes, ou na linha
de comandos via o runhaskell).

Main> run02
"sowlyincpi"

Main> :reload
Ok, modules loaded: Main.

Main> run02
"nrvopmwoaj"

Para obter valores distintos na mesma sessão usamos o 'newStdGen'

> run02' = 
>   do g <- newStdGen
>      print $ take 10 (randomRs ('a', 'z') g)

Main> run02'
"iuyqxavzdu"

Main> run02'
"wfsnbnwbwv"

--------------------------------------------------------------------

Um exemplo: criar uma função que imprime uma sequência aleatória de n bits
(aqui interpretamos bits como os inteiros 0 e 1)

> bitSeq :: Int -> IO ()
> bitSeq n =
>   do gen <- newStdGen
>      putStrLn $ (concat . map show . take n) (randomRs (0,1) gen::[Int])
    
Main> bitSeq 20
01110010101011100011

Main> bitSeq 20
01000010111011010001
    
--------------------------------------------------------------------

Outro exemplo (exercício IX.6b das folhas)

Considere que cada carta de um baralho é representada por um número inteiro
entre 1 e 52. Escreva uma função que devolva uma mão de cartas de jogar, 
composta por um dado número de cartas.
  
> mao :: Int -> IO [Int]
> mao n = 
>   do gen <- getStdGen
>      return (take n . nub $ randomRs (1,52) gen)

Main> mao 13
[48,50,16,8,3,9,33,6,41,7,49,21,13]

--------------------------------------------------------------------

Para incluir novos tipos aleatórios temos de instanciá-los 
na typeclass Random.

Vejamos o exemplo para o lançamento de uma moeda:

> data Coin = Heads | Tails 
>   deriving (Eq, Ord, Show, Enum, Bounded)

> instance Random Coin where
>   randomR (a, b) g =
>     case randomR (fromEnum a, fromEnum b) g of
>       (x, g') -> (toEnum x, g')
>   random g = randomR (minBound, maxBound) g

É preciso definir a função randomR 

  randomR :: (Random a, RandomGen g) => (a, a) -> g -> (a, g)
  
que dado um intervalo limitado e um gerador, devolve
um par onde a primeira componente é o valor aleatório e a
segunda componente é o *próximo gerador a ser usado*!

Este segundo gerador costuma ser produzido pelos randomR
dos tipos primitivos. Neste exemplo usámos o tipo inteiro
ao converter os valores do enumerado via a função

    fromEnum :: Enum a => a -> Int  

Já a outra função, random, tem uma definição quase sempre
similar à usada neste exemplo.

O uso do typeclass Bounded (que representa tipos limitados) serve 
apenas para não nos preocuparmos com o valor mínimo e máximo do tipo, 
basta escrever minBound e maxBound para obter esses. Estes valores 
são importantes para limitar os valores que a função random pode 
produzir.

Exemplo de uso:

> flipCoins n =
>   do g <- newStdGen
>      print . take n $ (randoms g :: [Coin])

Main> flipCoins 6
[Tails,Tails,Tails,Tails,Heads,Tails]

Main> flipCoins 6
[Tails,Tails,Heads,Tails,Heads,Heads]

--------------------------------------------------------------------

A seguinte função devolve um par com o número de moedas e o número
de valor 'Heads' (caras).

> process :: [Coin] -> (Int, Int)
> process cs = (length cs, length (filter (== Heads) cs))

> runProcess n =
>   do g <- newStdGen
>      let coins = take n $ (randoms g :: [Coin])
>      return $ process coins

Main> runProcess 5
(5,2)

Main> runProcess 10
(10,5)

Podemos verificar se o número de Caras é gerado perto das 50% das vezes:

> computeHeads :: Int -> (Int, Int) -> IO ()
> computeHeads 16 _ = return ()
> computeHeads  n (totalFlips, totalHeads) = 
>   do g <- newStdGen
>      let coins               = take (2^n) $ (randoms g :: [Coin])
>      let (count,heads)       = process coins
>      let (newTotal,newHeads) = (totalFlips+count, totalHeads+heads)
>      let ratio = (fromIntegral newHeads / fromIntegral newTotal)::Double
>      print $ "Obtemos " ++ printf "%0.2f" (100.0 * ratio) ++ 
>              "% de caras num total de " ++ 
>              printf "%5d" newTotal ++ " lancamentos."
>      computeHeads (n+1) (newTotal,newHeads)

> run03 = computeHeads 1 (1,1)

Main> run03
"Obtemos 66.67% de caras num total de     3 lancamentos."
"Obtemos 28.57% de caras num total de     7 lancamentos."
"Obtemos 40.00% de caras num total de    15 lancamentos."
"Obtemos 48.39% de caras num total de    31 lancamentos."
"Obtemos 57.14% de caras num total de    63 lancamentos."
"Obtemos 54.33% de caras num total de   127 lancamentos."
"Obtemos 52.94% de caras num total de   255 lancamentos."
"Obtemos 52.05% de caras num total de   511 lancamentos."
"Obtemos 49.07% de caras num total de  1023 lancamentos."
"Obtemos 50.66% de caras num total de  2047 lancamentos."
"Obtemos 50.18% de caras num total de  4095 lancamentos."
"Obtemos 50.16% de caras num total de  8191 lancamentos."
"Obtemos 50.16% de caras num total de 16383 lancamentos."
"Obtemos 49.94% de caras num total de 32767 lancamentos."
"Obtemos 50.08% de caras num total de 65535 lancamentos."

--------------------------------------------------------------------
    
Refs:
  https://en.wikibooks.org/wiki/Haskell/Libraries/Random
  https://hackage.haskell.org/package/random-1.1/docs/System-Random.html
  www.schoolofhaskell.com/school/starting-with-haskell/libraries-and-frameworks/randoms
  
> {-# LANGUAGE FlexibleInstances #-}  -- não ligar numa primeira leitura

--------------------------------------------------------------------

> import Test.QuickCheck

> import qualified Data.List as DL
> import Text.Printf (printf)
> import Control.Monad

--------------------------------------------------------------------

O objectivo da seguinte função é inverter uma lista:

> reverse' xs = rev xs [] 
>    where
>       rev   []   acc = acc
>       rev (x:xs) acc = rev xs (x:acc)

Para determinar se a função está correta, temos de especificar o 
que significa uma lista invertida. 

Dada uma lista xs, ys é a lista invertida se e só se cumprir as 
seguintes propriedades:

 * xs e ys têm o mesmo tamanho
 * para todo o índice de xs: xs!!i == ys!!(último indice de xs - 1)
 
Podemos implementar estas propriedades em Haskell e verificar,
com valores de teste, se elas são respeitadas.

A seguir vamos testar as propriedades com listas de inteiros.
É necessário escolher um tipo concreto mesmo que as funções a 
testar sejam polimórficas.

> prop_reverse_len :: [Int] -> Bool
> prop_reverse_len xs = length (reverse' xs) == length xs

> prop_reverse_index :: [Int] -> Int -> Bool
> prop_reverse_index [] _ = null $ reverse' []
> prop_reverse_index xs i = (reverse' xs)!!(lastIndex-i) == xs!!i
>    where
>       lastIndex = length xs - 1

E agora podemos testar:

Main> prop_reverse_len [1,2,3]
True

Main> let xs = [1,2,3] in [prop_reverse_index xs i | i <- [0..length xs-1]]
[True,True,True]

Mas este método não é prático para testar muitas listas.

--------------------------------------------------------------------

O objectivo do módulo Test.QuickCheck é automatizar a produção de 
valores de teste.

Neste caso do reverse podíamos fazer assim:

Main> quickCheck prop_reverse_len
+++ OK, passed 100 tests.

Mas temos um problema com a 2a propriedade:

Main> quickCheck prop_reverse_index
*** Failed! Exception: 'Prelude.!!: negative index' 

Isto ocorre porque o QuickCheck gera listas e inteiros aleatórios 
para testar esta propriedade, e isso inclui valores negativos!
Assim, podemos alterar um pouco a propriedade prop_reverse_index 
para garantir que os i's gerados são índices válidos:

> prop_reverse_index' :: [Int] -> Int -> Bool
> prop_reverse_index' [] _ = null $ reverse' []
> prop_reverse_index' xs i = (reverse' xs)!!(lastIndex-j) == xs!!j
>    where
>       lastIndex = length xs - 1
>       j = abs $ mod i (length xs)   -- safe index

Main> quickCheck prop_reverse_index'
+++ OK, passed 100 tests.

O QuickCheck testou com 100 listas diferentes para cada propriedade!

Se quisermos ver que exemplos foram testados usar:

Main> (quickCheck.verbose) prop_reverse_index'
Passed:
[]
0
Passed:
[-1]
-1
Passed:
[-1,1]
2
Passed:
[3,-1]
1
...

--------------------------------------------------------------------

Podemos definir o número de testes que o QuickCheck efectua:

Main> quickCheckWith stdArgs {maxSuccess = 1000} prop_reverse_index'
+++ OK, passed 1000 tests.

Os testes não demonstram a correcção da função, mas quando o reverse 
passa os testes das propriedades que definem a sua especificação, 
aumentamos a nossa confiança na sua correcção.

Como disse Edsger Dijkstra, testar prova apenas a existência de 
bugs, não a sua ausência.

--------------------------------------------------------------------

Existem mais argumentos que podem ser passados:

 args = Args {maxSuccess = 100, -- definir número de sucessos mínimo
              maxDiscard = 50,  -- definir número de insucessos máximo
              maxSize = 200,    -- definir a dimensão máxima dos valores testados
              chatty = True}    -- imprimir ou não os resultados

testar com: quickCheckWith args prop_repl1

--------------------------------------------------------------------

Vamos testar com uma versão do reverse' com um bug:

> reverse'' xs = rev xs [] 
>    where
>       rev   []   acc = [] -- bug!
>       rev (x:xs) acc = rev xs (x:acc)

> prop_reverse_len2 :: [Int] -> Bool
> prop_reverse_len2 xs = length (reverse'' xs) == length xs

Main> quickCheck prop_reverse_len2
*** Failed! Falsifiable (after 5 tests and 2 shrinks): 
[0]

O que nos indica que falhou no teste da lista [0]. Foi detectada 
uma falha na execução da propriedade length.

Uma falha é a manifestação de um comportamento não esperado.
As falhas surgem pela existência de faltas (bugs) no código.
Neste caso o QuickCheck avisou-nos para a existência de uma falta 
que produz uma falha na reversão da lista [0].

--------------------------------------------------------------------

Exercício

Outra forma de especificar reverse xs é dizer que a função tem 
de satisfazer as seguintes propriedades:

    reverse [x] == [x]
    
    reverse (xs++ys) == reverse ys ++ reverse xs
    
    reverse (reverse xs) == xs
    
Defina estas propriedades e teste-as com o QuickCheck para
listas de inteiros.  

-------------------------------------------------------------------

Vejamos outro exemplo.

Seja a função inserir um elemento ordenadamente numa lista ordenada:

> insert :: Ord a => a -> [a] -> [a]
> insert x [] = [x]
> insert x (y:ys)
>    | x <= y    = x:y:ys
>    | otherwise = y:insert x ys

Main> insert 3 [1,2,4,5]
[1,2,3,4,5]

Que propriedades tem esta função de satisfazer, ie, qual a sua
especificação?

    * extra_elem: O resultado tem mais um elemento que a lista original
    * all_there : O resultado tem os elementos originais e o novo elemento
    * ordered   : O resultado tem de estar ordenado

Como programar estas propriedades em Haskell?

Vamos precisar de um predicado auxiliar que verifica se uma lista
está ordenada (e vamos assumir que esta função está correta, mas 
podíamos testá-la também).

> ordered []  = True
> ordered [x] = True
> ordered (x:y:xs) = x <= y && ordered (y:xs)

Vamos construir os testes para lidar com inteiros:

> prop_extra_elem :: Int -> [Int] -> Bool
> prop_extra_elem x xs = length xs + 1 == length (insert x xs)

Main> quickCheck prop_extra_elem
+++ OK, passed 100 tests.

> prop_all_there :: Int -> [Int] -> Bool
> prop_all_there x xs = xs DL.\\ newList == [] && newList DL.\\ xs == [x]
>   where
>     newList = insert x xs

Main> quickCheck prop_all_there
+++ OK, passed 100 tests.

Para a terceira propriedade é importante considerar a pré-condição do insert: 
a lista dada tem de já estar ordenada. Ou seja, esta propriedade é condicional! 
Para lidar com estas situações, o QuickCheck inclui um operador de implicação ==>
    
> prop_ordered :: Int -> [Int] -> Property
> prop_ordered x xs = ordered xs ==> ordered $ insert x xs

Main> quickCheck prop_ordered
*** Gave up! Passed only 77 tests.

Agora tivemos um resultado diferente. O teste não encontrou contra-exemplos 
mas foi incapaz de gerar todos os 100 testes. 

Como existe uma pré-condição o QuickCheck rejeita as listas criadas 
aleatoriamente que não estão ordenadas. Ele tenta 1000 vezes, e se não 
conseguir desiste, dizendo quantas vezes conseguiu.

Podemos aumentar o número de testes:

Main> quickCheckWith stdArgs {maxSuccess = 10000} prop_ordered
*** Gave up! Passed only 5462 tests.

Mas também podemos ficar desconfiados se o QuickCheck está a usar
listas muito simples. Uma forma é introduzir na propriedade alguns
elementos de monitorização:

> prop_ordered' :: Int -> [Int] -> Property
> prop_ordered' x xs = ordered xs ==> 
>                         classify (null xs)        "empty" $
>                         classify (length xs == 1) "singletons" $
>                         ordered $ insert x xs

Main> quickCheck prop_ordered'
*** Gave up! Passed only 74 tests:
47% singletons
32% empty

E percebemos que 79% das listas são trivialmente ordenadas!

Podemos ter um relatório mais pormenorizado com a função collect:

> prop_ordered'' :: Int -> [Int] -> Property
> prop_ordered'' x xs = ordered xs ==> 
>                          collect (length xs) $
>                          ordered $ insert x xs

Main> quickCheck prop_ordered''
*** Gave up! Passed only 69 tests:
42% 0
33% 1
11% 2
10% 3
 1% 5
 1% 4
 
Existem muitos poucos testes que possuem uma dimensão não trivial. Isto
não é de admirar dado que não é fácil que uma lista gerada aleatoriamente
seja ordenada. 

Outa forma de abordar o problema passa por receber uma lista e
ordená-la antes de efectuar o teste:

> prop_ordered''' :: Int -> [Int] -> Bool
> prop_ordered''' x xs = ordered $ insert x sortXs
>   where
>     sortXs = DL.sort xs
 
Main> quickCheck prop_ordered'''
+++ OK, passed 100 tests.

--------------------------------------------------------------------



--------------------------------------------------------------------

Para evitar estar a avaliar o QuickCheck para cada propriedade,
podemos criar suites de testes, sendo estes todos avaliados
sequencialmente:

> suite_test_insert = 
>   do quickCheck prop_extra_elem
>      quickCheck prop_all_there
>      quickCheck prop_ordered'''

Main> suite_test_insert
+++ OK, passed 100 tests.
+++ OK, passed 100 tests.
+++ OK, passed 100 tests.

--------------------------------------------------------------------

Podemos incluir propriedades que verifiquem casos específicos
que não temos a garantia de estarem a ser testados pelos
valores aleatórios gerados pelo QuickCheck.

Por exemplo, será que estamos a testar a inserção de valores que
já existem na lista original? A próxima propriedade testa esta
questão:

> prop_already_there xs =
>      forAll (elements xs) $ \x -> ordered $ insert x xs

Main> quickCheck prop_already_there
+++ OK, passed 100 tests.

A função forAll exige que todos os valores gerados a seguir
satisfaçam a propriedade que se segue. A função elements gera 
aleatoriamente um dos elementos da lista dada (mais sobre
o elements a seguir).

--------------------------------------------------------------------

É possível abordar testes para funções que lidam com listas infinitas.

Por exemplo, a função cycle repete o conteúdo de uma lista não vazia
ad infinitum.

Main> take 11 $ cycle "ab"
"abababababa"

Para validar esta função podemos testar a seguinte propriedade:

   cycle xs == cycle (xs++xs)

Mas como testar esta igualdade, dado que não podemos comparar listas
infinitas? Uma forma é escolher um valor inteiro positivo n, fazer
o take n de ambas as listas e verificar a sua igualdade.

> prop_cycle_twice :: [Int] -> Int -> Property
> prop_cycle_twice xs n = not (null xs) && n >= 0 
>                            ==> take n (cycle xs) == take n (cycle (xs++xs))

Main> quickCheck prop_cycle_twice
+++ OK, passed 100 tests.

--------------------------------------------------------------------

Outra função útil que o QuickCheck disponibiliza é a possibilidade de
dar timeout se um teste estiver a demorar muito tempo.

    within :: Testable prop => Int -> prop -> Property
    
A função within prefixa um dado número de microsegundos que
espera para que a avaliação da propriedade termine. Senão
o teste falha com timeout.

Main> quickCheckWith stdArgs {maxSuccess = 100000} $ within 100 prop_cycle_twice
*** Failed! Exception: '<<timeout>>' (after 26004 tests)
   
--------------------------------------------------------------------

É possível visualizar amostras aleatórias criadas pelo QuickCheck.

Para tal podemos usar a função

    sample :: Show a => Gen a -> IO ()
    
que mostra os dados no std output

Main> sample (vector 4 :: Gen [Int])   -- falaremos do vector adiante
[0,0,0,0]
[1,-2,1,1]
[-3,-1,-4,-4]
[4,4,4,2]
[2,8,6,0]
[-10,6,4,3]

Se pretendermos criar a amostra e usá-la num programa IO temos o sample':

> useSample' :: IO ()
> useSample' =
>   do xs <- sample' (vector 4 :: Gen [Int])
>      mapM (putStrLn . show) xs
>      return ()
   
Main> useSample'
[0,0,0,0]
[2,0,2,2]
[1,1,-2,2]
[4,-4,-6,-3]
[-1,5,-4,-1]
[10,10,-10,9]
   
--------------------------------------------------------------------
   
Os métodos de monitorização classify/collect são importantes para 
validar se os casos de teste são suficientemente representativos. 
Afinal, testar o insert apenas com listas triviais não nos ajuda 
muito a testar a sua correcção.

Idealmente, os dados gerados aleatoriamente devem seguir a mesma
distribuição dos dados reais. Como normalmente não se conhece
a distribuição dos dados reais, um substituto é uma criar uma
distribuição que gere dados o mais diferente possível para
tentar aumentar a probabilidade de encontrar falhas.

O QuickCheck dá a possibilidade ao programador de criar as suas
próprias distribuições de dados.

O tipo 'Gen a' representa um gerador de valores de tipo a.

Para criar geradores, entre várias funções disponíveis, temos

    * elements :: [a] -> Gen a               selecciona um dos elementos
    * choose :: Random a => (a, a) -> Gen a  seleciona dentro de um intervalo
    * oneof :: [Gen a] -> Gen a              seleciona um dos geradores
    * listOf :: Gen a -> Gen [a]             cria um gerador de listas de a
    * vectorOf :: Int -> Gen a -> Gen [a]    cria um gerador de listas de tamanho fixo
    * frequency :: [(Int, Gen a)] -> Gen a   seleciona com ponderações
    * shuffle :: [a] -> Gen [a]              gera uma permutação aleatória

que podem ser combinadas. 

Vejamos alguns exemplos:

Main> sample $ elements "aeiou"
'o'
'o'
'u'
'e'
'a'

Main> sample $ choose (0,3)
0
1
2
0
2

Main> sample $ choose (0.0,3.0)
2.6572966846504205
2.1403568913812214
2.600959881612627
2.149169999694159
1.2492729615475946

Main> sample $ oneof [elements [10,20,30], choose (0,3)]
0
2
20
10
2

Main> sample $ listOf $ elements ['a'..'z']
""
"yaa"
"jvorgyncqephr"
"liwkc"
"rssv"

Main> sample $ vectorOf 8 $ elements ['a'..'z']
"qfdwyjtb"
"ichnerde"
"xbpedqgx"
"jrcocrtl"
"mmehuhrj"

-- neste caso os valores do elements são escolhidos 75% das vezes
Main> sample $ frequency [(3,elements [10,20,30]), (1,choose (0,3))]
2
30
20
30
10
30
30
3
0

Main> sample $ shuffle [1..5]
[5,2,1,4,3]
[4,3,5,2,1]
[3,1,5,4,2]
[1,4,2,3,5]
[3,2,4,1,5]

Main> sample $ vectorOf 2 (vector 4 :: Gen [Int])  
[[0,0,0,0],[0,0,0,0]]
[[1,-1,-1,-1],[2,-2,0,-2]]
[[3,-1,4,3],[-2,4,2,0]]
[[-3,0,4,4],[-4,4,1,-1]]
[[-2,-3,-2,-4],[-1,-5,8,1]]
[[-3,-7,10,2],[5,3,5,-6]]

--------------------------------------------------------------------

Estas funções, como referido, são úteis para criar geradores:

> positives :: Gen Int  -- gerador de números positivos
> positives =
>   do x <- arbitrary   -- devolve um inteiro: falaremos do arbitrary adiante
>      return $ (+1) $ abs x

Main> sample positives
1
3
4
2
7
6
13

Main> sample $ vectorOf 5 positives
[1,1,1,1,1]
[3,2,2,1,3]
[3,4,1,2,3]
[6,3,4,7,7]

---

> validIndex n =       -- índice válido para uma lista com n elementos
>   do x <- positives
>      return $ mod x n

Main> sample $ validIndex 5
1
3
2
0
3
2

Main> sample $ listOf $ validIndex 10
[]
[]
[3,1,3,2]
[7,5]
[9]
[0,7,1,7,3,9,0]
[3,6,2,5,5]
[2,4,4,3,0,8,3,5,0]

---

> sumDice :: Gen Int   -- gerador da soma de dois dados
> sumDice = 
>   do d1 <- choose (1,6)
>      d2 <- choose (1,6)
>      return (d1+d2)

Main> sample sumDice
11
3
8
5
9
4
7

Podemos testar se a distribuição dos lançamentos parece razoável:

> prop_2dice = forAll sumDice $ 
>                  \sum -> collect (sum) $ 
>                  sum>=2 && sum <=12

Main> quickCheckWith stdArgs {maxSuccess = 10000} prop_2dice
+++ OK, passed 10000 tests:
16% 7
13% 8
13% 6
10% 9
10% 5
 8% 4
 8% 10
 5% 3
 5% 11
 2% 2
 2% 12

---

O código seguinte cria o tipo Shape:

> data Shape = Circle Double | Rect Double Double
>   deriving (Show)

e um gerador de valores deste tipo:

> genShape :: Gen Shape
> genShape =
>   do shape <- choose (1,2) :: Gen Int
>      case shape of
>         1 -> do radius <- choose (0.0,1.0) :: Gen Double 
>                 return $ Circle radius
>         2 -> do a <- choose (0.0,5.0) :: Gen Double
>                 b <- choose (0.0,5.0) :: Gen Double
>                 return $ Rect a b

Main> sample genShape
Rect 3.0150621125566306 0.8983247913589187
Circle 0.8027260358863824
Circle 4.339045252458318e-3
Rect 1.6550075683764753 3.6934934231774683

--------------------------------------------------------------------
--------------------------------------------------------------------

O QuickCheck permite definir, para um dado tipo, um gerador por default. 
Para tal, o módulo inclui o typeclass Arbitrary:

    class Arbitrary a where
       arbitrary :: Gen a

O nome do gerador por default é 'arbitrary' que tem de ser definido 
para cada novo tipo. 
      
É através deste typeclass que o QuickCheck pode criar valores de 
qualquer tipo instanciado. Isto facilita a geração de valores aleatórios 
de estruturas de dados arbitrárias, como listas ou árvores binárias.

Os tipos primitivos do Haskell já estão definidos como Arbitrary,
bem como listas e tuplos.

Por exemplo, se assumirmos que o genShape é o gerador por default
do tipo Shape, basta fazer:

> instance Arbitrary Shape where
>    arbitrary = genShape

Main> sample (arbitrary :: Gen Shape)
Rect 0.14138049471364544 2.070049291847563
Rect 0.17672096544572968 2.0965531725343736
Circle 0.29833059320749045
Circle 0.7224780509604535
Rect 3.7230040529984954 4.205842002970325

---

Vejamos outros exemplos de como tornar os nossos tipos 
em instâncias do typeclass Arbitrary.

A função elements é útil para tipos enumerados:

> data Semaforo = Verde | Amarelo | Encarnado
>    deriving (Eq, Show)

> instance Arbitrary Semaforo where
>    arbitrary = elements [Verde, Amarelo, Encarnado]
 
em alternativa podemos usar o oneof:

  instance Arbitrary Semaforo where
     arbitrary = oneof [ return Verde, 
                         return Amarelo, 
                         return Encarnado]
    
Main> sample (arbitrary :: Gen Semaforo)
Encarnado
Amarelo
Amarelo
Encarnado
Amarelo
Verde
Amarelo

---
    
O choose pode ser usado se tivermos tipos com valores de um intervalo:

> data Nota = N Int  -- as notas de uma cadeira variam entre 0 e 20
>   deriving (Show)

> instance Arbitrary Nota where
>   arbitrary = 
>       do n <- choose (0,20)
>          return $ N n

Podemos testar o gerador criado:

Main> sample (arbitrary :: Gen Nota)
N 2
N 15
N 13
N 19
N 7
N 12
N 4
N 20
N 17      (notem que não é assim que distribuímos as notas de PP!)

---

A função frequency permite-nos ter maior controle sobre como criar
distribuições de dados. 

Seja uma moeda viciada com apenas 25% de probabilidade de sair Caras:

> data BentCoin = Heads | Tails
>   deriving (Show)

> instance Arbitrary BentCoin where
>    arbitrary = frequency
>       [ (1, return Heads)
>       , (3, return Tails) ]

Main> sample (arbitrary :: Gen BentCoin)
Heads
Tails
Tails
Tails
Tails
Heads
Tails
  
--------------------------------------------------------------------

Vejamos como tornar Arbitrary um tipo recursivo:

> data Doc = Vazio | Frase String | Concat Doc Doc
>    deriving (Show)

O código seguinte escolhe entre 1, 2 e 3 aleatoriamente para escolher um dos 
construtores:

  instance Arbitrary Doc where
    arbitrary = 
        do n <- choose (1, 3) :: Gen Int
           case n of
              1 -> return Vazio
              2 -> do s <- arbitrary
                      return $ Frase s
              3 -> do d1 <- arbitrary :: Gen Doc
                      d2 <- arbitrary :: Gen Doc
                      return $ Concat d1 d1

Main> sample (arbitrary :: Gen Doc)
Frase ""
Concat (Frase "W") (Frase "W")
Vazio
Concat Vazio Vazio
Frase ";\168\224\144VIM\158\247"
...

Nestes casos é possível ser menos verboso usando as funções liftM
do módulo Control.Monad que automatizam a recolha dos valores 
arbitrários e a subsequente criação do valor do tipo:

> instance Arbitrary Doc where
>   arbitrary = oneof[ return Vazio,
>                      liftM  Frase arbitrary,
>                      liftM2 Concat arbitrary arbitrary ]

A escolha aleatória do oneof é uniforme. Assim o QuickCheck
selecciona o construtor Vazio, Frase e Concat com 1/3 de 
probabilidade para cada um.

---

Mas e se não quisermos uma distribuição uniforme?

> data Doc' = Vazio' | Frase' String | Concat' Doc' Doc'
>    deriving (Show)

Vamos torná-lo instância de Arbitrary dando 80% de probabilidade de ser
um valor Concat'. Para isso usamos a função frequency:

    instance Arbitrary Doc' where
    arbitrary = frequency[ (1, return Vazio'),
                           (1, liftM  Frase'  arbitrary),
                           (8, liftM2 Concat' arbitrary arbitrary) ]

Esta solução dá-nos a distribuição desejada mas tem um problema.
Se formos pedir um sample dela

    Main> sample (arbitrary :: Gen Doc')

há 50% de probabilidade de produzirmos um Doc' infinito!

Isto ocorre porque cada Concat' produz dois valores arbitrários, e 
a probabilidade do cada vez maior número de Concat's gerados
não terminar em Frase ou Vazio é muito elevada. 

Para evitar este tipo de problema, o QuickCheck inclui a função

    sized :: (Int -> Gen a) -> Gen a
    
que dá a possibilidade ao programador de controlar o crescimento das
estruturas de dados aleatórias.

> instance Arbitrary Doc' where
>   arbitrary = sized arbDoc'
>     where
>        arbDoc' 0 = oneof [return Vazio', liftM  Frase'  arbitrary]
>        arbDoc' n = frequency[ (1, return Vazio'),
>                               (1, liftM  Frase'  arbitrary),
>                               (8, liftM2 Concat' arcDoc2 arcDoc2) ]
>          where
>            arcDoc2 = arbDoc' (n `div` 2)

Ou seja, cada vez que o Concat' é escolhido, a dimensão inicial do sized 
diminui para metade e inevitavelmente será escolhida a base da recursão, 
ie, um Vazio' ou um Frase'.

Main> sample (arbitrary :: Gen Doc')
Frase' ""
Concat' (Frase' "") (Concat' Vazio' (Frase' ""))
Concat' (Concat' (Concat' (Frase' "w\131=v") (Frase' "\190=\ENQ\DEL")) Vazio') (Concat'  (Concat' (Frase' "\191\244") Vazio') (Concat' (Frase' "\148K") (Frase' "\208\210g")))
Concat' (Frase' "") (Concat' (Frase' "\190x") (Frase' "2\f\164"))
Vazio'

--------------------------------------------------------------------

Vejamos como criar listas aleatórias.

A seguinte função cria uma lista aleatória, porém infinita:

> genList' ::  (Arbitrary a) => Gen [a]
> genList' = liftM2 (:) arbitrary genList'
 
Se quisermos listas finitas:

> genList ::  (Arbitrary a) => Gen [a]
> genList = frequency [ (1, return [])
>                     , (7, liftM2 (:) arbitrary genList) ]

A dimensão média das listas produzidas por genList, neste caso, 
é de sete elementos (sendo p a dimensão média, calcula-se pela
seguinte equação: p = 0 * 1/8 + (1+p) * 7/8).

Main> sample (genList :: Gen [Int])
[0,0,0,0,0]
[0,-1,-1,-2,0,0,1,2,2,-1]
[4,1,0,0,1,0,2]
[-1,6]
[-7,2,1,7,8,-8,-7,5,-8,-6,-1,6,8,7]
[2,-2,-7,-4,-9,5,3,0,4,5,-8,-5,-3,-2,4,5,-9,8,-3,-2,-10]

Main> sample (genList :: Gen String)
"#\r"
"\194\&8r"
"N\179Op'\170\vd4G!CNhZ7<zpr\254"
"\239}\SYNi\148\DC2[\238wG\242\153_\244,O\176S"
"\f!;\138\&0\SUB5\ESC\SOD\NUL\ENQ\154\DC3\224"
"f"

Podemos confirmar empiricamente o tamanho médio das listas geradas:

> checkLengths :: Int -> IO ()
> checkLengths n =
>   do xss <- sample' (vectorOf n (genList :: Gen [Int]))
>      let ls  = map length $ concat xss
>      let avg = fromIntegral (sum ls) / DL.genericLength ls :: Double
>      printf "%0.3f\n" avg

Main> checkLengths 1000
7.054

--------------------------------------------------------------------

Para criar uma lista aleatória ordenada aplicamos o sort ao genList:

> genOrdList :: (Arbitrary a, Ord a) => Gen [a]
> genOrdList = genList >>= return . DL.sort

Main> sample (genOrdList :: Gen [Int])
[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
[-1,-1,2]
[2]
[-6,-2,1,2,4,5]
[-6,-1,1,1]
[]
[-12,-12,-12,-10,-10,-8,-8,-7,-5,-4,-2,0,0,3,3,7,7,11,11]

ou em alternativa:

> genOrdList' :: (Arbitrary a, Ord a) => Gen [a]
> genOrdList' = liftM DL.sort genList

Main> sample $ (genOrdList' :: Gen [Int])
[0,0,0,0,0,0,0,0,0]
[-2,-1,-1,-1,-1,-1,-1,0,1,1,2,2,2,4]
[-5,5,5,10]
[-15,-7,-2,9]
[]
[-20,-19,-16,-10,-7,-4,-3,-3,-3,0,3,3,8,10,11,12,14,16]

---

Com este operador podemos voltar a olhar para o eg do insert 
e redefinir a propriedade de inserção ordenada. 

A versão inicial era:

 prop_ordered :: Int -> [Int] -> Property
 prop_ordered x xs = ordered xs ==> ordered $ insert x xs

A propriedade seguinte recebe um x e repete o seguinte: cria uma 
lista ordenada xs e verifica se a inserção de x em xs devolve 
uma lista ordenada,
 
> prop_ordered'''' :: Int -> Property
> prop_ordered'''' x = forAll genOrdList $ 
>                          \xs -> ordered $ insert x xs
   
Main> quickCheck prop_ordered''''
+++ OK, passed 100 tests.

---

Como criar listas ordenadas é um requisito comum, o QuickCheck 
também possui uma função para as criar:

    orderedList :: (Ord a, Arbitrary a) => Gen [a] 
    
Main> sample (orderedList :: Gen [Int])
[]
[]
[-3,1,1]
[-11]
[-9,-2,2,4,4,9,12,15,15,15,17]
[-18,-9,-7,-5,-2,8,11,12,12,13,17,17,20]

A propriedade ficaria assim:

> prop_ordered''''' :: Int -> Property
> prop_ordered''''' x = forAll orderedList $ 
>                          \xs -> ordered $ insert x xs

Main> quickCheck prop_ordered'''''
+++ OK, passed 100 tests.

--------------------------------------------------------------------

O QuickCheck introduz alguns tipos que produzem valores comuns.

Outra implementação de um gerador de positivos usa o tipo Positive:

> positives' :: Gen Int  -- gerador de números positivos
> positives' =
>   do Positive x <- arbitrary   
>      return x

outro eg são listas ordenadas:

> ordList :: Gen [Int]
> ordList =
>   do Ordered xs <- arbitrary
>      return xs

Main> sample ordList
[]
[-4,-4,-2,1]
[-5,1,2,3,5]
[-8,0,2,7,9,9,10]
[-9,-8,-8,1,5]

Estes são dois exemplo de modificadores. Os modificadores no QuickCheck
permitem restringir os valores que podem ser gerados.

> prop_trivial :: (Positive Int) -> Bool  -- gera apenas valores positivos
> prop_trivial (Positive n) = n > 0

Por exemplo, para verificar se o operador (!!) funciona, precisamos, pelo
menos, de uma lista não vazia e de um índice não negativo:

> prop_index :: (NonEmptyList Integer) -> NonNegative Int -> Property
> prop_index (NonEmpty xs) (NonNegative n) = 
>     n < length xs ==> xs !! n == head (drop n xs)

(neste caso ainda estaríamos a desperdiçar os testes onde n > lengh xs)
  
O modificador Large permite produzir números maiores que o default:

> prop_test_large :: (Positive (Large Int)) -> (Positive (Large Int)) -> Property
> prop_test_large (Positive (Large n)) (Positive (Large m)) =
>     collect (n, m) $ even (2*n) -- não falhar, queremos apenas ver a coleção

Main> quickCheck prop_test_large
+++ OK, passed 100 tests:
 3% (1,1)
 2% (4,2)
 2% (2,1)
 1% (908066102,1282413906)
 1% (823459,299061)
 1% (776440,850201)
 1% (72336819,1754339001)
 
 Já o Small prozud números menores que o habitual:
 
> prop_test_small :: (Positive (Small Int)) -> (Positive (Small Int)) -> Property
> prop_test_small (Positive (Small n)) (Positive (Small m)) =
>     collect (n, m) $ even (2*n) -- não falhar, queremos apenas ver a coleção

Main> quickCheck prop_test_small
+++ OK, passed 100 tests:
 3% (1,1)
 2% (40,28)
 2% (3,2)
 1% (91,92)
 1% (9,38)
 1% (9,37)
 1% (84,64)
 1% (80,88)

 Existe também o modificador NonZero para números não nulos.

--------------------------------------------------------------------
--------------------------------------------------------------------

Se for preciso criar um gerador default com valores específicos
de um tipo primitivo, temos um problema, porque o tipo primitivo
já tem um arbitrary pré-definido.

Por exemplo, dá jeito definir que uma hora é composta por
três Int's, mas estes inteiros têm valores limitados, o que
nao está previsto no arbitrary do tipo Int.

Nestes casos deve-se usar o comando newtype para definir um
novo tipo igual ao tipo original. Depois é só instanciar este
newtype ao typeclass Arbitrary.

Vejamos o exemplo das horas:

> data Tempo = Tempo Hora Minuto Segundo

> instance Show Tempo where
>   show (Tempo (H h) (M m) (S s)) = hh ++ ":" ++ mm ++ ":" ++ ss
>     where
>        hh = if h < 10 then "0" ++ show h else show h
>        mm = if m < 10 then "0" ++ show m else show m
>        ss = if s < 10 then "0" ++ show s else show s

> newtype Hora    = H Int deriving (Show, Eq, Ord)
> newtype Minuto  = M Int deriving (Show, Eq, Ord)
> newtype Segundo = S Int deriving (Show, Eq, Ord)

Vamos tornar os newtype's arbitrários:

> instance Arbitrary Hora where
>   arbitrary = 
>     do h <- choose (0,23)
>        return (H h)

> gen0059 = choose(0,59)

> instance Arbitrary Minuto where
>   arbitrary = 
>     do m <- gen0059
>        return (M m)

> instance Arbitrary Segundo where
>   arbitrary = liftM S gen0059  -- também se pode usar o liftM

E agora podemos fazer o mesmo para o tipo Tempo:

> instance Arbitrary Tempo where
>   arbitrary = liftM3 Tempo arbitrary arbitrary arbitrary
   
Main> sample (arbitrary :: Gen Tempo)
22:07:57
15:24:35
04:42:47
17:55:58
13:50:51
19:00:33
02:18:36
08:08:05

--------------------------------------------------------------------

Outro exemplo. Queremos implementar uma função que verifique se
uma string de parênteses está bem formada. Por exemplo "(())()"
está correcta, mas "()())" não está.

Eis uma função que resolve o problema:

> checkPars :: String -> Bool
> checkPars xs = res && nOpens==0 
>   where
>     (res, nOpens) = foldl check (True,0) xs
>     
>     check :: (Bool, Int) -> Char -> (Bool, Int)
>     check (soFar, nOpens) '(' = (soFar, nOpens+1)
>     check (soFar, nOpens) ')' 
>       | nOpens > 0 = (soFar, nOpens-1)
>       | otherwise  = (False, 0)
>     check x _ = x -- se houver outros chars, não interessam
    
Agora gostaríamos de testar a sua correção. Seria bom conseguirmos 
criar geradores de expressões com parênteses, para validar a função.
Ora, uma forma de gerar strings de parênteses bem formadas
é usar a seguinte gramática (para os curiosos cf. context-free grammars)

    S -> (S)S | <string vazia>

Vamos seguir esta ideia para criar um gerador de strings deste formato 
(vamos excluir as strings vazias, mas depois testamos este caso à parte)

> goodPars :: Gen String
> goodPars = 
>   do b1 <- elements [True, False]
>      b2 <- elements [True, False]
>      pars1 <- goodPars
>      case (b1,b2) of
>        (True,True)   -> do pars2 <- goodPars
>                            return $ "(" ++ pars1 ++ ")" ++ pars2
>        (True,False)  -> return    $ "(" ++ pars1 ++ ")"
>        (False,True)  -> return    $         "()"        ++ pars1
>        (False,False) -> return "()"  -- evitamos strings vazias

Main> sample goodPars
"()"
"(())(((()))())"
"(()())"
"()"
"(((())())()())"
"()()()"
"((()))(())"

E como gerar strings mal formadas? Porque não gerar uma string bem 
formada, e simplesmente trocar um dos parênteses?

> badPars :: Gen String
> badPars = 
>   do goodEg <- goodPars
>      let size = length goodEg
>      index <- elements [0..(size-1)]
>      return $ replace goodEg index
>   where
>      replace :: String -> Int -> String
>      replace str i = take i str ++ [(swap.(!!i)) str] ++ drop (i+1) str
>      swap '(' = ')'
>      swap ')' = '('
       
Main> sample badPars
"((((()()(())()()))(())(((((())))()))"
"((()))(((())"
"(()("
"()(("
"))"
    
As propriedades que vamos testar, incluído uma para a string vazia
(que se assume bem formada):

> prop_empty = checkPars ""       
> prop_good  = forAll goodPars $ \pars ->       checkPars pars
> prop_bad   = forAll badPars  $ \pars -> not $ checkPars pars
      
> testCheckPars = 
>   do quickCheck prop_empty
>      quickCheck prop_good
>      quickCheck prop_bad

Main> testCheckPars
+++ OK, passed 1 tests.
+++ OK, passed 100 tests.
+++ OK, passed 100 tests.

--------------------------------------------------------------------
--------------------------------------------------------------------

O QuickCheck pode também gerar funções! Para tal é preciso que 
os valores funções sejam do typeclass Show (é preciso ativar a
extensão FlexibleInstances, cf o início deste tutorial para ver 
como fazer):

> instance Show (Int -> Char) where
>   show _ = "Function: (Int -> Char)"

> instance Show (Char -> Maybe Double) where
>   show _ = "Function: (Char -> Maybe Double)"
 
A seguinte propriedade testa que se fizermos dois maps sucessivos
com as funções f e g, é o mesmo que fazer o um map com a composição
de f e g:
 
> prop_MapMap :: (Int -> Char) -> (Char -> Maybe Double) -> [Int] -> Bool
> prop_MapMap f g xs = map g (map f xs) == map (g . f) xs

Main> quickCheck prop_MapMap
+++ OK, passed 100 tests.

Este tipo de mecanismo é útil para testarmos funções de ordem superior.

Vejamos outro exemplo. Gostaríamos de testar esta definição:

> filterMap :: (a -> Bool) -> (a -> a) -> [a] -> [a]
> filterMap p f = foldr (\x acc -> if p x then f x:acc else acc) []

Main> filterMap (>0) (*2) [-3..3]
[2,4,6]

Para testar esta propriedade precisamos gerar predicados e funções 
unárias aleatórias. Como temos de testar para um tipo concreto,
vamos escolher o Int:

> instance Show (Int -> Int) where
>   show _ = "Function: (Int -> Int)"

> instance Show (Int -> Bool) where
>   show _ = "Function: (Int -> Bool)"

Comparamos a função com a definição mais directa via map e filter:

> prop_filterMap :: (Int -> Bool) -> (Int -> Int) -> [Int] -> Bool
> prop_filterMap p f xs = filterMap p f xs == (map f . filter p) xs

Main> quickCheck prop_filterMap
+++ OK, passed 100 tests.

--------------------------------------------------------------------

refs:

"Teste de funções com QuickCheck" do prof. Vasco Vasconcelos (disponível no moodle)

"Testing and Tracing Lazy Functional Programs using QuickCheck and Hat" por
Koen Claessen et al.

http://www.seas.upenn.edu/~cis552/12fa/lectures/QuickCheck.html

https://www.dcc.fc.up.pt/~pbv/aulas/tapf/slides/quickcheck.html

https://www.fpcomplete.com/blog/2017/01/quickcheck

https://hackage.haskell.org/package/QuickCheck-2.9.2/docs/Test-QuickCheck.html

https://hackage.haskell.org/package/QuickCheck-2.9.1/docs/Test-QuickCheck.html#g:14

https://hackage.haskell.org/package/QuickCheck-2.9.2/docs/Test-QuickCheck-Modifiers.html
  
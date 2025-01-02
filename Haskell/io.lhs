> import Data.List
> import Text.Read           -- readMaybe
> import System.Environment  -- getArgs
> import Control.Monad

--------------------------------------------------------------------------

As funções Haskell não produzem acções com efeitos secundários, mas o input/output
provoca (no ecrã, em ficheiros...). A função é um conceito distinto da acção. 

Para harmonizar estes dois mundos e permitir input/output existe no Haskell 
um tipo especial que representa acções de input/output: IO T.

IO T corresponde a um programa de input/output que, quando termina, devolve 
um valor do tipo T (aqui 'programa' significa uma sequência de acções, à la Java)

Eg: a função f :: Int -> IO Char é uma função que recebe um inteiro e devolve 
um programa de input/output que, quando termina, devolve um valor do tipo Char

IO () é um programa de input/output que não devolve nada (similar a um método
Java que devolve void)

Algumas funções úteis neste contexto: 

-- a acção de ler uma tecla, ecoar no ecrã e devolver o respectivo char
getChar :: IO Char   

-- a acção de ler o input até ao ENTER, ecoar no ecrã e devolver a respectiva String
getLine :: IO String

Main> getLine
uma linha
"uma linha"

-- a acção de escrever o char no ecrã e devolver void, ie, ()
putChar  :: Char -> IO () 

-- a acção de escrever a string no ecrã e devolver void
putStr   :: String -> IO ()

Main> putStr "hello world"
hello world

Main> putStr "\BEL"    (ocorre um apito)

-- a acção de escrever a string no ecrã, mudar de linha e devolver void
putStrLn :: String -> IO ()

-- a acção de escrever 'a' no ecrã e devolver void
print :: Show a => a -> IO ()

> printQuad :: Int -> IO()
> printQuad n = print [i^2 | i <- [0..n]]

Main> printQuad 4
[0,1,4,9,16]

--------------------------------------------------------------------------

Para compor acções no Haskell usamos os seguintes comandos:

 * a função return: não produz qualquer acção de IO mas retorna um valor 

    return :: a -> IO a

 * o operador 'do' que junta acções de IO.

Exemplos:

A seguinte função lê dois chars e devolve-os num par:

> lerPar :: IO (Char,Char)
> lerPar =
>   do x <- getChar     -- guarda o input na etiqueta x
>      y <- getChar
>      return (x,y)

Main> lerPar
ab
('a','b')

Se quiser ler o par de chars com um espaço de intervalo:

> lerPar' :: IO (Char,Char)
> lerPar' =
>   do x <- getChar     
>      _ <- getChar     -- o espaço não interessa guardar
>      y <- getChar
>      return (x,y)

Main> lerPar'
a b
('a','b')

A seguinte acção lê um par e imprime de acordo com o formato dado:

> duploChar :: IO ()
> duploChar = 
>   do (x,y) <- lerPar
>      putStrLn $ show x ++ ":" ++ show y

Main> duploChar
rt
'r':'t'

A seguinte função executa sequencialmente uma lista de acções:

> seqn :: [IO a] -> IO ()
> seqn [] = return ()
> seqn (a:as) = 
>   do a
>      seqn as

Podemos redefinir o putStr como sendo a execução sequencial
de uma lista de acções putChar:

> putStr' xs = seqn [ putChar x | x <- xs ]  

--------------------------------------------------------------------------

O operador 'do' executa uma sequência de programas de input/output, e 
transporta os resultados obtidos no programa anterior para o programa 
seguinte. A ordem das acções agora interessa!

Como vimos, a sintaxe "x <- P"  representa uma definição local útil 
para designar o valor obtido e devolvido pelo programa P

Outro exemplo de definição da função putStr usando agora o 'do':

> putStr'' :: String -> IO ()
> putStr'' []     = return ()
> putStr'' (x:xs) = 
>   do putChar x 
>      putStr'' xs

Outro exemplo:

O programa reverte cada palavra da string dada, e repete o processo
até a string nula ser inserida:

> progRevs :: IO ()
> progRevs = 
>   do line <- getLine
>      if null line
>          then return ()
>          else do putStrLn $ reverseWords line
>                  progRevs
>   where
>       reverseWords :: String -> String
>       reverseWords = unwords . map reverse . words

Main> progRevs
John Sebastian Bach
nhoJ naitsabeS hcaB
Wolfgang Amadeus Mozart
gnagfloW suedamA trazoM
Ludwig van Beethoven
giwduL nav nevohteeB
             -- linha em branco para terminar
  
--------------------------------------------------------------------------

É possível usar let's na sequência de acções:

> lengthName :: IO ()
> lengthName = 
>   do putStr "What is your name? "
>      name <- getLine
>      let size = length name
>      putStrLn $ "Your name has " ++ show size ++ " letters"

Main> lengthName
What is your name? Joao
Your name has 4 letters

Reparem na diferença entre o <- e o let:

    * resultado <- accao Haskell
    * let valor = expressão Haskell    

--------------------------------------------------------------------------

Vamos criar o nosso próprio getInt:

> getInt :: IO Int
> getInt = 
>   do line <- getLine
>      return $ read line

Main> getInt
54
54

mas:

*Main> getInt
5a
*** Exception: Prelude.read: no parse

Neste 2º caso, a função 'read' não conseguiu converter a string dada num
número, produzindo uma excepção.

Para definir um getInt robusto usamos o readMaybe do módulo Text.Read

    readMaybe :: Read a => String -> Maybe a

> getInt' :: IO Int
> getInt' = 
>   do line <- getLine
>      let mint = readMaybe line :: Maybe Int
>      case mint of
>         Just n  -> return n
>         Nothing -> do putStr "número inválido, tente outra vez: "
>                       getInt'

Main> getInt'
5a
número inválido, tente outra vez: wef4aw
número inválido, tente outra vez: 12
12
    
--------------------------------------------------------------------------

De notar que o return não significa que o programa termina, ao contrário
das linguagens imperativas. O return apenas 'embrulha' um valor numa acção.

Estes programas fazem o mesmo:

> ret1 = 
>   do a <- return "hello "  -- o operador <- desfaz o trabalho do return
>      b <- return "world"
>      putStrLn $ a++b

> ret2 = 
>   do let a = "hello "
>      let b = "world"
>      putStrLn $ a++b

A importância do return é quando temos um valor a devolver após
uma sequência de acções (daí o seu nome)

> sumProg :: IO Int
> sumProg =
>   do putStr "what is the first number? "
>      x <- getLine
>      putStr "what is the second number? "
>      y <- getLine
>      let soma = read x + read y
>      return soma

Main> sumProg
what is the first number? 12
what is the second number? 32
44

--------------------------------------------------------------------------

A função 

    readIO :: Read a => String -> IO a
    
faz um papel similar a read, mas no contexto de IO.

> readListAndSum =
>   do str <- getLine
>      xs <- readIO str :: IO [Int]
>      putStrLn $ "Sum = " ++ show (sum xs)

Main> readListAndSum 
[4,3,5]
Sum = 12

Main> readListAndSum 
[5,]
*** Exception: user error (Prelude.readIO: no parse)

--------------------------------------------------------------------------

Outros operadores úteis (necessário importar o módulo Control.Monad)

 *** when/unless: permitem ter acções condicionadas a uma guarda
 
 unless :: Bool -> IO () -> IO ()   
 when   :: Bool -> IO () -> IO ()

 (as assinaturas são mais gerais, mas estão aqui adaptadas para IO)
 
> warningBigInts minBig =
>   do n <- getInt
>      when (n>=minBig) $
>          putStrLn("^^ Big Integer!")
>      unless (n==0) $                   -- zero terminates
>           warningBigInts minBig  

Main> warningBigInts 100
34
-142
145
^^ Big Integer!
12
0

 *** sequence: executa uma sequência de acções e devolve a lista dos
               seus resultados
               
  sequence :: [IO a] -> IO [a]                
  
Main> sequence $ map print [1..3]
1
2
3
[(),(),()]

O Haskell mostra os efeitos secundários da acção (imprimir o 1,2,3)
e também o resultado da expressão: uma lista de três programas IO ()

O Haskell só não mostra o resultado da expressão quando esta é IO ()

> getNLines :: Int -> IO [String]  
> getNLines n =
>   do myLines <- sequence $ replicate n getLine
>      return myLines   

que pode ser simplificado para:

> getNLines' :: Int -> IO [String]  
> getNLines' n = sequence $ replicate n getLine

Main> getNLines 3
Foo
Bar
Xpto
["Foo","Bar","Xpto"]

A ideia de replicar uma acção e depois fazer a sequência é tão comum
que existe a função replicateM para isso mesmo.

  replicateM :: Int -> IO a -> IO [a]

Assim, o programa anterior poderia ser também escrito como:

> getNLines'' :: Int -> IO [String]  
> getNLines'' n =
>   do myLines <- replicateM n getLine
>      return myLines   



 *** mapM/mapM_: mapeiam a lista com uma acção e executa a sequência, 
                 a versão mapM_ não mostra o resultado da expressão
                 
  mapM :: (a -> IO b) -> [a] -> IO [b]               
  
Main> mapM print [1..3]
1
2
3
[(),(),()]

Main> mapM_ print [1..3]
1
2
3


 *** forM/forM_: são como o mapM/mapM_ mas com os argumentos trocados
 
    forMM :: [a] -> (a -> IO b) -> IO [b]
 
Main> forM_ [1..3] print
1
2
3

Um exemplo mais elaborado:

> testeDiv3 ns = 
>   do respostas <- forM ns
>           (\n -> do putStrLn $ "O numero " ++ show n ++ " e' divisivel por 3? (s/n)"
>                     res <- getLine
>                     return $ res == if mod n 3 == 0 then "s" else "n")
>      putStrLn "------------ Resultados ------------"
>      mapM_ print $ map (\res -> if res then "acertou" else "falhou") respostas


Main> testeDiv3 [435, 5673, 1245]
O numero 435 e' divisivel por 3? (s/n)
s
O numero 5673 e' divisivel por 3? (s/n)
n
O numero 1245 e' divisivel por 3? (s/n)
n
------------ Resultados ------------
"acertou"
"falhou"
"falhou"

--------------------------------------------------------------------------

Existem dois operadores (>>) e (>>=) que também permitem combinar acções.

O operador (>>) (pronuncia-se 'then') tem assinatura:

  (>>)   :: IO a -> IO b -> IO b

operador p>>q  : 1) executar p, 
                 2) executar q (o resultado de p perdeu-se)
                 
Eg:
                 
> addNums n = 
>   do ns <- replicateM n $ putStr "Number? " >> getInt
>      return $ sum ns


Main> addNums 3
Number? 100
Number? 200
Number? 300
600

A acção 

    putStr "Number? " >> getInt :: IO Int
    
é o resultado de duas acções em sequência

    putStrLn "Number?" :: IO ()
    getInt :: IO Int
    
Duas soluções para definir putStr com o (>>)

> putStr''' (x:xs) = putChar x >> putStr'' xs

> putStr'''' = foldr (>>) (return ()) . map putChar
    
---   
    
O operador (>>=) (pronuncia-se 'bind') tem assinatura

  (>>=)  :: IO a -> (a -> IO b) -> IO b

operador p>>=q : 1) executar p, 
                 2) designar x ao resultado de p, 
                 3) executar q x
    
Exemplo:

Main> putStr "Introduza um char: " >> getChar >>= \c -> putStrLn $ "escolheu " ++ show c
Introduza um char: t
escolheu 't'    

Normalmente usam-se estas duas funções em situações pontuais. As maiores sequências
de acções devem ser tratadas com o operador 'do'
    
--------------------------------------------------------------------------
-------------------------- Uso de Ficheiros ------------------------------
    
Existem várias funções para lidar com ficheiros. Aqui vamos apenas
nos preocupar em ler ficheiros de texto.

As funções mais comuns são:

  *** writeFile :: FilePath -> String -> IO ()
  
Escreve um ficheiro com o conteúdo da string dada (a versão anterior,
se existia, é apagada)

Main> writeFile "linhas.txt" "abc\ndef"
    (escreve um ficheiro na pasta local com duas linhas de texto)
  
  *** readFile :: FilePath -> IO String
  
Lê o conteúdo do ficheiro 

Main> readFile "linhas.txt"
"abc\ndef"


  *** appendFile :: FilePath -> String -> IO ()
  
Como o writeFile mas adiciona ao fim do ficheiro, se este já existir.

Main> appendFile "linhas.txt" "ghi"
Main> readFile "linhas.txt"
"abc\ndefghi"


  *** lines :: String -> [String]
  *** unlines :: [String] -> String

A função lines faz o split de uma string por mudanças de linha (\n) enquanto
o unlines faz o oposto.

Main> lines "abc\ndefghi"
["abc","defghi"]

Main> unlines ["abc","defghi"]
"abc\ndefghi\n"

Estas funções são úteis para converter as strings lidas em listas (lines), 
e para reconverter as listas de resultados em strings para serem escritas 
nos ficheiros (unlines).

--------------------------------------------------------------------------

Um exemplo:

O seguinte código salva um ficheiro com os números de 1 a n, um por cada linha

> saveFile :: Int -> IO()
> saveFile n = 
>   do 
>     writeFile "nums.txt" (text [1..n])
>   where
>     text = concat . map ((++"\n").show)

--------------------------------------------------------------------------

A função getArgs do módulo System.Environment permite recolher
os argumentos passados pela linha de comando.

Neste eg o ficheiro nums.txt tem um número inteiro em cada linha.
Se executarmos na linha de comandos

   runhaskell io.lhs "nums.txt" "evens.txt" "odds.txt"
   
o programa cria dois novos ficheiros, um com os números pares, e o 
outro com os ímpares. Os nomes dos ficheiros são dados na invocação
do programa.
  
> main =                  -- o programa IO a executar tem de chamar-se 'main'
>   do args <- getArgs 
>      let fileIn    = args!!0
>          fileEvens = args!!1
>          fileOdds  = args!!2
>      nums <- readFile fileIn
>      let (evens, odds) = partition (even.read) $ lines nums
>      writeFile fileEvens $ unlines evens
>      writeFile fileOdds  $ unlines odds

--------------------------------------------------------------------------

As seguintes funções são úteis para processar ficheiros recebidos pelo
standard input, por exemplo via pipes. Não são úteis na linha 
de comandos do Haskell.

    *** getContents :: IO String
    
Lê do standard input e transforma numa string

Exemplo:

1) Escrevam no ficheiro io_t1.hs o seguinte código:

    import Data.Char

    main = 
      do contents <- getContents
         putStr (map toUpper contents)
     
2) No terminal escrevam:

    bash$ ghc --make io_t1.hs
    bash$ cat linhas.txt
    abc
    defghi
    bash$ cat linhas.txt | ./io_t1        (no windows: cat linhas.txt | io_t1.exe)
    ABC
    DEFGHI

Outra possibilidade é no terminal escrever

    bash$ cat linhas.txt | runhaskell io_t1.hs
    ABC
    DEFGHI
    
De notar que as operações com ficheiros também são lazy, o Haskell não carrega
um ficheiro por inteiro, vai ler linha a linha consoante o que está a ser pedido.
    
    
    *** interact :: (String -> String) -> IO ()
    
A função interact automatiza o getContents, processando cada linha com a função dada

O exemplo anterior poderia ser escrito assim:

    import Data.Char

    main = interact $ map toUpper
    
O exemplo seguinte filtra todas as linhas de um ficheiro que tenham mais que 10 chars:

    main = interact $ unlines . filter ((<10) . length) . lines
    
--------------------------------------------------------------------------

IO pode ser definido como instância de Functor:

  instance Functor IO where  
      fmap f action = 
        do result <- action  
           return (f result) 
        
Eg:

> functor_eg = 
>   do line <- fmap reverse getLine
>      putStrLn line

Main> functor_eg
abcd
dcba

--------------------------------------------------------------------------

IO também pode ser definido como instância de Applicative:

    instance Applicative IO where  
        pure = return  
        a <*> b = 
          do f <- a  
             x <- b  
             return (f x) 
        
O programa

    myAction :: IO String  
    myAction = 
      do a <- getLine  
         b <- getLine  
         return $ a ++ b  

Pode ser escrito:

    myAction :: IO String  
    myAction = (++) <$> getLine <*> getLine
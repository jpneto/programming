O Jogo do NIM
=============
Dadas n pilhas de pedras, cada jogador no seu turno pode tirar 
um qualquer número de pedras apenas de uma pilha. Ganha quem
for o último a jogar.

mais info: https://en.wikipedia.org/wiki/Nim

A função 'nim' recebe um inteiro e cria uma posição inicial do jogo
desta forma:

    Main> nim 5
    1: *
    2: **
    3: ***
    4: ****
    5: *****

A partir daqui, cada jogador escolhe a pilha e quantas pedras
quer tirar. Por exemplo:

    Main> nim 5
    1: *
    2: **
    3: ***
    4: ****
    5: *****
    Jogador 1
    Que linha? 3
    Qts *s? 2
    1: *
    2: **
    3: *
    4: ****
    5: *****
    Jogador 2
    Que linha?

-------------------------------

Vejamos o código.

> import Text.Read (readMaybe)

O estado do jogo é uma lista de inteiros que contém as pedras 
ainda em jogo de cada pilha. O fim do jogo ocorre quando já
não há pedras.

> isEoG state = sum state == 0

Uma jogada passa por remover n pedras da respectiva pilha 

> move :: Int -> Int -> [Int] -> [Int]
> move n i state = take (i-1) state   ++ 
>                  [(\x->if x<0 then 0 else x)(state!!(i-1) - n)] ++ 
>                  drop i state

Mostrar o tabuleiro

> printBoard :: Int -> [Int] -> IO ()
> printBoard _ []     = return ()
> printBoard n (x:xs) = do putStr ((show n) ++ ": " ++ (replicate x '*') ++ "\n")
>                          printBoard (n+1) xs

Ler um inteiro (versão robusta)

> getInt :: IO Int
> getInt = 
>   do line <- getLine
>      let mint = readMaybe line :: Maybe Int
>      case mint of
>         Just n  -> return n
>         Nothing -> do putStr "número inválido, tente outra vez: "
>                       getInt

Ir buscar uma jogada válida

> getMove :: [Int] -> IO (Int,Int)
> getMove xs = do putStr "Que linha? "
>                 i <- getInt
>                 if (i<1 || i>length xs || xs!!(i-1)==0) 
>                   then getMove xs
>                   else do putStr "Qts *s? "
>                           p <- getInt
>                           if p<=0 then getMove xs
>                                   else return (i,p)

Um turno do jogo

> play :: [Int] -> Int -> IO String
> play board player
>   | isEoG board && player == 0 = return "Segundo"
>   | isEoG board && player == 1 = return "Primeiro"
>   | otherwise = do printBoard 1 board
>                    putStr ("Jogador " ++ (show (player+1)) ++ "\n")
>                    (i,n) <- getMove board
>                    play (move n i board) (1-player)  -- next turn

O jogo

> nim :: Int -> IO ()
> nim n = do winner <- play [1..n] 0
>            putStrLn (winner ++ " jogador ganhou!")


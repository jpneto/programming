> import Debug.Trace 
> import Debug.Hood.Observe -- instalar no terminal: cabal install hood

A função trace é usada no contexto de debugging. A sua assinatura é 

    trace :: String -> a -> a
    
e o seu comportamento é de imprimir o primeiro argumento antes de devolver
o segundo. De notar também que dada a avaliação lazy, a string só é impressa 
quando o valor é calculado.

----------------------------------------------------------

Vejamos alguns egs:

> teste01 n = trace ("  recebi " ++ show n) $ n*2

Main> teste01 10
  recebi 10
20

> teste02 n = if even n then trace "  ramo par"   1 
>                       else trace "  ramo impar" 0

Main> teste02 2
  ramo par
1

Main> teste02 3
  ramo impar
0

> teste_fib :: Int -> Int
> teste_fib 0 = trace "  base 0" 0
> teste_fib 1 = trace "  base 1" 1
> teste_fib n = trace ("  calcular fib(" ++ show n ++ ")") $ 
>               teste_fib (n - 1) + teste_fib (n - 2)

Main> teste_fib 5
  calcular fib(5)
  calcular fib(4)
  calcular fib(3)
  calcular fib(2)
  base 1
  base 0
  base 1
  calcular fib(2)
  base 1
  base 0
  calcular fib(3)
  calcular fib(2)
  base 1
  base 0
  base 1
5

----------------------------------------------------------

Claro que isto não é muito prático quando terminarmos o debugging, dado 
que é preciso retirar as chamadas do trace. Uma opção passa por remover
o import e incluir a seguinte definição:

  trace _ = id

Desta forma, o trace deixa de produzir qualquer efeito, e provavelmente
o compilador até optimiza o código resultante.

Main> teste_fib 5    -- com a definição inerte do trace
5

Outra forma:
   
> myfun a b | trace ("myfun " ++ show a ++ " " ++ show b) False = undefined
> myfun a b = a+b

Ou seja, o trace imprime a string e retorna falso, o que significa 
que a 1a equação guardada não é avaliada. Logo o Haskell executa a segunda
equação que produz o valor desejado. Este formato permite o comentário
fácil da 1a equação quando a fase de debug terminar.

ref: https://wiki.haskell.org/Debugging

----------------------------------------------------------

Provavelmente já repararam que o trace imprime resultados sem ter 
na assinatura um tipo IO. Isto é, a função trace é uma função Haskell 
com efeitos secundários! 

Esta função quebra a transparência referencial - ie, funções com o 
mesmo input devem produzir o mesmo output - e deve ser usada com 
cuidado e *apenas* no contexto de debug.

Um exemplo de quebra de transparência referencial: 

    f x = trace ("testar" ++ show (f x)) $ x^2
    
A função f com o trace desligado devolve o quadrado de x, mas com
o trace ligado entra em ciclo infinito.   

----------------------------------------------------------

Outros exemplos:

> trace_notice x = trace ("  processing " ++ show x) $ x

Main> map ((*2) . trace_notice ) [2,5,8]
[4,10,16]
  processing 2
  processing 5
  processing 8

Main> foldr (\x acc -> trace_notice x + acc) 0 [1,2,3,4]
  processing 4
  processing 3
  processing 2
  processing 1
10

Main> foldl (\acc x -> trace_notice x + acc) 0 [1,2,3,4]
  processing 1
  processing 2
  processing 3
  processing 4
10

----------------------------------------------------------

Algumas funções úteis disponíveis no módulo Debug.Trace:

 traceShowId :: (Show a) => a -> a
 traceShowId x = trace (show x) x

map (traceShowId . (*2)) [1,2,3]
[2,4,6]
2
4
6

 traceShow :: (Show a) => a -> b -> b
 traceShow = trace . show

> teste03 x y =
>     traceShow (w,z) $ result
>   where
>     w = x*y
>     z = x+y
>     result = w+z
 
Main> teste03 4 5
(20,9)
29 
 
Podemos fazer flip dos argumentos se preferirmos por o teste 
no fim da definição da função a testar:
 
> debug = flip trace

> teste04 n = n*2  `debug` ("  duplicar " ++ show n)

Main> teste04 10
  duplicar 10
20

ref: https://en.wikibooks.org/wiki/Haskell/Debugging

----------------------------------------------------------

Podemos igualmente incluir traces nos programas IO com a função traceIO:

> teste05 = 
>   do putStr "? "
>      xs <- getLine
>      let i = 4
>      traceIO $ "  valor do indice e' " ++ show i
>      return $ xs!!i

Main> teste05
? abcdef
  valor do indice e' 4
'e'

ref: hackage.haskell.org/package/base-4.9.0.0/docs/Debug-Trace.html

----------------------------------------------------------
----------------------------------------------------------

O pacote Debug.Hood.Observe dá-nos outra ferramenta de debug 
através da função 'observe':

> f' :: Int -> Int
> f' = observe "Observar a funcao f:" f 

> f :: Int -> Int
> f x = if odd x then x*2 else 0

Para mostrar as mensagens usamos a função printO :: Show a => a -> IO ()

Main> printO $ map f' [1..4]
[2,0,6,0]

-- Observar a funcao f:
  { \ 1  -> 2
  , \ 2  -> 0
  , \ 3  -> 6
  , \ 4  -> 0
  }
  
As funções são observadas na forma como são usadas. No seguinte
exemplo, o length não precisa avaliar os elementos da lista, e
isso nota-se no tipo de informação devolvido pelo observe:

Main> printO $ (observe "length") length [1..5]
5

-- length
  { \ ( _ :  _ :  _ :  _ :  _ : [] )  -> 5
  }

  
Ou seja, se um argumento não é avaliado, o Hood marca-o com um underscore:

Main> printO $ observe "x,y" (\x y -> 2*x) 4 5
8

-- x,y
  { \ 4 _  -> 8
  }


Main> let xs = observe "list" [0..9] in printO (xs!!2 + xs!!4)
6

-- list
   _ :  _ :  _ :  _ :  4 : _
-- list
   _ :  _ :  2 : _


No seguinte exemplo observamos o comportamento do foldl:

Main> printO $ observe "foldl (+) 0 [1..4]" foldl (+) 0 [1..4]
10

-- foldl (+) 0 [1..4]
  { \ { \ 0 1  -> 1
      , \ 1 2  -> 3
      , \ 3 3  -> 6
      , \ 6 4  -> 10
      } 0 ( 1 :  2 :  3 :  4 : [] )  -> 10
  }

Podemos usar o observe em listas por compreensão:  
  
Main> printO [ observe "+1" (+1) x | x <- observe "xs" [1..3]]
[2,3,4]

-- +1
  { \ 1  -> 2
  }
-- +1
  { \ 2  -> 3
  }
-- +1
  { \ 3  -> 4
  }
-- xs
   1 :  2 :  3 : []
   
----------------------------------------------------------

Um exemplo com o quicksort:  

> qsort :: [Int] -> [Int]
> qsort xs = observe "qsort" qsort' xs
> 
> qsort' []     = []
> qsort' (x:xs) = qsort elts_lt_x ++ [x] ++ qsort elts_greq_x
>                  where
>                    elts_lt_x   = [y | y <- xs, y < x]
>                    elts_greq_x = [y | y <- xs, y >= x]
 
Main> printO $ qsort [3,5,2,4]
[2,3,4,5]

-- qsort
  { \ ( 3 :  5 :  2 :  4 : [] )  ->  2 :  3 :  4 :  5 : []
  }
-- qsort
  { \ ( 2 : [] )  ->  2 : []
  }
-- qsort
  { \ []  -> []
  }
-- qsort
  { \ []  -> []
  }
-- qsort
  { \ ( 5 :  4 : [] )  ->  4 :  5 : []
  }
-- qsort
  { \ ( 4 : [] )  ->  4 : []
  }
-- qsort
  { \ []  -> []
  }
-- qsort
  { \ []  -> []
  }
-- qsort
  { \ []  -> []
  }
  
----------------------------------------------------------
  
Outro eg: esta função converte um número numa lista de dígitos,

  natural :: Int -> [Int]
  natural = reverse
            . map (`mod` 10)
            . takeWhile (/= 0)
            . iterate (`div` 10)

Se quisermos observar o que está a ser calculado internamente:

> natural :: Int -> [Int]
> natural = reverse
>           . observe "after map: "
>           . map (`mod` 10)
>           . observe "after takeWhile: "
>           . takeWhile (/= 0)
>           . observe "after iterate: "
>           . iterate (`div` 10)

Main> printO $ natural 5804
[5,8,0,4]

-- after iterate: 
   5804 :  580 :  58 :  5 :  0 : _
-- after map: 
   4 :  0 :  8 :  5 : []
-- after takeWhile: 
   5804 :  580 :  58 :  5 : []
   
Em vez de analisarmos as listas produzidas, podemos também 
visualizar as transformações que estão a ocorrer em cada função:
   
> natural2 :: Int -> [Int]
> natural2 = reverse
>           . observe "after map: "        map (`mod` 10)
>           . observe "after takeWhile: "  takeWhile (/= 0)
>           . observe "after iterate: "    iterate (`div` 10)

printO $ natural2 5804
[5,8,0,4]

-- after iterate: 
  { \ { \ 5  -> 0
     , \ 58  -> 5
     , \ 580  -> 58
     , \ 5804  -> 580
     } 5804  ->  5804 :  580 :  58 :  5 :  0 : _
  }
-- after map: 
  { \ { \ 5  -> 5
     , \ 58  -> 8
     , \ 580  -> 0
     , \ 5804  -> 4
     } ( 5804 :  580 :  58 :  5 : [] )  ->  4 :  0 :  8 :  5 : []
  }
-- after takeWhile: 
  { \ { \ 0  -> False
     , \ 5  -> True
     , \ 58  -> True
     , \ 580  -> True
     , \ 5804  -> True
     } ( 5804 :  580 :  58 :  5 :  0 : _ )  ->  5804 :  580 :  58 :  5 : []
  }
   
----------------------------------------------------------

A função runIO permite fazer debug de codigo IO com debug:

> teste06 :: [Int] -> IO ()   
> teste06 = print . reverse . (observe "intermediate") . reverse 
   
Main> runO $ teste06 [1,2,3,4]
[1,2,3,4]

-- intermediate
   4 :  3 :  2 :  1 : []
   
De facto, a função printO é apenas a aplicação sequencial de runO e print.
   
----------------------------------------------------------

O uso do trace/observe deve ser temperado com um estilo de 
programação que reduza a necessidade de fazer debug desta forma.

Cada função deve ser pequena, clara e reusável, de forma a que
a sua correcção seja o mais óbvia possível. Funções mais complexas 
devem ser formadas pela composição de funções simples 

A validação das funções deve ser maioritariamente efectuada através
de testes QuickCheck.

Uma nota final: existe um projeto mais moderno designado Hoed que
pode ser seguido aqui: https://github.com/MaartenFaddegon/Hoed

----------------------------------------------------------

refs: 
  http://hackage.haskell.org/package/hood-0.3/docs/Debug-Hood-Observe.html
  http://ku-fpg.github.io/papers/Gill-00-HOOD/
  http://ku-fpg.github.io/software/hood/
  
> import Control.Monad
> import Control.Monad.State

> import qualified Data.Map as M       -- hash table
> import Data.List
> import Data.Bits                     -- bitwise operations

> import Language.Haskell.Interpreter  -- to install: cabal install hint

> import Parsing                       -- cf. Hutton, Programming in Haskell, chp.8

-------------------------------------------------------------------------------

Uma domain-specific language (DSL) � uma linguagem que foi constru�da para um dom�nio muito espec�fico, na qual podemos expressar problemas relevantes num determinado contexto. Ao contr�rio de uma linguagem gen�rica, como o Java ou o Haskell, uma DSL tem uma expressividade limitada. Como exemplos de DSL's temos o HTML, o SQL, os shell scripts do Unix/Linux, as express�es regulares, Lex/YACC para parsing, o OpenGL para gr�ficos vectoriais, Markdown para documenta��o, as linguagens estat�sticas BUGS e Stan, o Csound para sons e m�sica, etc.

Este documento pretende mostrar algumas formas de usar DSL's na programa��o Haskell.

Iremos usar uma pequena DSL para representar circuitos l�gicos (sem ciclos), a linguagem WIRES, que permite manipular valores inteiros de 16 bits (cf. http://beautifulracket.com/wires/), tendo os seguintes operadores bit a bit:

+ Atribui��o de valores a 'wires', eg: 123 -> x

+ Nega��o, eg: NOT x -> y

+ Uso de portas 'and' e 'or', eg: x AND y -> z

+ Uso de left/rigit shifts, eg: x LSHIFT 2 -> y

Eis um exemplo de um programa WIRES:

    123 -> x         
    456 -> y        
    NOT x -> h      
    NOT y -> i      
    x LSHIFT 2 -> f 
    y RSHIFT 2 -> g 
    x OR y -> e     
    x AND y -> d

Fa�amos um pequeno programa IO para guardar este programa WIRES como exemplo a utilizar adiante:

> makeEg = writeFile "wires_eg.txt" wiresEg
>   where
>     wiresEg = "123 -> x         \n\
>                \456 -> y        \n\
>                \NOT x -> h      \n\
>                \NOT y -> i      \n\
>                \x LSHIFT 2 -> f \n\
>                \y RSHIFT 2 -> g \n\
>                \x OR y -> e     \n\
>                \x AND y -> d"

Quando executado, estes seriam os sinais em cada 'wire':

    d: 72
    e: 507
    f: 492
    g: 114
    h: 65412
    i: 65079
    x: 123
    y: 456

Como implementar esta DSL em Haskell?

Vamos abordar tr�s solu��es:

+ usando um parser para criar uma estrutura de dados que usamos para calcular a solu��o,

+ criando e avaliando dinamicamente express�es Haskell

+ definindo a DSL na pr�pria linguagem Haskell

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Solu��o 1: usando um parser

Um parser � um programa que analisa uma string com uma express�o que segue uma dada gram�tica e traduz essa express�o para uma estrutura adequada. 

Por exemplo, um parser para express�es WIRE com o operador NOT tem de analisar frases com a seguinte gram�tica:

    not ::= 'NOT' identifier '->' identifier
    
onde 'identifier' � uma palavra, e onde os tokens 'NOT' e '->' tem de estar na posi��o correcta. Exemplos de strings que seguem este formato s�o 

    NOT abc -> aaa
    NOT x -> y

e contra-exemplos:

    abs NOT -> aaa
    aaa <- NOT abs

Se lerem o m�dulo Parsing.lhs ver�o que j� existem v�rios parsers para tarefas comuns, como analisar uma palavra ou um inteiro. Vejam o cap�tulo 8 do livro do Hutton, Programming in Haskell, para mais informa��o e para aprenderem a construir os vossos parsers.

Neste caso, um exemplo de parser para respeitar a gram�tica acima seria:
    
> _not1 :: Parser (String, [String]) 
> _not1 = do symbol "NOT"    -- "NOT x -> z"
>            x <- identifier
>            symbol "->"
>            var <- identifier
>            return (var, [x])
> 

Egs de uso:

Main> parse _not1 "NOT x -> aa"   -- sucesso
[(("aa",["x"]),"")]                 -- o "" significa que nada ficou por processar
Main> parse _not1 "aa <- NOT x"   -- insucesso
[]

---

Antes de fazermos o nosso parser vamos definir alguns tipos para lidar com esta DSL

> type Node = (Variable, Operator, [Variable], Data)
> type Variable  = String
> type Data      = Int
> data Operator  = CONST | AND | OR | NOT | RSHIFT | LSHIFT
>   deriving (Eq, Show)

As vari�veis s�o strings, e os valores s�o inteiros. Definimos um enumerado para representar as diferentes opera��es da DSL. Um Node corresponde � informa��o de um comando WIRE. Por exemplo, os comandos

    x AND y -> z
    x LSHIFT 2 -> v
    123 -> w

ser�o representados pelos seguintes valores Node:

    ("z", AND, ["x","y"], unkown)   <- aqui n�o usamos o Data
    ("v", LSHIFT, ["x"], 2)
    ("w", CONST, unkown, 123)       <- aqui n�o usamos a lista de vars

O objetivo � criar um parser 

    command :: Parse Node
    
que dado um comando, devolva o Node respectivo. Por exemplo:

Main> fst $ head $ parse command "x LSHIFT 2 -> v"
("v",LSHIFT,["x"],2)

Primeiro definimos a gram�tica (aqui, em formato EBNF):

     command ::= const | not | and | or | lshift | rshift
	 
	 const  ::=                        int     '->' identifier
	 not    ::=            'NOT'    identifier '->' identifier
	 and    ::= identifier 'AND'    identifier '->' identifier
	 or     ::= identifier 'OR'     identifier '->' identifier
	 lshift ::= identifier 'LSHIFT' identifier '->' identifier
	 rshift ::= identifier 'RSHIFT' identifier '->' identifier

Este � o parser que a realiza:     
     
> _assign  = "->"
> 
> command :: Parser Node       -- to test: parse command "x AND y -> z"
> command = do g <- _const
>              return g
>           +++                -- o operador +++ significa 'opcionalmente'
>           do g <- _not
>              return g
>           +++
>           do g <- _and
>              return g
>           +++
>           do g <- _or
>              return g
>           +++
>           do g <- _lshift
>              return g
>           +++
>           do g <- _rshift
>              return g
> 
> _const :: Parser Node                      -- "123 -> x"
> _const = do n <- int
>             symbol _assign
>             var <- identifier
>             return (var, CONST, undefined, n)
> 
> _not = do symbol "NOT"                     -- "NOT x -> z"
>           x <- identifier
>           symbol _assign
>           var <- identifier
>           return (var, NOT, [x], undefined)
> 
> _and = do x <- identifier                  -- "x AND y -> z"
>           symbol "AND"
>           y <- identifier
>           symbol _assign
>           var <- identifier
>           return (var, AND, [x,y], undefined)
> 
> _or  = do x <- identifier                  -- "x OR y -> z"
>           symbol "OR"
>           y <- identifier
>           symbol _assign
>           var <- identifier
>           return (var, OR, [x,y], undefined)
> 
> _lshift = do x <- identifier               -- "x LSHIFT 2 -> z"
>              symbol "LSHIFT"
>              y <- int
>              symbol _assign
>              var <- identifier
>              return (var, LSHIFT, [x], y)
> 
> _rshift = do x <- identifier               -- "x RSHIFT 2 -> z"
>              symbol "RSHIFT"
>              y <- int
>              symbol _assign
>              var <- identifier
>              return (var, RSHIFT, [x], y)    

-------------------------------------------------------------------------------

A seguinte fun��o auxiliar faz-nos a correspond�ncia das opera��es WIRES com fun��es Haskell do m�dulo Data.Bits:

> getOp :: Operator -> (Int -> Int -> Int)
> getOp AND    = (.&.)
> getOp OR     = (.|.)
> getOp LSHIFT = shift
> getOp RSHIFT = \x n -> shift x (-n)

E esta transforma os valores negativos em valores unsigned:

> int2unint n = if n>=0 then n else 65536+n

-------------------------------------------------------------------------------

O uso do parser em todas os comandos WIRES vai resultar numa lista de Node. Esta lista corresponde a uma s�rie de opera��es que v�o criar os valores para cada vari�vel. a pr�xima fun��o efectua estes c�lculos, usando um hash map para ir guardando os valores j� encontrados. No fim, devolve um hash map com os valores todos.

De notar que esta fun��o espera que os comandos WIRES estejam numa ordem adequada, ie, que se se usa uma vari�vel x para calcular a vari�vel y, o x j� ter� sido calculado. Ou seja, a ordem dos comandos WIRES � importante!

> solve :: [Node] -> M.Map Variable Data -> M.Map Variable Data
> solve [] mp = mp
> 
> solve ((var, CONST, _, val) : ops) mp = solve ops (M.insert var val mp)
> 
> solve ((var, NOT, [x], _)   : ops) mp = solve ops (M.insert var val mp)
>   where
>     xVal = M.findWithDefault 9999 x mp -- assumes that always find the value
>     val = int2unint $ complement xVal
> 
> solve ((var, op, [x], y) : ops) mp = solve ops (M.insert var val mp)
>   where
>     xVal = M.findWithDefault 9999 x mp 
>     val = (getOp op) xVal y
>     
> solve ((var, op, [x,y], _) : ops) mp = solve ops (M.insert var val mp)
>   where
>     xVal = M.findWithDefault 9999 x mp 
>     yVal = M.findWithDefault 9999 y mp
>     val = (getOp op) xVal yVal

J� temos tudo o que precisamos. Vamos criar uma programa para calcular os valores do exemplo inicial:

> mainParser = 
>    do makeEg
>       str <- readFile $ "wires_eg.txt"
>       let xss = lines str
>       let problem = map (fst . head . parse command) xss  -- parse file & get [Node]
>       -- mapM_ (putStrLn.show) problem
>       let state = solve problem M.empty                   -- solve it
>       putStrLn $ show state                               -- show results from hash

Main> mainParser
fromList [("d",72),("e",507),("f",492),("g",114),("h",65412),("i",65079),("x",123),("y",456)]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Solu��o 2: avalia��o din�mica de c�digo Haskell

O Haskell n�o possui um eval de ra�z, ie, uma fun��o que leia uma string contendo c�digo Haskell e que o execute. Isto deve-se muito ao facto do Haskell ser uma linguagem pura, sem efeitos secund�rios.

No entanto existe (pelo menos) uma biblioteca que nos permite criar um ambiente onde podemos avaliar strings com comandos Haskell num ambiente controlado ao qual podemos ir buscar resultados. Vejamos um exemplo com a biblioteca 'hint' (para instalar, executar na linha de comandos, cabal install hint).

A t�cnica usada � a seguinte: vamos fazer outro parsing do ficheiro com os comandos WIRES. Este parsing, em vez de criar listas de Nodes, vai criar um conjunto de fun��es Haskell que calculam os valores das vari�veis desejadas! 

Neste exemplo, o parser se receber o programa

    123 -> x         
    456 -> y        
    NOT x -> h      
    NOT y -> i      
    x LSHIFT 2 -> f 
    y RSHIFT 2 -> g 
    x OR y -> e     
    x AND y -> d
    
vai produzir automaticamente

    x :: Int
    x = 123

    y :: Int
    y = 456

    h :: Int
    h = int2unint $ complement x

    i :: Int
    i = int2unint $ complement y

    d :: Int
    d = x .&. y

    e :: Int
    e = x .|. y

    f :: Int
    f = x `shift` 2

    g :: Int
    g = y `shift` (-2)
    
Depois � s� anexar isto num m�dulo Haskell para ser avaliado pela biblioteca 'hint'.

-------------------------------------------------------------------------------

Desta vez ser� produzindo um par pelo parser. A primeira componente � a fun��o Haskell que queremos salvar no m�dulo. A segunda componente � o nome da vari�vel definida. Isto vai dar-nos jeito adiante. Ei-lo:

> command2 :: Parser (String,Variable)    -- to test: parse command "x AND y -> z"
> command2 = do g <- _const2
>               return g
>            +++
>            do g <- _not2
>               return g
>            +++
>            do g <- _and2
>               return g
>            +++
>            do g <- _or2
>               return g
>            +++
>            do g <- _lshift2
>               return g
>            +++
>            do g <- _rshift2
>               return g
> 
> _const2 :: Parser (String,Variable)         -- "123 -> x"
> _const2 = do n <- int
>              symbol _assign
>              var <- identifier
>              return $ (var ++ " :: Int\n" ++ 
>                        var ++ " = " ++ show n ++ "\n", var)
> 
> _not2 = do symbol "NOT"                     -- "NOT x -> z"
>            x <- identifier
>            symbol _assign
>            var <- identifier
>            return $ (var ++ " :: Int\n" ++ 
>                      var ++ " = int2unint $ complement " ++ x ++ "\n", var)
> 
> _and2 = do x <- identifier                  -- "x AND y -> z"
>            symbol "AND"
>            y <- identifier
>            symbol _assign
>            var <- identifier
>            return $ (var ++ " :: Int\n" ++ 
>                      var ++ " = " ++ x ++ " .&. " ++ y ++ "\n", var)
> 
> _or2  = do x <- identifier                  -- "x OR y -> z"
>            symbol "OR"
>            y <- identifier
>            symbol _assign
>            var <- identifier
>            return $ (var ++ " :: Int\n" ++ 
>                      var ++ " = " ++ x ++ " .|. " ++ y ++ "\n", var)
> 
> _lshift2 = do x <- identifier               -- "x LSHIFT 2 -> z"
>               symbol "LSHIFT"
>               n <- int
>               symbol _assign
>               var <- identifier
>               return $ (var ++ " :: Int\n" ++ 
>                         var ++ " = " ++ x ++ " `shift` " ++ show n ++ "\n", var)
> 
> _rshift2 = do x <- identifier               -- "x RSHIFT 2 -> z"
>               symbol "RSHIFT"
>               n <- int
>               symbol _assign
>               var <- identifier
>               return $ (var ++ " :: Int\n" ++ 
>                         var ++ " = " ++ x ++ " `shift` (" ++ show (-n) ++ ")\n", var)

Um eg:

Main> fst $ head $ parse command2 "x LSHIFT 2 -> v"
("v :: Int\nv = x `shift` 2\n","v")

-------------------------------------------------------------------------------

Esta fun��o l� o programa WIRES, faz o parsing, escreve o m�dulo Haskell (cham�-mo-lo DslModule.hs) e devolve a lista com os nomes de todas as vari�veis definidas.

> preProcess :: FilePath -> IO [String]
> preProcess filename = 
>    do str <- readFile filename 
>       let xss = lines str
>       let parsing   = map (fst . head . parse command2) xss
>       let functions = map fst parsing 
>       writeFile "DslModule.hs" $ template ++ unlines functions
>       return $ sort $ map snd parsing  -- return list of variables
>    where
>       template = "module DslModule where\n\
>                   \\n\
>                   \import Data.Bits\n\
>                   \\n\
>                   \int2unint n = if n>=0 then n else 65536+n  -- unsigned 16 bit ints \n\
>                   \\n"

Main> preProcess "wires_eg.txt"
["d","e","f","g","h","i","x","y"]

Ap�s a execu��o aparece o novo ficheiro com o m�dulo Haskell contendo as defini��es das fun��es Haskell.

-------------------------------------------------------------------------------

Agora estamos preparados para importar o m�dulo dinamicamente, e avaliar a lista das vari�veis. Para isso temos de usar a API da biblioteca hint (cf. https://github.com/mvdan/hint)

> evaluate :: [String] -> Interpreter ()
> evaluate vars =
>   do setImports ["Prelude"]
>      loadModules ["DslModule.hs"]
>      setTopLevelModules ["DslModule"]  -- module whose context is used during eval
>        -- make string with a Haskell list containing all vars
>      let varsDescription = filter (not.(`elem` "\"")) $ show vars
>      evals <- eval varsDescription
>      say $ show $ zip vars ((read evals) :: [Int])
>    where
>      say :: String -> Interpreter ()
>      say = liftIO . putStrLn

De notar que neste caso, a ordem dos comandos WIRES n�o � relevante. Pass�mos essa complexidade para o interpretador/compilador Haskell!

-------------------------------------------------------------------------------

A fun��o evaluate tem de ser invocada por um programa IO. Apenas as duas linhas comentadas s�o-nos interessantes. O resto � boilerplate:

> mainEval :: IO ()
> mainEval = 
>   do makeEg
>      vars <- preProcess "wires_eg.txt"    -- read problem, make module & return vars
>      r <- runInterpreter $ evaluate vars  -- executar o interpretador
>      case r of
>        Left err -> putStrLn $ errorString err
>        Right () -> return ()
>   where
>      errorString :: InterpreterError -> String
>      errorString (WontCompile es) = intercalate "\n" (header : map unbox es)
>        where
>          header = "ERROR: Won't compile:"
>          unbox (GhcError e) = e
>      errorString e = show e

Main> mainEval
[("d",72),("e",507),("f",492),("g",114),("h",65412),("i",65079),("x",123),("y",456)]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Solu��o 3: escrevendo a DSL no Haskell

Nesta abordagem n�o usamos ficheiros que descrevem comandos WIRES. Em alernativa criamos esses comandos em Haskell, e tentamos aproximar a sintaxe Haskell � DSL desejada.

-------------------------------------------------------------------------------

Sejam as seguintes fun��es que descrevem os comandos WIRES:

> _CONST :: Int -> (Operator, [Variable], Data)
> _CONST n = (CONST, [], n)
> 
> _AND :: Variable -> Variable -> (Operator, [Variable], Data)
> _AND x y = (AND, [x,y], 0)
> 
> _OR  :: Variable -> Variable -> (Operator, [Variable], Data)
> _OR x y = (OR, [x,y], 0)
> 
> _NOT :: Variable -> (Operator, [Variable], Data)
> _NOT x = (NOT, [x], 0)
> 
> _RSHIFT :: Variable -> Int -> (Operator, [Variable], Data)
> _RSHIFT x n = (RSHIFT, [x], n)
> 
> _LSHIFT :: Variable -> Int -> (Operator, [Variable], Data)
> _LSHIFT x n = (LSHIFT, [x], n)

(mantive as ma�usculas, mas � necess�rio adicionar um underscore para o Haskell n�o reclamar, tamb�m n�o usei valores que nas solu��es anteriores, para se poder observar no interpretador a estrutura de dados produzida)

Estas fun��es criam estruturas com a informa��o necess�ria para executar um comando WIRES.

Eg:

Main> "x" `_LSHIFT` 2     -- parecido com  x LSHIFT 2
(LSHIFT,["x"],2)

-------------------------------------------------------------------------------

J� o operador WIRES -> tem uma defini��o um pouco diferente:

> (->-) :: (Operator, [Variable], Data) -> Variable -> State [Node] ()
> (->-) (op, args, val) var = modify $ ins (var, op, args, val)
>   where
>     ins x xs = x:xs
    
Aqui vamos usar a m�nada State que introduz a ideia de estado (embrulhado no contexto computacional desta m�nada, j� que no Haskell puro, sem efeitos secund�rios, n�o pode existir um estado persistente). Para mais informa��o cf. sec��o 13.3 do livro do Lipovaca.

O operador (->-) vai anexar uma fun��o/comando WIRES que adiciona um novo valor Node aos j� produzidos at� ao momento.

O uso da m�nada permite-nos usar o operador 'do' para recriar a DSL num formato 'haskellizado' (a ordem dos comandos � relevante):

> problem = evalDSL $ do
>      _CONST 123      ->- "x"  
>      _CONST 456      ->- "y"
>      _NOT "x"        ->- "h"
>      _NOT "y"        ->- "i"
>      "x" `_LSHIFT` 2 ->- "f"
>      "y" `_RSHIFT` 2 ->- "g"
>      "x" `_AND` "y"  ->- "d"
>      "x" `_OR`  "y"  ->- "e"

A avalia��o come�a com a lista de Nodes vazia, que � constru�da em cada comando WIRES.
� preciso reverter a lista para que sejam primeiro avaliados os comandos iniciais.

> evalDSL :: State [Node] a -> [Node]
> evalDSL f = reverse $ execState f [] 

A fun��o 'execState' da biblioteca Control.Monad.State avalia um estado a partir de um estado inicial (aqui a lista de Nodes vazia) e devolve o estado final (a lista de Nodes, um por cada comando).

Podemos ver o que � produzido neste eg:

Main> problem
[("x",CONST,[],123),("y",CONST,[],456),("h",NOT,["x"],0),("i",NOT,["y"],0),("f",LSHIFT,["x"],2),("g",RSHIFT,["y"],2),("d",AND,["x","y"],0),("e",OR,["x","y"],0)]

Main> :t problem
problem :: [Node]

-------------------------------------------------------------------------------

Mas ainda n�o calcul�mos os valores finais das vari�veis, apenas temos os Nodes com a informa��o a ser tratada. Este � o papel da fun��o 'solveDSL'.

A fun��o 'solveDSL' processa a lista de Nodes produzida por 'problem'. Por cada Node processado � criada uma nova hash table actualizada. Aqui estamos a trabalhar em Haskell puro (o uso da m�nada State cingiu-se ao programa 'problem').

> solveDSL :: [Node] -> M.Map Variable Data -> M.Map Variable Data
> solveDSL [] mp = mp   -- all Nodes were processed, return this hash table
> 
> solveDSL ((var, CONST, _, val) : ops) mp = solveDSL ops (M.insert var val mp)
> 
> solveDSL ((var, NOT, [x], _)   : ops) mp = solveDSL ops (M.insert var val mp)
>   where
>     xVal = M.findWithDefault 0 x mp -- assumes that always find the value (0 is dummy)
>     val = int2unint $ complement xVal
> 
> solveDSL ((var, op, [x], y) : ops) mp = solveDSL ops (M.insert var val mp)
>   where
>     xVal = M.findWithDefault 0 x mp 
>     val = (getOp op) xVal y
>     
> solveDSL ((var, op, [x,y], _) : ops) mp = solveDSL ops (M.insert var val mp)
>   where
>     xVal = M.findWithDefault 0 x mp 
>     yVal = M.findWithDefault 0 y mp
>     val = (getOp op) xVal yVal

-------------------------------------------------------------------------------

Agora � apenas necess�rio invocar o 'solveDSL' com uma hash inicialmente vazia e mostrar o resultado final que a fun��o produz:

> mainDSL = putStrLn $ show $ solveDSL problem M.empty
    
Main> mainDSL
fromList [("d",72),("e",507),("f",492),("g",114),("h",65412),("i",65079),("x",123),("y",456)]

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Refs:

http://hackage.haskell.org/package/hint-0.6.0/docs/Language-Haskell-Interpreter.html
https://github.com/mvdan/hint/tree/master/examples
http://beautifulracket.com/public/wires/
http://www.lpenz.org/articles/hedsl-sharedexpenses/
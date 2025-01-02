> import Control.Monad
> import Control.Monad.State

> import qualified Data.Map as M       -- hash table
> import Data.List
> import Data.Bits                     -- bitwise operations

> import Language.Haskell.Interpreter  -- to install: cabal install hint

> import Parsing                       -- cf. Hutton, Programming in Haskell, chp.8

-------------------------------------------------------------------------------

Uma domain-specific language (DSL) é uma linguagem que foi construída para um domínio muito específico, na qual podemos expressar problemas relevantes num determinado contexto. Ao contrário de uma linguagem genérica, como o Java ou o Haskell, uma DSL tem uma expressividade limitada. Como exemplos de DSL's temos o HTML, o SQL, os shell scripts do Unix/Linux, as expressões regulares, Lex/YACC para parsing, o OpenGL para gráficos vectoriais, Markdown para documentação, as linguagens estatísticas BUGS e Stan, o Csound para sons e música, etc.

Este documento pretende mostrar algumas formas de usar DSL's na programação Haskell.

Iremos usar uma pequena DSL para representar circuitos lógicos (sem ciclos), a linguagem WIRES, que permite manipular valores inteiros de 16 bits (cf. http://beautifulracket.com/wires/), tendo os seguintes operadores bit a bit:

+ Atribuição de valores a 'wires', eg: 123 -> x

+ Negação, eg: NOT x -> y

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

Façamos um pequeno programa IO para guardar este programa WIRES como exemplo a utilizar adiante:

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

Vamos abordar três soluções:

+ usando um parser para criar uma estrutura de dados que usamos para calcular a solução,

+ criando e avaliando dinamicamente expressões Haskell

+ definindo a DSL na própria linguagem Haskell

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

Solução 1: usando um parser

Um parser é um programa que analisa uma string com uma expressão que segue uma dada gramática e traduz essa expressão para uma estrutura adequada. 

Por exemplo, um parser para expressões WIRE com o operador NOT tem de analisar frases com a seguinte gramática:

    not ::= 'NOT' identifier '->' identifier
    
onde 'identifier' é uma palavra, e onde os tokens 'NOT' e '->' tem de estar na posição correcta. Exemplos de strings que seguem este formato são 

    NOT abc -> aaa
    NOT x -> y

e contra-exemplos:

    abs NOT -> aaa
    aaa <- NOT abs

Se lerem o módulo Parsing.lhs verão que já existem vários parsers para tarefas comuns, como analisar uma palavra ou um inteiro. Vejam o capítulo 8 do livro do Hutton, Programming in Haskell, para mais informação e para aprenderem a construir os vossos parsers.

Neste caso, um exemplo de parser para respeitar a gramática acima seria:
    
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

As variáveis são strings, e os valores são inteiros. Definimos um enumerado para representar as diferentes operações da DSL. Um Node corresponde à informação de um comando WIRE. Por exemplo, os comandos

    x AND y -> z
    x LSHIFT 2 -> v
    123 -> w

serão representados pelos seguintes valores Node:

    ("z", AND, ["x","y"], unkown)   <- aqui não usamos o Data
    ("v", LSHIFT, ["x"], 2)
    ("w", CONST, unkown, 123)       <- aqui não usamos a lista de vars

O objetivo é criar um parser 

    command :: Parse Node
    
que dado um comando, devolva o Node respectivo. Por exemplo:

Main> fst $ head $ parse command "x LSHIFT 2 -> v"
("v",LSHIFT,["x"],2)

Primeiro definimos a gramática (aqui, em formato EBNF):

     command ::= const | not | and | or | lshift | rshift
	 
	 const  ::=                        int     '->' identifier
	 not    ::=            'NOT'    identifier '->' identifier
	 and    ::= identifier 'AND'    identifier '->' identifier
	 or     ::= identifier 'OR'     identifier '->' identifier
	 lshift ::= identifier 'LSHIFT' identifier '->' identifier
	 rshift ::= identifier 'RSHIFT' identifier '->' identifier

Este é o parser que a realiza:     
     
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

A seguinte função auxiliar faz-nos a correspondência das operações WIRES com funções Haskell do módulo Data.Bits:

> getOp :: Operator -> (Int -> Int -> Int)
> getOp AND    = (.&.)
> getOp OR     = (.|.)
> getOp LSHIFT = shift
> getOp RSHIFT = \x n -> shift x (-n)

E esta transforma os valores negativos em valores unsigned:

> int2unint n = if n>=0 then n else 65536+n

-------------------------------------------------------------------------------

O uso do parser em todas os comandos WIRES vai resultar numa lista de Node. Esta lista corresponde a uma série de operações que vão criar os valores para cada variável. a próxima função efectua estes cálculos, usando um hash map para ir guardando os valores já encontrados. No fim, devolve um hash map com os valores todos.

De notar que esta função espera que os comandos WIRES estejam numa ordem adequada, ie, que se se usa uma variável x para calcular a variável y, o x já terá sido calculado. Ou seja, a ordem dos comandos WIRES é importante!

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

Já temos tudo o que precisamos. Vamos criar uma programa para calcular os valores do exemplo inicial:

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

Solução 2: avaliação dinâmica de código Haskell

O Haskell não possui um eval de raíz, ie, uma função que leia uma string contendo código Haskell e que o execute. Isto deve-se muito ao facto do Haskell ser uma linguagem pura, sem efeitos secundários.

No entanto existe (pelo menos) uma biblioteca que nos permite criar um ambiente onde podemos avaliar strings com comandos Haskell num ambiente controlado ao qual podemos ir buscar resultados. Vejamos um exemplo com a biblioteca 'hint' (para instalar, executar na linha de comandos, cabal install hint).

A técnica usada é a seguinte: vamos fazer outro parsing do ficheiro com os comandos WIRES. Este parsing, em vez de criar listas de Nodes, vai criar um conjunto de funções Haskell que calculam os valores das variáveis desejadas! 

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
    
Depois é só anexar isto num módulo Haskell para ser avaliado pela biblioteca 'hint'.

-------------------------------------------------------------------------------

Desta vez será produzindo um par pelo parser. A primeira componente é a função Haskell que queremos salvar no módulo. A segunda componente é o nome da variável definida. Isto vai dar-nos jeito adiante. Ei-lo:

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

Esta função lê o programa WIRES, faz o parsing, escreve o módulo Haskell (chamá-mo-lo DslModule.hs) e devolve a lista com os nomes de todas as variáveis definidas.

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

Após a execução aparece o novo ficheiro com o módulo Haskell contendo as definições das funções Haskell.

-------------------------------------------------------------------------------

Agora estamos preparados para importar o módulo dinamicamente, e avaliar a lista das variáveis. Para isso temos de usar a API da biblioteca hint (cf. https://github.com/mvdan/hint)

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

De notar que neste caso, a ordem dos comandos WIRES não é relevante. Passámos essa complexidade para o interpretador/compilador Haskell!

-------------------------------------------------------------------------------

A função evaluate tem de ser invocada por um programa IO. Apenas as duas linhas comentadas são-nos interessantes. O resto é boilerplate:

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

Solução 3: escrevendo a DSL no Haskell

Nesta abordagem não usamos ficheiros que descrevem comandos WIRES. Em alernativa criamos esses comandos em Haskell, e tentamos aproximar a sintaxe Haskell à DSL desejada.

-------------------------------------------------------------------------------

Sejam as seguintes funções que descrevem os comandos WIRES:

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

(mantive as maíusculas, mas é necessário adicionar um underscore para o Haskell não reclamar, também não usei valores que nas soluções anteriores, para se poder observar no interpretador a estrutura de dados produzida)

Estas funções criam estruturas com a informação necessária para executar um comando WIRES.

Eg:

Main> "x" `_LSHIFT` 2     -- parecido com  x LSHIFT 2
(LSHIFT,["x"],2)

-------------------------------------------------------------------------------

Já o operador WIRES -> tem uma definição um pouco diferente:

> (->-) :: (Operator, [Variable], Data) -> Variable -> State [Node] ()
> (->-) (op, args, val) var = modify $ ins (var, op, args, val)
>   where
>     ins x xs = x:xs
    
Aqui vamos usar a mónada State que introduz a ideia de estado (embrulhado no contexto computacional desta mónada, já que no Haskell puro, sem efeitos secundários, não pode existir um estado persistente). Para mais informação cf. secção 13.3 do livro do Lipovaca.

O operador (->-) vai anexar uma função/comando WIRES que adiciona um novo valor Node aos já produzidos até ao momento.

O uso da mónada permite-nos usar o operador 'do' para recriar a DSL num formato 'haskellizado' (a ordem dos comandos é relevante):

> problem = evalDSL $ do
>      _CONST 123      ->- "x"  
>      _CONST 456      ->- "y"
>      _NOT "x"        ->- "h"
>      _NOT "y"        ->- "i"
>      "x" `_LSHIFT` 2 ->- "f"
>      "y" `_RSHIFT` 2 ->- "g"
>      "x" `_AND` "y"  ->- "d"
>      "x" `_OR`  "y"  ->- "e"

A avaliação começa com a lista de Nodes vazia, que é construída em cada comando WIRES.
É preciso reverter a lista para que sejam primeiro avaliados os comandos iniciais.

> evalDSL :: State [Node] a -> [Node]
> evalDSL f = reverse $ execState f [] 

A função 'execState' da biblioteca Control.Monad.State avalia um estado a partir de um estado inicial (aqui a lista de Nodes vazia) e devolve o estado final (a lista de Nodes, um por cada comando).

Podemos ver o que é produzido neste eg:

Main> problem
[("x",CONST,[],123),("y",CONST,[],456),("h",NOT,["x"],0),("i",NOT,["y"],0),("f",LSHIFT,["x"],2),("g",RSHIFT,["y"],2),("d",AND,["x","y"],0),("e",OR,["x","y"],0)]

Main> :t problem
problem :: [Node]

-------------------------------------------------------------------------------

Mas ainda não calculámos os valores finais das variáveis, apenas temos os Nodes com a informação a ser tratada. Este é o papel da função 'solveDSL'.

A função 'solveDSL' processa a lista de Nodes produzida por 'problem'. Por cada Node processado é criada uma nova hash table actualizada. Aqui estamos a trabalhar em Haskell puro (o uso da mónada State cingiu-se ao programa 'problem').

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

Agora é apenas necessário invocar o 'solveDSL' com uma hash inicialmente vazia e mostrar o resultado final que a função produz:

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
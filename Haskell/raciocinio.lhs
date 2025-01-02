> import Prelude hiding (zip, zip3)

--------------------------------------------------------------------

A característica principal de um programa é o estar correcto.

De nada serve um programa ser rápido ou gastar pouca memória
se devolver resultados errados!

Mas coloca-se uma questão: o que determina a correcção de um programa?

Por exemplo, segue a definição da função zip 

> zip [] _  = []
> zip _  [] = []
> zip (x:xs) (y:ys) = (x,y) : zip xs ys

Estará esta definição correcta?

Ora, a resposta a esta pergunta depende dos requisitos que foram 
pedidos pelo cliente/enunciado/contracto.

Um programa não está correcto por si mesmo, um programa está 
correcto **em relação a uma especificação**

Uma especificação é uma lista de propriedades (também designados
por requisitos) que o programa tem de satisfazer.

A especificação típica do zip tem duas propriedades:

    E1: o i-ésimo par do resultado é dado pelos respectivos i-ésimos
        elementos das duas listas dadas. Numa notação mais formal:
    
    (zip xs ys)!!i == (xs!!i, ys!!i);  0<=i<min(length xs, length ys)
            
    E2: a dimensão da lista resultante é dada pela menor dimensão das
        listas dadas    

            length(zip xs ys) == min(length xs, length ys)
            
Assim, quando perguntamos se a função zip está correcta, o que estamos 
a perguntar é se zip satisfaz E1+E2 para todas as listas xs e ys.

Se nos requisitos para zip trocarmos E2 por: 

    E3: a função deve copiar o resto da maior lista para os dois 
        elementos dos pares sobrantes"
        
        (zip xs ys)!!i == (zs!!i,zs!!i); 
             min(length xs, length ys)<=i<max(length xs, length ys)
             zs == a maior das listas.
             
então a definição de zip estaria incorrecta, dado que não satisfaz E3.

A seguinte definição estaria correcta de acordo com E1+E3:

> zip2   []     []   = []
> zip2   []   (y:ys) = (y,y) : zip2 [] ys
> zip2 (x:xs)   []   = (x,x) : zip2 xs []
> zip2 (x:xs) (y:ys) = (x,y) : zip2 xs ys

Main> zip2 [1,2,3,4] [5,6]
[(1,5),(2,6),(3,3),(4,4)]

---

Por outro lado, a seguinte função está correcta de acordo apenas com E1:

> zip3   []     []   = []
> zip3   []   (y:ys) = (0,y) : zip3 [] ys
> zip3 (x:xs)   []   = (x,0) : zip3 xs []
> zip3 (x:xs) (y:ys) = (x,y) : zip3 xs ys

Main> zip3 [1,2,3,4] [5,6]
[(1,5),(2,6),(3,0),(4,0)]

--------------------------------------------------------------------

Podemos interpretar uma especificação como um conjunto de todos os
programas que a satisfazem.

Quanto mais específica for uma especificação, menor é o número
de programas que contém.

Os programas anteriores poderiam ser organizados do seguinte modo:

      +---------------------------------------------------+
      |E1                                                 |
      |    +-----------------------------+      zip3      |
      |    |E1+E2                        |                |
      |    |           +-------------------------------+  |
      |    |           |E1+E2+E3         |        E1+E3|  |
      |    |   zip     |                 |             |  |
      |    |           |                 |             |  |
      |    +-----------------------------+    zip2     |  |
      |                |                               |  |
      |                +-------------------------------+  |
      +---------------------------------------------------+

De acordo com a nossa ideia do como o zip deve funcionar, 
percebemos que a especificação que desejamos é E1+E2.

A especificação E1 é um exemplo de *sub-especificação*,
uma especificação demasiado genérica que permite comportamentos
indesejados, como adicionar valores estranhos à lista para lá
dos pares correctos.

Uma *sobre-especificação* é mais exigente que a especificação 
desejada, podendo limitar desnecessariamente a liberdade do 
programador que tem de implementar uma solução. Por exemplo, 
a especificação poderia exigir uma solução não recursiva.

Em certos casos, a sobre-especificação pode ser *incoerente*
o que significa que é impossível de se cumprir. Por outras palavras
o conjunto de programas capaz de a satisfazer corresponde
ao conjunto vazio. Esse é o caso da especificação E1+E2+E3.

--------------------------------------------------------------------

A especificação é uma representação mais ou menos objectiva
da intenção mais ou menos subjectiva do cliente.

Existem vários métodos formais de especificar o que é suposto
ser implementado. Estes métodos descrevem o que *deve* ser 
cumprido, não *como* se deve cumprir. 

A característica de ser formal ajuda a retirar ambiguidade entre 
o que o cliente deseja, e o que o fornecedor entende dos desejos
do cliente.

Uma implementação correcta é uma descrição algorítmica 
suficientemente eficiente que permite satisfazer a especificação 
no tempo e espaço disponível.

--------------------------------------------------------------------

Podemos (ultra-)resumir o desenvolvimento de software da seguinte forma:

  1) Escrever uma especificação E do problema dado numa linguagem formal
  2) Implementar uma solução P eficiente que satisfaça E
  3) Mostrar que P pertence a E

---
  
Exemplo básico:

1) definir uma função inc :: Int -> Int que satisfaça inc x >= x^2

2) inc :: Int -> Int
   inc x = x^2 + 1     {inc1}  <- atribuímos um identificador à equação

3) A especificação possui apenas uma propriedade: inc x >= x^2

Ela é satisfeita pelo programa dado que:

   inc x    ==  {definição de inc1}
   x^2+1    >=  {uso de álgebra}
   x^2      

--------------------------------------------------------------------

Os exemplos de especificação que vamos focar são funções Haskell 
que manipulam listas.

Para descrever propriedades, usaremos a notação matemática e um 
conjunto de funções Haskell que assumimos disponíveis.

Se nenhuma pré-condição for referida, assumimos a existência de 
um quantificador universal para cada valor que surge na propriedade.
Por exemplo, a propriedade 

    length xs + length ys == length (xs++ys)
    
é um resumo de

    Para todas as listas xs e ys : 
       length xs + length ys == length (xs++ys)

--------------------------------------------------------------------

Seguem alguns exemplos de especificação. 

Podendo usar length e (!!) especificar as funções take e map:

  (take n xs)!!i     == xs!!i            , 0 <= i < min(n,length xs)
  length (take n xs) == min(n,length xs)

  (map f xs)!!i      == f (xs!!i)        , 0 <= i < length xs
  length (map f xs)  == length xs

--------------------------------------------------------------------

Em princípio podemos mostrar que um programa satisfaz uma dada 
propriedade.

Exemplo: será que a definição de (++)

        []  ++ ys = ys         {++1}
     (x:xs) ++ ys = x:xs++ys   {++2}

satisfaz a propriedade [z]++zs == z:xs ?

Sim, porque:

      [z]  ++ zs ==        {sintaxe Haskell}
    (z:[]) ++ zs ==        {++2}
      z:([]++zs) ==        {++1}
            z:zs       

---

Exemplo: a definição de reverse

       reverse   []   = []                 {rev1}
       reverse (x:xs) = reverse xs ++ [x]  {rev2}
       
satisfaz a propriedade reverse [x] == [x]?

        reverse   [x]  ==    {sintaxe}
        reverse (x:[]) ==    {rev2}
     reverse [] ++ [x] ==    {rev1}
         []     ++ [x] ==    {++1}
                   [x] 
                   
--------------------------------------------------------------------

Para mostrar que um programa satisfaz uma especificação mostramos
que o programa satisfaz todas as propriedades que compõem essa 
especificação.

Vejamos um exemplo, assumindo disponíveis as seguintes definições: 

              equação           |   id
    ----------------------------+-------
        []  ++ ys = ys          |  {++1}
     (x:xs) ++ ys = x:xs++ys    |  {++2}
                                |
         last [x] = x           |  {last1}
      last (x:xs) = last xs     |  {last2}

O nosso problema é definir a função init que devolve a lista 
dada sem o seu último elemento.

Passo 1: Especificar a função init usando uma ou mais propriedades:

    prop_init:   init xs ++ [last xs] == xs;  para todo xs não vazio

Passo 2: Implementar uma solução

    init  [x]   = []             {init1}
    init (x:xs) = x:init xs      {init2}

Passo 3: Mostrar que a solução está correcta de acordo com a especificação

Como mostrar a correcção desta solução? Ie, a definição de init 
satisfaz/pertence à especificação?

Para mostrar a correcção teremos de provar que cada propriedade
da respectiva especificação é verdade para a função dada.

Neste caso temos apenas uma propriedade, prop_init:

    init xs ++ [last xs] == xs

A forma como se demonstram a maior parte das propriedades é usando
um raciocício por indução matemática, o que é natural, dado que 
a indução espelha a estrutura recursiva da solução Haskell. 

Assim:    

Caso 1:  xs == [x]    (base da indução)

  init [x] ++ [last [x]] ==   {init1}
  [] ++ [last [x]]       ==   {last1}
  [] ++ [x]              ==   {++1}
  [x] 
  
Caso 2:  xs == x:xs'  (passo da indução)

A Hipótese de Indução (HI) assume que a propriedade é válida
para o resto da lista, ie, init xs' ++ [last xs'] == xs'
  
  init (x:xs') ++ [last (x:xs')] ==   {init2}
  x:init xs'  ++ [last (x:xs')]  ==   {last2}
  x:init xs'  ++ [last xs']      ==   {++2}
  x:(init xs' ++ [last xs'])     ==   {HI}
  x:xs' 
  
Desta forma, mostrámos que a definição de init satisfaz a 
propriedade prop_init, ie, a solução está correcta de acordo
com a especificação!

--------------------------------------------------------------------

Outro exemplo: tendo as seguintes definições

  sum []       = 0           (sum1)
  sum (x:xs)   = x + sum xs  (sum2)
  
  [] ++ ys     = ys          (++1)
  (x:xs) ++ ys = x:(xs++ys)  (++2)

mostre que a propriedade 

  sum (xs++ys) == sum xs + sum ys

é satisfeita para todas as listas finitas xs e ys.

Resolução por indução em xs (ys está fixo):

Caso 1: xs == []      (base da indução)

Vamos desenvolver os dois lados da propriedade em colunas distintas:

  sum ([]++ys)    ==  {++1}      |   sum [] + sum ys    ==  {sum1}
  sum ys                         |   0 + sum ys         ==   
                                 |   sum ys
                                   
Chegámos ao mesmo resultado, logo a base da indução é verificada.
                                     
Caso 2: xs == x:xs'   (passo da indução)

HI: sum (xs'++ys) == sum xs' + sum ys

  sum ((x:xs')++ys)  ==  {++2}   |   sum (x:xs') + sum ys   ==  {sum2}
  sum (x:(xs'++ys))  ==  {sum2}  |   x + sum xs' + sum ys
  x + sum (xs'++ys)  ==  {HI}    |   
  x + sum xs' + sum ys           | 

O mesmo ocorreu com o passo da indução!
    
Assim, mostrámos por indução que a propriedade é satisfeita pelas 
funções dadas.    
    
--------------------------------------------------------------------

Em resumo, para provar a propriedade prop(xs) por indução, para todas
as listas finitas xs, mostram-se os seguintes casos:

Caso 1: prop([]) é verdade
Caso 2: Se prop(xs') é verdade então prop(x:xs') é verdade, para todo o x

--------------------------------------------------------------------

Para mostrar propriedades que relacionam funções (no contexto das listas)
podemos invocar o princípio da extensionalidade:

    f == g  sse  para toda a lista xs: f xs == g xs
    
Exemplo. Sejam

        sum   []   = 0               {sum1}
        sum (x:xs) = x + sum xs      {sum2}
        
        doub  []    = []             {doub1}
        doub (x:xs) = 2*x : doub xs  {doub2}
        
        (.) f g x = f (g x)          {.1}
        
será verdade a propriedade

    prop: sum . doub == (*2) . sum
    
Segundo o princípio da extensionalidade, mostrar que prop é satisfeita 
é o mesmo que mostrar prop'

    prop': (sum . doub) xs == ((*2) . sum) xs
    
E esta propriedade podemos mostrá-la por indução.

Caso 1: xs == []    

    (sum . doub) [] ==  {.1}           |   ((*2) . sum) []  ==  {.1}
    sum (doub [])   ==  {doub1}        |   (*2) (sum [])    ==  {sum1}
    sum []          ==  {sum1}         |   (*2) 0           ==  {aplicação}
    0                                  |   0
    
Caso 2: xs == x:xs'

HI:   (sum . doub) xs' == ((*2) . sum) xs' 

 (sum . doub) (x:xs')   ==   {.1}         |  ((*2) . sum) (x:xs')  ==   {.1}
 sum (doub (x:xs'))     ==   {dou2}       |  (*2) (sum (x:xs'))    ==   {sum2}
 sum (2*x : doub xs')   ==   {sum2}       |  (*2) (x + sum xs')    ==   {def(*2)}
 2*x + sum (doub xs')   ==   {.1}         |  (x + sum xs') * 2     ==   {álgebra}
 2*x + (sum . doub) xs' ==   {HI}         |  2*x + sum xs' * 2
 2*x + ((*2). sum) xs'  ==   {def(*2),.1} |  
 2*x + sum xs' * 2                        |
 
e chegamos à mesma expressão, o que significa que prop' é satisfeita. 

Pelo princípio da extensionalidade, prop também é satisfeita.
                                  
--------------------------------------------------------------------

Problemas desta abordagem:

* A linguagem formal pode não conseguir exprimir todos os requisitos 
  informais do cliente
* Mostrar que P pertence a E pode ser demasiado complexo para o fazer
  por dedução matemática  
  
Em relação a este 2º ponto, o que ocorre normalmente no desenvolvimento
de software é que se substituí o raciocínio matemático-dedutivo por um 
processo empírico-indutivo (nota: método indutivo /= indução matemática) 
de tentar encontrar falhas, ie, contra-exemplos. 

Esta é a natureza habitual de testar software. Não mostramos que a 
implementação está correcta mas, ao testar a implementação com casos 
de teste, ganhamos empiricamente confiança que o código satisfaz as 
propriedades da especificação.

No Haskell, para testar as nossas propriedades empiricamente, vamos 
usar o módulo QuickCheck.

> import Prelude hiding (zip, zip3)

--------------------------------------------------------------------

A caracter�stica principal de um programa � o estar correcto.

De nada serve um programa ser r�pido ou gastar pouca mem�ria
se devolver resultados errados!

Mas coloca-se uma quest�o: o que determina a correc��o de um programa?

Por exemplo, segue a defini��o da fun��o zip 

> zip [] _  = []
> zip _  [] = []
> zip (x:xs) (y:ys) = (x,y) : zip xs ys

Estar� esta defini��o correcta?

Ora, a resposta a esta pergunta depende dos requisitos que foram 
pedidos pelo cliente/enunciado/contracto.

Um programa n�o est� correcto por si mesmo, um programa est� 
correcto **em rela��o a uma especifica��o**

Uma especifica��o � uma lista de propriedades (tamb�m designados
por requisitos) que o programa tem de satisfazer.

A especifica��o t�pica do zip tem duas propriedades:

    E1: o i-�simo par do resultado � dado pelos respectivos i-�simos
        elementos das duas listas dadas. Numa nota��o mais formal:
    
    (zip xs ys)!!i == (xs!!i, ys!!i);  0<=i<min(length xs, length ys)
            
    E2: a dimens�o da lista resultante � dada pela menor dimens�o das
        listas dadas    

            length(zip xs ys) == min(length xs, length ys)
            
Assim, quando perguntamos se a fun��o zip est� correcta, o que estamos 
a perguntar � se zip satisfaz E1+E2 para todas as listas xs e ys.

Se nos requisitos para zip trocarmos E2 por: 

    E3: a fun��o deve copiar o resto da maior lista para os dois 
        elementos dos pares sobrantes"
        
        (zip xs ys)!!i == (zs!!i,zs!!i); 
             min(length xs, length ys)<=i<max(length xs, length ys)
             zs == a maior das listas.
             
ent�o a defini��o de zip estaria incorrecta, dado que n�o satisfaz E3.

A seguinte defini��o estaria correcta de acordo com E1+E3:

> zip2   []     []   = []
> zip2   []   (y:ys) = (y,y) : zip2 [] ys
> zip2 (x:xs)   []   = (x,x) : zip2 xs []
> zip2 (x:xs) (y:ys) = (x,y) : zip2 xs ys

Main> zip2 [1,2,3,4] [5,6]
[(1,5),(2,6),(3,3),(4,4)]

---

Por outro lado, a seguinte fun��o est� correcta de acordo apenas com E1:

> zip3   []     []   = []
> zip3   []   (y:ys) = (0,y) : zip3 [] ys
> zip3 (x:xs)   []   = (x,0) : zip3 xs []
> zip3 (x:xs) (y:ys) = (x,y) : zip3 xs ys

Main> zip3 [1,2,3,4] [5,6]
[(1,5),(2,6),(3,0),(4,0)]

--------------------------------------------------------------------

Podemos interpretar uma especifica��o como um conjunto de todos os
programas que a satisfazem.

Quanto mais espec�fica for uma especifica��o, menor � o n�mero
de programas que cont�m.

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
percebemos que a especifica��o que desejamos � E1+E2.

A especifica��o E1 � um exemplo de *sub-especifica��o*,
uma especifica��o demasiado gen�rica que permite comportamentos
indesejados, como adicionar valores estranhos � lista para l�
dos pares correctos.

Uma *sobre-especifica��o* � mais exigente que a especifica��o 
desejada, podendo limitar desnecessariamente a liberdade do 
programador que tem de implementar uma solu��o. Por exemplo, 
a especifica��o poderia exigir uma solu��o n�o recursiva.

Em certos casos, a sobre-especifica��o pode ser *incoerente*
o que significa que � imposs�vel de se cumprir. Por outras palavras
o conjunto de programas capaz de a satisfazer corresponde
ao conjunto vazio. Esse � o caso da especifica��o E1+E2+E3.

--------------------------------------------------------------------

A especifica��o � uma representa��o mais ou menos objectiva
da inten��o mais ou menos subjectiva do cliente.

Existem v�rios m�todos formais de especificar o que � suposto
ser implementado. Estes m�todos descrevem o que *deve* ser 
cumprido, n�o *como* se deve cumprir. 

A caracter�stica de ser formal ajuda a retirar ambiguidade entre 
o que o cliente deseja, e o que o fornecedor entende dos desejos
do cliente.

Uma implementa��o correcta � uma descri��o algor�tmica 
suficientemente eficiente que permite satisfazer a especifica��o 
no tempo e espa�o dispon�vel.

--------------------------------------------------------------------

Podemos (ultra-)resumir o desenvolvimento de software da seguinte forma:

  1) Escrever uma especifica��o E do problema dado numa linguagem formal
  2) Implementar uma solu��o P eficiente que satisfa�a E
  3) Mostrar que P pertence a E

---
  
Exemplo b�sico:

1) definir uma fun��o inc :: Int -> Int que satisfa�a inc x >= x^2

2) inc :: Int -> Int
   inc x = x^2 + 1     {inc1}  <- atribu�mos um identificador � equa��o

3) A especifica��o possui apenas uma propriedade: inc x >= x^2

Ela � satisfeita pelo programa dado que:

   inc x    ==  {defini��o de inc1}
   x^2+1    >=  {uso de �lgebra}
   x^2      

--------------------------------------------------------------------

Os exemplos de especifica��o que vamos focar s�o fun��es Haskell 
que manipulam listas.

Para descrever propriedades, usaremos a nota��o matem�tica e um 
conjunto de fun��es Haskell que assumimos dispon�veis.

Se nenhuma pr�-condi��o for referida, assumimos a exist�ncia de 
um quantificador universal para cada valor que surge na propriedade.
Por exemplo, a propriedade 

    length xs + length ys == length (xs++ys)
    
� um resumo de

    Para todas as listas xs e ys : 
       length xs + length ys == length (xs++ys)

--------------------------------------------------------------------

Seguem alguns exemplos de especifica��o. 

Podendo usar length e (!!) especificar as fun��es take e map:

  (take n xs)!!i     == xs!!i            , 0 <= i < min(n,length xs)
  length (take n xs) == min(n,length xs)

  (map f xs)!!i      == f (xs!!i)        , 0 <= i < length xs
  length (map f xs)  == length xs

--------------------------------------------------------------------

Em princ�pio podemos mostrar que um programa satisfaz uma dada 
propriedade.

Exemplo: ser� que a defini��o de (++)

        []  ++ ys = ys         {++1}
     (x:xs) ++ ys = x:xs++ys   {++2}

satisfaz a propriedade [z]++zs == z:xs ?

Sim, porque:

      [z]  ++ zs ==        {sintaxe Haskell}
    (z:[]) ++ zs ==        {++2}
      z:([]++zs) ==        {++1}
            z:zs       

---

Exemplo: a defini��o de reverse

       reverse   []   = []                 {rev1}
       reverse (x:xs) = reverse xs ++ [x]  {rev2}
       
satisfaz a propriedade reverse [x] == [x]?

        reverse   [x]  ==    {sintaxe}
        reverse (x:[]) ==    {rev2}
     reverse [] ++ [x] ==    {rev1}
         []     ++ [x] ==    {++1}
                   [x] 
                   
--------------------------------------------------------------------

Para mostrar que um programa satisfaz uma especifica��o mostramos
que o programa satisfaz todas as propriedades que comp�em essa 
especifica��o.

Vejamos um exemplo, assumindo dispon�veis as seguintes defini��es: 

              equa��o           |   id
    ----------------------------+-------
        []  ++ ys = ys          |  {++1}
     (x:xs) ++ ys = x:xs++ys    |  {++2}
                                |
         last [x] = x           |  {last1}
      last (x:xs) = last xs     |  {last2}

O nosso problema � definir a fun��o init que devolve a lista 
dada sem o seu �ltimo elemento.

Passo 1: Especificar a fun��o init usando uma ou mais propriedades:

    prop_init:   init xs ++ [last xs] == xs;  para todo xs n�o vazio

Passo 2: Implementar uma solu��o

    init  [x]   = []             {init1}
    init (x:xs) = x:init xs      {init2}

Passo 3: Mostrar que a solu��o est� correcta de acordo com a especifica��o

Como mostrar a correc��o desta solu��o? Ie, a defini��o de init 
satisfaz/pertence � especifica��o?

Para mostrar a correc��o teremos de provar que cada propriedade
da respectiva especifica��o � verdade para a fun��o dada.

Neste caso temos apenas uma propriedade, prop_init:

    init xs ++ [last xs] == xs

A forma como se demonstram a maior parte das propriedades � usando
um racioc�cio por indu��o matem�tica, o que � natural, dado que 
a indu��o espelha a estrutura recursiva da solu��o Haskell. 

Assim:    

Caso 1:  xs == [x]    (base da indu��o)

  init [x] ++ [last [x]] ==   {init1}
  [] ++ [last [x]]       ==   {last1}
  [] ++ [x]              ==   {++1}
  [x] 
  
Caso 2:  xs == x:xs'  (passo da indu��o)

A Hip�tese de Indu��o (HI) assume que a propriedade � v�lida
para o resto da lista, ie, init xs' ++ [last xs'] == xs'
  
  init (x:xs') ++ [last (x:xs')] ==   {init2}
  x:init xs'  ++ [last (x:xs')]  ==   {last2}
  x:init xs'  ++ [last xs']      ==   {++2}
  x:(init xs' ++ [last xs'])     ==   {HI}
  x:xs' 
  
Desta forma, mostr�mos que a defini��o de init satisfaz a 
propriedade prop_init, ie, a solu��o est� correcta de acordo
com a especifica��o!

--------------------------------------------------------------------

Outro exemplo: tendo as seguintes defini��es

  sum []       = 0           (sum1)
  sum (x:xs)   = x + sum xs  (sum2)
  
  [] ++ ys     = ys          (++1)
  (x:xs) ++ ys = x:(xs++ys)  (++2)

mostre que a propriedade 

  sum (xs++ys) == sum xs + sum ys

� satisfeita para todas as listas finitas xs e ys.

Resolu��o por indu��o em xs (ys est� fixo):

Caso 1: xs == []      (base da indu��o)

Vamos desenvolver os dois lados da propriedade em colunas distintas:

  sum ([]++ys)    ==  {++1}      |   sum [] + sum ys    ==  {sum1}
  sum ys                         |   0 + sum ys         ==   
                                 |   sum ys
                                   
Cheg�mos ao mesmo resultado, logo a base da indu��o � verificada.
                                     
Caso 2: xs == x:xs'   (passo da indu��o)

HI: sum (xs'++ys) == sum xs' + sum ys

  sum ((x:xs')++ys)  ==  {++2}   |   sum (x:xs') + sum ys   ==  {sum2}
  sum (x:(xs'++ys))  ==  {sum2}  |   x + sum xs' + sum ys
  x + sum (xs'++ys)  ==  {HI}    |   
  x + sum xs' + sum ys           | 

O mesmo ocorreu com o passo da indu��o!
    
Assim, mostr�mos por indu��o que a propriedade � satisfeita pelas 
fun��es dadas.    
    
--------------------------------------------------------------------

Em resumo, para provar a propriedade prop(xs) por indu��o, para todas
as listas finitas xs, mostram-se os seguintes casos:

Caso 1: prop([]) � verdade
Caso 2: Se prop(xs') � verdade ent�o prop(x:xs') � verdade, para todo o x

--------------------------------------------------------------------

Para mostrar propriedades que relacionam fun��es (no contexto das listas)
podemos invocar o princ�pio da extensionalidade:

    f == g  sse  para toda a lista xs: f xs == g xs
    
Exemplo. Sejam

        sum   []   = 0               {sum1}
        sum (x:xs) = x + sum xs      {sum2}
        
        doub  []    = []             {doub1}
        doub (x:xs) = 2*x : doub xs  {doub2}
        
        (.) f g x = f (g x)          {.1}
        
ser� verdade a propriedade

    prop: sum . doub == (*2) . sum
    
Segundo o princ�pio da extensionalidade, mostrar que prop � satisfeita 
� o mesmo que mostrar prop'

    prop': (sum . doub) xs == ((*2) . sum) xs
    
E esta propriedade podemos mostr�-la por indu��o.

Caso 1: xs == []    

    (sum . doub) [] ==  {.1}           |   ((*2) . sum) []  ==  {.1}
    sum (doub [])   ==  {doub1}        |   (*2) (sum [])    ==  {sum1}
    sum []          ==  {sum1}         |   (*2) 0           ==  {aplica��o}
    0                                  |   0
    
Caso 2: xs == x:xs'

HI:   (sum . doub) xs' == ((*2) . sum) xs' 

 (sum . doub) (x:xs')   ==   {.1}         |  ((*2) . sum) (x:xs')  ==   {.1}
 sum (doub (x:xs'))     ==   {dou2}       |  (*2) (sum (x:xs'))    ==   {sum2}
 sum (2*x : doub xs')   ==   {sum2}       |  (*2) (x + sum xs')    ==   {def(*2)}
 2*x + sum (doub xs')   ==   {.1}         |  (x + sum xs') * 2     ==   {�lgebra}
 2*x + (sum . doub) xs' ==   {HI}         |  2*x + sum xs' * 2
 2*x + ((*2). sum) xs'  ==   {def(*2),.1} |  
 2*x + sum xs' * 2                        |
 
e chegamos � mesma express�o, o que significa que prop' � satisfeita. 

Pelo princ�pio da extensionalidade, prop tamb�m � satisfeita.
                                  
--------------------------------------------------------------------

Problemas desta abordagem:

* A linguagem formal pode n�o conseguir exprimir todos os requisitos 
  informais do cliente
* Mostrar que P pertence a E pode ser demasiado complexo para o fazer
  por dedu��o matem�tica  
  
Em rela��o a este 2� ponto, o que ocorre normalmente no desenvolvimento
de software � que se substitu� o racioc�nio matem�tico-dedutivo por um 
processo emp�rico-indutivo (nota: m�todo indutivo /= indu��o matem�tica) 
de tentar encontrar falhas, ie, contra-exemplos. 

Esta � a natureza habitual de testar software. N�o mostramos que a 
implementa��o est� correcta mas, ao testar a implementa��o com casos 
de teste, ganhamos empiricamente confian�a que o c�digo satisfaz as 
propriedades da especifica��o.

No Haskell, para testar as nossas propriedades empiricamente, vamos 
usar o m�dulo QuickCheck.

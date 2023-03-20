```
import random as rnd
import matplotlib.pyplot as plt 
```



---



# Probabilidades

Pierre-Simon Laplace foi um dos grandes matemáticos e físicos (e astronomo, engenheiro, ...) do Século XIX, sendo reconhecido como o Newton da França. Na minha opinião o Newton é que devia ser chamado de Laplace de Inglaterra...

<center><img src='https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Laplace%2C_Pierre-Simon%2C_marquis_de.jpg/225px-Laplace%2C_Pierre-Simon%2C_marquis_de.jpg'></center>

No seu livro _Théorie analytique des probabilités_ de 1812, um dos textos seminais da Teoria das Probabilidades, escreveu:

> A probabilidade de um evento é o rácio do número de casos favoráveis a ele e do número de todos os casos possíveis, quando nada nos leva a esperar que um dos casos ocorra mais frequentemente que qualquer outro, o que os torna, para nós, todos igualmente possíveis.




Na tentativa de formalizar o conceito de probabilidade, a comunidade Matemática definiu os seguintes termos que vocês aprenderam no 12º ano:

+ **Espaço de resultados** ou **Espaço Amostral** - corresponde ao conjunto de todos os casos (também designados resultados) possíveis, que designamos por $\Omega$

+ **Acontecimento** ou **Evento** - é um subconjunto do espaço de resultados

+ **Experiência aleatória** - a execução de uma experiência que produz um resultado do respetivo espaço $\Omega$

Para ilustrar, no contexto do lançamento de um dado  o espaço de resultados corresponde ao conjunto $\{1,2,3,4,5,6\}$. Um evento possível seria um lançamento resultar num número par, que corresponde ao subconjunto $\{2,4,6\} \subseteq \Omega$. Uma experiência aleatória seria lançar o dado uma vez, o que produz um resultado, por exemplo, $5 \in \Omega$.



Vamos definir as probabilidades como Laplace definiu, como um rácio. Para tal, usamos um tipo Python que representa frações,


```
from fractions import Fraction

x = Fraction(1,2)
y = Fraction(1,3)
x + y
```




    Fraction(5, 6)



E a nossa definição de probabilidade também segue do texto:


```
def p(evento, Ω):
  """
  evento : o conjunto de resultados a considerar (evento ⊆ Ω)
  Ω      : o conjunto que representa o espaço de resultados
  """
  return Fraction(len(evento), len(Ω) )
```

## Problemas com Dados 

Podemos agora perguntar qual é a probabilidade de sair um número par se lançarmos um dado de seis faces:


```
Ω_dado = {1,2,3,4,5,6} # espaço de resultados para um dado de seis faces
par  = {2,4,6}         # evento de sair um resultado par

p(par, Ω_dado)         # probabilidade do evento
```




    Fraction(1, 2)



Qual é a probabilidade de sair um valor maior que três se lançarmos um dado de oito faces?


```
Ω_dado8 = {1,2,3,4,5,6,7,8}
maiorQue3 = { res for res in Ω_dado8 if res > 3 }

p(maiorQue3, Ω_dado8)
```




    Fraction(5, 8)



Vamos definir uma função que filtra os eventos de um espaço que satisfazem um predicado:


```
def condicional(predicado, Ω):
  return {resultado for resultado in Ω if predicado(resultado)}
```

Por exemplo, quais são os resultados do espaço anterior que são pares?


```
condicional(lambda n:n%2==0, Ω_dado8)
```




    {2, 4, 6, 8}



## Problemas com Cartas 


Vejamos um exemplo com o baralho de cartas:


```
def baralhoCartas():   
  return [ valor+naipe for naipe in '♤♡♢♧' 
                       for valor in 'AKQJT98765432']

baralho = baralhoCartas()
len(baralho)
```




    52



Vamos considerar como espaço de resultados as mãos iniciais do jogo de Poker (são dadas cinco cartas a cada jogador).

Seja o gerador `combinations` do módulo `itertools` que calcula combinações:


```
from itertools import combinations
```

As mãos possíveis calculam-se por escolher das cartas do baralho, cinco cartas sem repetição e onde a ordem é irrelevante.


```
Ω_maos = { ' '.join(mao) for mao in combinations(baralho, 5) }
len(Ω_maos)  
```




    2598960



Produzimos quase 2.6 milhões de mãos possíveis! Nada mau, Python 💪

Podemos visualizar uma amostra deste espaço de resultados:


```
rnd.sample(Ω_maos, 5)
```




    ['K♡ 6♡ 4♢ 2♢ 2♧',
     'A♤ 8♤ A♢ 9♧ 3♧',
     '7♤ 3♤ 9♡ 3♢ 2♧',
     'K♡ K♢ J♢ 8♢ A♧',
     'A♢ T♢ 9♢ 9♧ 4♧']



Qual é a probabilidade de sair um *poker* na mão inicial?

Como o Marquês de Laplace indica, temos de contar quantos *pokers* são possíveis e calcular o rácio em relação ao espaço de resultados de todas as mãos possíveis:


```
pokers = { mao for mao in Ω_maos 
               if any(mao.count(valor)==4 for valor in 'AKQJT98765432') }
len(pokers)
```




    624



Há 624 pokers distintos, a probabilidade pode ser calculada agora pela função `p`


```
p(pokers, Ω_maos)
```




    Fraction(1, 4165)



## Problemas com Urnas

Outros problemas típicos são aqueles relacionados com urnas. 

Por exemplo, numa urna com sete bolas azuis e quatro bolas vermelhas, tirámos cinco bolas. Calcule as probabilidades de:

+ todas as bolas serem azuis

+ todas as bolas serem vermelhas 

+ haver mais bolas vermelhas que azuis

+ haver mais bolas azuis que vermelhas

Primeiro começamos por definir as várias bolas que estão na urna. Iremos usar um identificador para distinguir bolas da mesma cor.


```
urna = [ '🔵'+str(id) for id in range(1,8) ] + [ '🔴'+str(id) for id in range(1,5) ]
print(urna)
```

    ['🔵1', '🔵2', '🔵3', '🔵4', '🔵5', '🔵6', '🔵7', '🔴1', '🔴2', '🔴3', '🔴4']
    

O nosso espaço de resultados é a combinação destas bolas selecionando apenas cinco bolas (como referido no enunciado do problema):


```
from itertools import combinations

Ω_urna5bolas = { ' '.join(bolas) for bolas in combinations(urna, 5) }
len(Ω_urna5bolas)  
```




    462



A seguinte função auxiliar retorna os resultados que contêm exatamente $n$ bolas de uma cor dada:


```
def contarCor(cor, n, Ω):
  return { res for res in Ω if res.count(cor) == n }
```

A probabilidade de todas as bolas serem azuis?


```
todas5Azuis = contarCor('🔵', 5, Ω_urna5bolas)
p(todas5Azuis, Ω_urna5bolas)
```




    Fraction(1, 22)



A probabilidade de todas as bolas serem vermelhas?



```
todas5Vermelhas = contarCor('🔴', 5, Ω_urna5bolas)
p(todas5Vermelhas, Ω_urna5bolas)
```




    Fraction(0, 1)



O que faz sentido, só há quatro bolas vermelhas mas tirámos cinco bolas. Este é um exemplo de um **evento impossível**.

A probabilidade de haver mais bolas vermelhas que azuis?


```
maisVermelhasQueAzuis = { res for res in Ω_urna5bolas 
                              if res.count('🔴') > res.count('🔵') }
p(maisVermelhasQueAzuis, Ω_urna5bolas)
```




    Fraction(13, 66)



A probabilidade de haver mais bolas azuis que vermelhas?


```
maisAzuisQueVermelhas = { res for res in Ω_urna5bolas 
                              if res.count('🔴') < res.count('🔵') }
p(maisAzuisQueVermelhas, Ω_urna5bolas)
```




    Fraction(53, 66)



Como o número de bolas retiradas foi ímpar, há probabilidade zero associada a um empate no número de cores das bolas. Assim, as duas probabilidades anteriores têm de somar 1:


```
p(maisVermelhasQueAzuis, Ω_urna5bolas) + p(maisAzuisQueVermelhas, Ω_urna5bolas)
```




    Fraction(1, 1)



## 'Paradoxos' Probabilísticos

Existem problemas com probabilidades cuja solução é muito contra-intuítiva, o que costuma ser chamado informalmente de paradoxo. Mas é simplesmente o reflexo de, por vezes, ser difícil contar as respostas favoráveis e o espaço de resultados.

Façamos uma fábrica de predicados que produz uma função que valida se um conjunto de características pertence a um resultado do espaço amostral:


```
def serVerdade(*caracteristicas):
  return lambda resultado: all(caracteristica in resultado 
                               for caracteristica in caracteristicas)
```

E vamos generalizar a nossa definição de probabilidade para também aceitar predicados como eventos:


```
def p(evento, Ω):
  """
  evento : o conjunto de resultados a considerar (evento ⊆ Ω)
           ou um predicado que define este conjunto a partir de Ω
  Ω      : o conjunto que representa o espaço amostral
  """
  if callable(evento):              # se é um predicado,
    evento = condicional(evento, Ω) # recolher resultados que satisfazem predicado
  return Fraction(len(evento), len(Ω) )
```

### Filhos e Filhas


Por exemplo, assuma um casal com dois filhos. Isto corresponde ao seguinte espaço de soluções:


```
# minúscula é o mais novo, maiúscula é o mais velho (F:rapariga, M:rapaz)
Ω_doisFilhos = {'fF', 'fM', 'mF', 'mM'} 
```

+ Se o filho mais velho for um rapaz, qual é a probabilidade de terem dois rapazes?


```
p(serVerdade('M', 'm'), condicional(serVerdade('M'), Ω_doisFilhos))
```




    Fraction(1, 2)



Esta foi fácil. A probabilidade é de 50%, como esperado.

+ Sabe-se que pelo menos um dos filhos é rapaz. Qual é a probabilidade de serem os dois rapazes?

A tentação aqui é responder novamente 50%, mas...


```
def peloMenosUmRapaz(resultado): 
  return serVerdade('M')(resultado) or serVerdade('m')(resultado)

p(serVerdade('M', 'm'), condicional(peloMenosUmRapaz, Ω_doisFilhos))
```




    Fraction(1, 3)



...afinal a resposta certa é 1/3. O Python não se deixa enganar!

Agora vem a _pièce de résistance_:

+ Pelo menos um dos filhos é um rapaz que nasceu a uma Terça-feira. Qual é a probabilidade de ambos serem rapazes?

(what??? que importância pode isto ter?)

Bem, vamos ver... Representamos os dias da semana como inteiros de 1 a 7, desde Domingo a Sábado. Cada filho, rapaz ou rapariga, terá nascido a um destes dia de semana. Vamos incorporar esta informação na descrição do resultado. Por exemplo 'f1M3' significa que o filho mais novo é uma rapariga que nasceu Domingo, e o filho mais velho é um rapaz que nasceu Terça.

Para criar este espaço de soluções:


```
Ω_diasSemana = { str(f1)+str(d1)+str(f2)+str(d2) for f1 in 'fm' for d1 in range(1,8) 
                                                 for f2 in 'FM' for d2 in range(1,8) }

import random as rnd
rnd.sample(Ω_diasSemana, 7)
```




    ['m5M7', 'f2F2', 'm6F1', 'f3F6', 'm2M4', 'm4F6', 'm1F3']



Agora seguimos a regra do Senhor Laplace:


```
# o filho mais novo ou o filho mais velho nasceu numa 3a feira
def algumRapazNasceuTerca(resultado):
  return serVerdade('m3')(resultado) or serVerdade('M3')(resultado)

p(serVerdade('m', 'M'), condicional(algumRapazNasceuTerca, Ω_diasSemana))  
```




    Fraction(13, 27)



🤔 E não é que faz diferença saber se um deles nasceu na Terça-feira!? 

O código aponta-nos para uma pista. Esta diferença ocorre porque o espaço amostral é alterado com a nova informação.

### O Problema da Bela Adormecida

A resolução deste [problema](https://en.wikipedia.org/wiki/*Sleeping_Beauty_problem*) passa por definir quais os resultados possíveis, e calcular a probabilidade de caras condicionado ao facto da Bela estar acordada:


```
Ω_bela = {'cara 2a acordada',  'cara 3a aDormir',   # Caras 2a tem 25% do pmf
          'coroa 2a acordada', 'coroa 3a acordada'}

p(serVerdade('cara'), condicional(serVerdade('acordada'), Ω_bela))
```




    Fraction(1, 3)



Se preferirmos atribuir o dobro do peso à experiência de 2a feira, negligenciando a 3a-feira de caras:


```
Ω_bela = {'cara 2a acordada',  'cara 2a acordada 2', # Caras 2a tem 50% do pmf
          'coroa 2a acordada', 'coroa 3a acordada'}

p(serVerdade('cara'), condicional(serVerdade('acordada'), Ω_bela))
```




    Fraction(1, 2)



Ou seja, o paradoxo dissolve-se uma vez definido o espaço amostral.

### O Problema de Monty-Hall

Assumimos, sem perda de generalidade, que o concorrente abre sempre a porta 1.

O espaço de eventos é dado por três características:

+ Onde está o carro (na porta 1, 2, ou 3)

+ A estratégia do apresentador é escolher sempre a porta de menor número possível ou a de maior número possível

+ A porta que foi aberta, de acordo com a estratégia

Assim, temos o seguinte espaço de resultados:


```
Ω_monty = {'Carro1_min_Abre2', 
           'Carro1_max_Abre3',
           'Carro2_min_Abre3',
           'Carro2_max_Abre3',
           'Carro3_min_Abre2',
           'Carro3_max_Abre2',
           }
```

Se o concorrente abrir a porta 3, quais são as probabilidades do carro estar na porta 1 ou na porta 2?


```
p(serVerdade('Carro1'), condicional(serVerdade('Abre3'), Ω_monty))
```




    Fraction(1, 3)




```
p(serVerdade('Carro2'), condicional(serVerdade('Abre3'), Ω_monty))
```




    Fraction(2, 3)



Uma outra interpretação é que o apresentador abre uma porta aleatória, podendo eventualmente mostrar-nos o carro.


```
Ω_monty = {'Carro1_Abre2_Cabra', 
           'Carro1_Abre3_Cabra',
           'Carro2_Abre2_Carro',
           'Carro2_Abre3_Cabra',
           'Carro3_Abre2_Cabra',
           'Carro3_Abre3_Carro',
           }
```

Qual é a probabilidade do carro estar na porta 1 ou 2, condicional ao facto do apresentador ter aberto a porta 3 e estar lá uma cabra?


```
p(serVerdade('Carro1'), condicional(serVerdade('Abre3','Cabra'), Ω_monty))
```




    Fraction(1, 2)




```
p(serVerdade('Carro2'), condicional(serVerdade('Abre3','Cabra'), Ω_monty))
```




    Fraction(1, 2)



O problema desta interpretação é que no _show_ real, nunca o apresentador abriu uma porta com um carro.

**Exercícios**

+ No jogo de Poker qual é a probabilidade de receber uma mão inicial com trio? E de receber um *flush*? (um *flush* são cinco cartas do mesmo naipe)

+ Numa urna com 5 bolas azuis, 4 bolas vermelhas e 3 bolas amarelas, tirámos 4 bolas. Qual é a probabilidade de:

  + ter pelo menos 1 bola azul, 1 vermelha e 1 amarela?
  + ter uma maioria de bolas azuis? 
  + ter duas bolas de uma cor, e as outras duas bolas de outra cor?

+ Na tal família dos dois filhos, pelo menos um dos filhos é um rapaz que nasceu a 29 de Fevereiro. Qual é a probabilidade de ambos serem rapazes? dica: pensem em períodos de 4 anos.



---



## Distribuições


Vamos salientar uma parte do texto do Laplace:

> A probabilidade de um evento é o rácio do número de casos favoráveis a ele e do número de todos os casos possíveis, **quando nada nos leva a esperar que um dos casos ocorra mais frequentemente que qualquer outro, o que os torna, para nós, todos igualmente possíveis**.

Esta definição, e o código anterior que nela se inspira, assumem que as probabilidades de ocorrência dos vários resultados são todas iguais, ou seja, são *equiprováveis*.

Mas o que acontece se isso não for verdade? Um dado pode estar viciado e sair o número 6 mais vezes do que seria esperado pela asserção anterior.

Convinha ter uma função para atribuir a cada resultado do espaço de resultados $\Omega$ uma proporção que, para cada resultado possível, nos informe quão comum é de ocorrer numa experiência aleatória. 

Uma restrição que vamos obrigar a função a seguir é que a soma das proporções para todos os resultados terá de ser 1, o que nos leva a interpretar as proporções como probabilidades.

Estas funções designam-se por **distribuições**.

Este tópico será estudado na disciplina do 2º semestre, Introdução às Probabilidades e Estatística. Aqui vamos ficar apenas pela rama deste importante assunto. 

Uma forma de definir distribuições é dar uma lista com os vários resultados, respeitando as proporções de cada resultado (um resultado mais comum aparece mais vezes).

No nosso caso, vamos representar uma distribuição por um dicionário. Cada resultado será uma chave, sendo o valor a respetiva proporção desse resultado em relação à lista dos resultados dados.


```
# função auxiliar: obriga que as proporções somem 1
def normaliza(dist):
  size = 0
  for val in dist.values():
    size = size + val
  for k,v in dist.items():
    dist[k] = Fraction(v, size)
  return dist
  
# cria uma distribuição baseada numa lista com as proporções 
# dos resultados possíveis
def criaDistribuicao(resultados):
  dist = {}
  for res in resultados:
    dist[res] = dist.get(res,0) + 1
  return normaliza(dist)
```

Por exemplo, para um dado equilibrado:


```
d1 = criaDistribuicao([1,2,3,4,5,6])
d1
```




    {1: Fraction(1, 6),
     2: Fraction(1, 6),
     3: Fraction(1, 6),
     4: Fraction(1, 6),
     5: Fraction(1, 6),
     6: Fraction(1, 6)}



Como cada resultado apareceu apenas uma vez, significa que os resultados são equiprováveis.

Vamos criar uma função para visualizar as distribuições como gráficos de barras:


```
def toStr(x):
  if type(x) is tuple:
    return ''.join(map(str, x))
  else:
    return str(x)

def visualizar(dist, col='b', alpha=1, ylim=(0,1)):
  """
  dist  : a distribuição a mostrar
  col   : a cor a usar, ref https://matplotlib.org/2.0.2/api/colors_api.html
  alpha : nível de transparência, de 0 invisível a 1 sólido
  ylim  : intervalo do eixo dos yy 
  """
  xs = [ toStr(x) for x,_ in dist.items() ]
  ys = [ y        for _,y in dist.items() ]
  plt.ylim(ylim)
  plt.bar(xs, ys, width=0.9, color=col, alpha=alpha)
```


```
visualizar(d1, ylim=(0,0.3))
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_95_0.png)
    


Vamos comparar o nosso dado equilibrado com um dado viciado:


```
d2 = criaDistribuicao([1,2,3,4,5,6,6]) # o 6 é um pouco mais provável

visualizar(d2, ylim=(0,0.3))
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_97_0.png)
    


Podem reparar que para a probabilidade do 6 crescer, todos os outros resultados tiveram de descer. O nosso 'orçamento' probabilístico é constante (a soma tem sempre de dar 1).

Podemos comparar as probabilidades do evento de sair 6 nas duas distribuições:


```
print(d1[6])
print(d2[6])
```

    1/6
    2/7
    

Um dos conceitos que falaram no Secundário foi o de probabilidade conjunta $p(A,B)$ que é a probabilidade de ocorrer o evento $A$ e também o evento $B$.

Se eu quiser lidar com lançamentos de dois dados equilibrados, posso pensar na probabilidade conjunta deste resultado. 

Como fazer? Temos de considerar um novo espaço de resultados, que é o produto cartesiano de dois espaços de resultados $\Omega_{dado}$


```
Ω_2dados = [ (res1,res2) for res1 in Ω_dado for res2 in Ω_dado]
rnd.sample(Ω_2dados, 8)
```




    [(4, 6), (1, 3), (6, 1), (1, 5), (3, 3), (1, 6), (3, 2), (4, 2)]



Agora passamos este novo espaço de resultados para a função `makeDistribution`:


```
d3 = criaDistribuicao(Ω_2dados)

plt.figure(figsize=(20,5))
visualizar(d3, ylim=(0,0.04))
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_103_0.png)
    


Normalmente queremos algo mais concreto, por exemplo, a distribuição de somar os lançamentos de dois dados. Assim, alguns dos resultados vão ser considerados iguais, reduzindo o tamanho do espaço de resultados (por exemplo, no contexto de somar dois dados, os resultados `(3,2)` e `(1,4)` serão considerados iguais).

A seguinte função trata disso. Para além de receber as duas distribuições a juntar, recebe ainda uma função $f$ que calcula o resultado $f(x,y)$ a partir do resultado $x$ da primeira distribuição, e o resultado $y$ da segunda distribuição.


```
def juntar(dist1, dist2, f=lambda res1,res2:'{}{}'.format(res1,res2) ):
  dist = {}
  for k1,v1 in dist1.items():
    for k2,v2 in dist2.items():
      dist[f(k1,k2)] = dist.get(f(k1,k2),0) + v1*v2
  return dist
```

Vamos então calcular a distribuição da soma de dois dados:


```
d4 = juntar(d1, d1, lambda res1,res2:res1+res2)
visualizar(d4, ylim=(0,0.2))
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_107_0.png)
    


Podemos calcular facilmente a distribuição de multiplicar o lançamento de dois dados:


```
d5 = juntar(d1, d1, lambda res1,res2:res1*res2)
visualizar(d5, ylim=(0,0.2))
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_109_0.png)
    


E se fosse a soma de dois dados viciados?


```
d4a = juntar(d2, d2, lambda res1,res2:res1+res2)
visualizar(d4, col='orange')   # soma de dois dados equilibrados (para comparação)
visualizar(d4a, ylim=(0,0.2))  # soma de dois dados viciados
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_111_0.png)
    


Reparem como as probabilidades das somas menores reduzem-se para a distribuição de dois dados viciados, pois o resultado 6 ocorre com maior frequência.

Também conseguimos lidar com distribuições associadas a probabilidades condicionais $P(A|B)$, a probabilidade do evento $A$ sabendo que o evento $B$ ocorreu.

Para tal podemos ir aos resultados de $A$ filtrar os resultados incompatíveis com $B$ e normalizar as proporções para termos novamente uma distribuição.


```
def filtrar(dist, p):
  """
  dist : a distribuição original
  p    : o predicado a satisfazer, corresponde ao evento B em p(A|B)
  """
  newDist = {}
  for k,v in dist.items():
    if p(k):
      newDist[k] = v
  return normaliza(newDist)
```

Por exemplo, qual é a distribuição de multiplicar dois dados, sabendo que o resultado foi maior que 10?


```
d6 = filtrar(d5, lambda res:res>10)
visualizar(d6, ylim=(0,0.25))
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_116_0.png)
    


## Caras e Coroas

Outro exemplo clássico das probabilidades é o lançamento de uma moeda. Neste caso existem apenas dois resultados possíveis, ou sai Cara (*Heads*) ou sai Coroa (*Tails*).


```
dCoin = criaDistribuicao(['H','T'])

visualizar(dCoin)
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_118_0.png)
    


Vamos definir a distribuição correspondente a quatro lançamentos de moedas:


```
d2Coins = juntar(dCoin, dCoin)
d4Coins = juntar(d2Coins, d2Coins)

plt.figure(figsize=(20,5))
visualizar(d4Coins, ylim=(0,0.075))
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_120_0.png)
    


E se quisermos saber a distribuição por número de *Heads* obtidas?


```
# Criar nova lista de resultados com apenas o número de Caras, por ex, HHTH -> 3
# Assumimos aqui que cada resultado do espaço anterior é equiprovável
res = sorted([ res.count('H') for res in d4Coins.keys() ])
dBinom = criaDistribuicao(res)

visualizar(dBinom, ylim=(0,0.4))
```


    
![png](Aplica%C3%A7%C3%A3o_Probabilidades_files/Aplica%C3%A7%C3%A3o_Probabilidades_122_0.png)
    


Este tipo de perguntas gera o que é conhecido como distribuição Binomial que vocês irão aprender na disciplina de Probabilidades.

### Problema de Samuel Pepys

Qual dos eventos é mais provável?

+ Seis dados são lançados e sai pelo menos um 6

+ Doze dados são lançados e sai pelo menos dois 6

+ Dezoito dados são lançados e sai pelo menos três 6

Para tal, vamos definir uma função que junta $n$ distribuições iguais


```
def juntar_(n, dist):
  """ junta n distribuições iguais numa só """
  if n==1:
    return dist
  return juntar(dist, juntar_(n-1, dist))
```

E, para simplificar o espaço amostral, consideramos apenas os eventos $6$ e não-$6$:


```
d6 = criaDistribuicao(['-','-','-','-','-',6])
```

A probabilidade de seis dados são lançados e sai pelo menos um 6:


```
dist_prob1 = juntar_(6, d6) 
float(sum(v for k,v in dist_prob1.items() if k.count('6')>=1))
```




    0.6651020233196159



A probabilidade de doze dados são lançados e sai pelo menos dois 6:


```
dist_prob2 = juntar_(12, d6) 
float(sum(v for k,v in dist_prob2.items() if k.count('6')>=2))
```




    0.6186673737323087



A probabilidade de dezoito dados são lançados e sai pelo menos três 6:


```
dist_prob3 = juntar_(18, d6) 
float(sum(v for k,v in dist_prob3.items() if k.count('6')>=3))
```




    0.5973456859477232





---



## O Paradoxo do 2º Ás

> You’re watching four statisticians play bridge. After a hand is dealt, you choose a player and ask, “Do you have at least one ace?” If she answers yes, the chance that she’s holding more than one ace is 5359/14498, which is less than 37 percent.
> 
> On a later hand, you choose a player and ask, “Do you have the ace of spades?” Strangely, if she says yes now the chance that she has more than one ace is 11686/20825, which is more than 56 percent.
>
> Why does specifying the suit of her ace improve the odds that she’s holding more than one ace? Because, though a smaller number of potential hands contain that particular ace, a greater proportion of those hands contain a second ace. It’s counterintuitive, but it’s true. https://www.futilitycloset.com/2012/10/17/the-paradox-of-the-second-ace-2/

Como há ${52 \choose 13} = 635.013.559.600$ mãos iniciais do Bridge, não podemos esperar que as funções anteriores sejam capazes de enumerá-las em tempo razoável.

Assim, usamos as ferramentas da Combinatória para calcular as probabilidades de ter, numa mão aleatória, zero, uns ou mais ases:


```
from math import comb
from itertools import combinations

def make_d_ace():
  d_ace = {'-': Fraction(comb(48,13)) / Fraction(comb(52,13))} # zero aces
  for n_aces in range(1,5):
    for ace in combinations(['♤','♡','♢','♧'], n_aces):
      d_ace[''.join(ace)] = Fraction(comb(48,13-n_aces)) / Fraction(comb(52,13))
  assert sum(v for k,v in d_ace.items()) == 1 
  return d_ace
```


```
d_ace = make_d_ace()
d_ace
```




    {'-': Fraction(6327, 20825),
     '♤': Fraction(9139, 83300),
     '♡': Fraction(9139, 83300),
     '♢': Fraction(9139, 83300),
     '♧': Fraction(9139, 83300),
     '♤♡': Fraction(741, 20825),
     '♤♢': Fraction(741, 20825),
     '♤♧': Fraction(741, 20825),
     '♡♢': Fraction(741, 20825),
     '♡♧': Fraction(741, 20825),
     '♢♧': Fraction(741, 20825),
     '♤♡♢': Fraction(429, 41650),
     '♤♡♧': Fraction(429, 41650),
     '♤♢♧': Fraction(429, 41650),
     '♡♢♧': Fraction(429, 41650),
     '♤♡♢♧': Fraction(11, 4165)}



O problema descrita pergunta por probabilidades condicionadas, $$Pr(A | B) = \frac{Pr(A,B)}{Pr(B)}$$

A primeira probabilidade é dada por $$Pr(\text{2+ ases} | \text{1 ás}) = \frac{Pr(\text{2+ ases}, \text{1 ás})}{Pr(\text{1 ás})}= \frac{Pr(\text{2+ ases})}{Pr(\text{1 ás})}$$

Em Python,


```
p_at_least_one_ace = 1 - d_ace['-']

p_at_least_two_aces = sum(v for k,v in d_ace.items() if len(k) > 1)

p_at_least_two_aces / p_at_least_one_ace 
```




    Fraction(5359, 14498)



Já a segunda probabilidade é,

$$Pr(\text{2+ ases} | \text{inclui ♤}) = \frac{Pr(\text{2+ ases}, \text{inclui ♤})}{Pr(\text{inclui ♤})}$$

Em Python,


```
p_ace_spades = sum(v for k,v in d_ace.items() if k.count('♤'))

p_at_least_two_aces_and_spades = sum(v for k,v in d_ace.items() 
                                       if len(k)>1 and k.count('♤'))

p_at_least_two_aces_and_spades / p_ace_spades
```




    Fraction(11686, 20825)





---



**Exercícios**

+ Defina a distribuição de um dado equilibrado de 12 faces 

+ Defina a distribuição de somar um dado de 6 faces com um dado de 12 faces

+ Defina a distribuição da diferença entre os resultados do lançamento de dois dados de 6 faces

+ Condicione a distribuição acima sabendo que a diferença foi maior que 1.

+ A função `criaDistribuicao` recebe uma lista de resultados para calcular as respetivas probabilidades. Mas se os valores precisarem de muita precisão podemos ter problemas. Por exemplo, para representar uma distribuição onde a probabilidade de sair Cara é 0.4843 teríamos de criar uma lista com 10 mil elementos. 
  + Defina uma nova função `criaDistribuicaoPp` que recebe os resultados e respetivas proporções num dicionário, devolvendo a respetiva distribuição. Para o exemplo referido, invocaríamos `criaDistribuicaoPp( {'H': 4843, 'T': 5157} )`

nota: para a distribuição da diferença, pode ser necessário ordenar os vários valores para que o histograma faça mais sentido. A próxima função ordena as chaves do respetivo dicionário:


```
def ordena(dist):
  chavesOrdenadas = sorted(dist.keys())
  return { chave:dist[chave] for chave in chavesOrdenadas }
```



---



## Referências

+ Peter Norvig, [A Concrete Introduction to Probability (using Python)](https://github.com/norvig/pytudes/blob/master/ipynb/Probability.ipynb), 2016

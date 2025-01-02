info: http://dmir.inesc-id.pt/project/SentiLex-PT_02

O que posso fazer com o SentiLex-PT?

O SentiLex-PT � um recurso especialmente importante para quem se interesse por aplica��es em extra��o e classifica��o de sentimentos e opini�es em portugu�s, em particular as que envolvam entidades humanas.

Qual � o formato do SentiLex-PT?

O SentiLex-PT encontra-se dispon�vel em dois ficheiros de texto distintos:

SentiLex-lem-PT02.txt
    Cada linha inclui informa��o sobre: 

    Lema (convencionalmente a forma masculina do singular para os adjetivos, a forma singular para os nomes que flexionam em n�mero e a forma infinitiva para os verbos e express�es idiom�ticas),
    Categoria gramatical (ADJ(etivo), N(ome), V(erbo) and IDIOM(a)), e
    Atributos de sentimento:
        polaridade(POL), a qual pode ser positiva (1), negativa (-1) ou neutra (0);
        alvo da polaridade (TG), o qual corresponde a um nome de tipo humano (HUM), com fun��o de sujeito (N0) e/ou complemento (N1);
        classifica��o de polaridade (ANOT), a qual pode ter sido manualmente (MAN) ou automaticamente atribu�da, pela ferramenta Judgment Analysis Lexicon Classifier (JALC), desenvolvida pela equipa do projeto. 

Algumas entradas incluem um c�digo adicional (REV), o qual se refere a observa��es espec�ficas do anotador. Neste momento, � poss�vel encontrar as seguintes anota��es:

    REV=AMB, associada a entradas cujo predicador � amb�guo com outra express�o que apresenta uma polaridade diferente, e
    REV:POL, associada a entradas cujo valor de polaridade inicialmente atribu�do no SentiLex-PT01 foi revisto. 

Abaixo, apresentam-se cinco entradas do SentiLex-lem-PT02.txt:

aberra��o.PoS=N;TG=HUM:N0;POL:N0=-1;ANOT=MAN
bonito.PoS=Adj;TG=HUM:N0;POL:N0=1;ANOT=MAN
castigado;PoS=Adj;TG=HUM:N0;POL:N0=-1;ANOT=JALC
estimado.PoS=Adj;TG=HUM:N0;POL:N0=1;ANOT=JALC;REV=AMB
enganar.PoS=V;TG=HUM:N0:N1;POL:N0=-1;POL:N1=0;ANOT=MAN
engolir em seco.PoS=IDIOM;TG=HUM:N0;POL:N0=-1;ANOT=MAN

SentiLex-flex-PT02.txt 
    Em cada linha, as formas flexionadas est�o associadas ao respetivo lema. Al�m das informa��es descritas no dicion�rio de lemas, neste formato as entradas adjetivais e nominais cont�m informa��o sobre a flex�o (FLEX) em g�nero(masculino (m) ou feminino (f)) e n�mero (singular (s) ou plural (p)). Os atributos morfol�gicos associados aos verbos e express�es idiom�ticas incluem informa��o de tempo, pessoa e n�mero. As formas flexionadas dos verbos e respetivos atributos foram automaticamente extra�dos do dicion�rio LABEL-LEX-sw. 


Abaixo, apresentam-se dez entradas do SentiLex-flex-PT02.txt:

aberra��o,aberra��o.PoS=N;FLEX=fs;TG=HUM:N0;POL:N0=-1;ANOT=MAN
bonita,bonito.PoS=Adj;FLEX=fs;TG=HUM:N0;POL:N0=1;ANOT=MAN
bonitas,bonito.PoS=Adj;FLEX=fp;TG=HUM:N0;POL:N0=1;ANOT=MAN
bonito,bonito.PoS=Adj;FLEX=ms;TG=HUM:N0;POL:N0=1;ANOT=MAN
bonitos,bonito.PoS=Adj;FLEX=mp;TG=HUM:N0;POL:N0=1;ANOT=MAN
engoliste em seco,engolir em seco.PoS=IDIOM;Flex=J2p|J2s;TG=HUM:N0;POL:N0=-1;ANOT=MAN
engolistes em seco,engolir em seco.PoS=IDIOM;Flex=J2p;TG=HUM:N0;POL:N0=-1;ANOT=MAN
engoliu em seco,engolir em seco.PoS=IDIOM;Flex=J4s|P3s;TG=HUM:N0;POL:N0=-1;ANOT=MAN
engulam em seco,engolir em seco.PoS=IDIOM;Flex=Y4p|S4p|S3p;TG=HUM:N0;POL:N0=-1;ANOT=MAN
engulamos em seco,engolir em seco.PoS=IDIOM;Flex=Y1p|S1p;TG=HUM:N0;POL:N0=-1;ANOT=MAN


info: http://dmir.inesc-id.pt/project/SentiLex-PT_02

O que posso fazer com o SentiLex-PT?

O SentiLex-PT é um recurso especialmente importante para quem se interesse por aplicações em extração e classificação de sentimentos e opiniões em português, em particular as que envolvam entidades humanas.

Qual é o formato do SentiLex-PT?

O SentiLex-PT encontra-se disponível em dois ficheiros de texto distintos:

SentiLex-lem-PT02.txt
    Cada linha inclui informação sobre: 

    Lema (convencionalmente a forma masculina do singular para os adjetivos, a forma singular para os nomes que flexionam em número e a forma infinitiva para os verbos e expressões idiomáticas),
    Categoria gramatical (ADJ(etivo), N(ome), V(erbo) and IDIOM(a)), e
    Atributos de sentimento:
        polaridade(POL), a qual pode ser positiva (1), negativa (-1) ou neutra (0);
        alvo da polaridade (TG), o qual corresponde a um nome de tipo humano (HUM), com função de sujeito (N0) e/ou complemento (N1);
        classificação de polaridade (ANOT), a qual pode ter sido manualmente (MAN) ou automaticamente atribuída, pela ferramenta Judgment Analysis Lexicon Classifier (JALC), desenvolvida pela equipa do projeto. 

Algumas entradas incluem um código adicional (REV), o qual se refere a observações específicas do anotador. Neste momento, é possível encontrar as seguintes anotações:

    REV=AMB, associada a entradas cujo predicador é ambíguo com outra expressão que apresenta uma polaridade diferente, e
    REV:POL, associada a entradas cujo valor de polaridade inicialmente atribuído no SentiLex-PT01 foi revisto. 

Abaixo, apresentam-se cinco entradas do SentiLex-lem-PT02.txt:

aberração.PoS=N;TG=HUM:N0;POL:N0=-1;ANOT=MAN
bonito.PoS=Adj;TG=HUM:N0;POL:N0=1;ANOT=MAN
castigado;PoS=Adj;TG=HUM:N0;POL:N0=-1;ANOT=JALC
estimado.PoS=Adj;TG=HUM:N0;POL:N0=1;ANOT=JALC;REV=AMB
enganar.PoS=V;TG=HUM:N0:N1;POL:N0=-1;POL:N1=0;ANOT=MAN
engolir em seco.PoS=IDIOM;TG=HUM:N0;POL:N0=-1;ANOT=MAN

SentiLex-flex-PT02.txt 
    Em cada linha, as formas flexionadas estão associadas ao respetivo lema. Além das informações descritas no dicionário de lemas, neste formato as entradas adjetivais e nominais contêm informação sobre a flexão (FLEX) em género(masculino (m) ou feminino (f)) e número (singular (s) ou plural (p)). Os atributos morfológicos associados aos verbos e expressões idiomáticas incluem informação de tempo, pessoa e número. As formas flexionadas dos verbos e respetivos atributos foram automaticamente extraídos do dicionário LABEL-LEX-sw. 


Abaixo, apresentam-se dez entradas do SentiLex-flex-PT02.txt:

aberração,aberração.PoS=N;FLEX=fs;TG=HUM:N0;POL:N0=-1;ANOT=MAN
bonita,bonito.PoS=Adj;FLEX=fs;TG=HUM:N0;POL:N0=1;ANOT=MAN
bonitas,bonito.PoS=Adj;FLEX=fp;TG=HUM:N0;POL:N0=1;ANOT=MAN
bonito,bonito.PoS=Adj;FLEX=ms;TG=HUM:N0;POL:N0=1;ANOT=MAN
bonitos,bonito.PoS=Adj;FLEX=mp;TG=HUM:N0;POL:N0=1;ANOT=MAN
engoliste em seco,engolir em seco.PoS=IDIOM;Flex=J2p|J2s;TG=HUM:N0;POL:N0=-1;ANOT=MAN
engolistes em seco,engolir em seco.PoS=IDIOM;Flex=J2p;TG=HUM:N0;POL:N0=-1;ANOT=MAN
engoliu em seco,engolir em seco.PoS=IDIOM;Flex=J4s|P3s;TG=HUM:N0;POL:N0=-1;ANOT=MAN
engulam em seco,engolir em seco.PoS=IDIOM;Flex=Y4p|S4p|S3p;TG=HUM:N0;POL:N0=-1;ANOT=MAN
engulamos em seco,engolir em seco.PoS=IDIOM;Flex=Y1p|S1p;TG=HUM:N0;POL:N0=-1;ANOT=MAN


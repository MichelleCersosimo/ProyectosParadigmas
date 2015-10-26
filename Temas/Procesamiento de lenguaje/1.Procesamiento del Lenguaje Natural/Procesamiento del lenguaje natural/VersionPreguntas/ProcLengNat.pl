%%%%%%
% Definicion de Gramaticas (DCG): Concordandia Genero y Numero
% True: oracion([kevin, y, valery,comen,helado,en,la, cocina],[]).
% False: oracion([kevin, y, valery,comen,helado,hacia, cuchara],[]).
%%%
oracion --> sintagmaNominal(G,N),sintagmaVerbal(G,N).  %G: genero y N: numero

sintagmaNominal(G,N)--> nombre_personal(G);sustantivo(G,N).
sintagmaNominal(G,N)--> articulo(G,N),sustantivo(G,N).
sintagmaNominal(G,N)--> sustantivo(G,N), adjetivo(G,N).
sintagmaNominal(G,N)--> articulo(G,N),adjetivo(G,N),sustantivo(G,N).
sintagmaNominal(G,N)--> nombre_personal(_),conjuncion,sintagmaNominal(G,N).
sintagmaNominal(G,N)--> articulo(G,N),sustantivo(G,N),conjuncion,sintagmaNominal(G,N).

articulo(f,s)--> [la];[una].
articulo(f,p)--> [las];[unas].
articulo(m,s)--> [el];[un].
articulo(m,p)--> [los];[unos].

sustantivo(G,N)--> sustantivo1(G,N); sustantivo2(G,N);sustantivo3(G,N);sustantivo4(G,N);sustantivo5(G,N);sustantivo6(G,N); sustantivo7(G,N);sustantivo8(G,N);sustantivo9(G,N).

sustantivo1(m,s)--> [helado];[chocolate].
sustantivo8(m,p)--> [helados];[chocolates].
sustantivo2(m,s)--> [carro].
sustantivo6(m,p)--> [carros].
sustantivo3(f,s)--> [fresa].
sustantivo7(f,s)--> [camisa];[cuchara].
sustantivo4(f,s)--> [cocina].
sustantivo5(f,p)--> [camisas];[cucharas].
sustantivo9(f,p)--> [fresas].

nombre_personal(f)--> [valery];[ana].
nombre_personal(m)--> [carlos];[kevin].

adjetivo(m,s)--> [rico].
adjetivo(m,p)--> [ricos].
adjetivo(f,s)--> [linda].
adjetivo(f,p)--> [lindas].

conjuncion--> [y];[o].

%%
% Sintagma Verbal: Verbo + Predicado
% Conconrdandia de Verbo y Preposiciones
%%

sintagmaVerbal(G,N)-->(verboS(G,N));(verboE(G,N)).
sintagmaVerbal(G,N)-->(verboS(G,N),predicadoS);(verboE(G,N),predicadoE).

verboS(G,N)--> verboS1(G,N);verboS2(G,N).
verboE(G,N)--> verboE1(G,N);verboE2(G,N).
verboS1(_,s)--> [come].
verboS1(_,p)--> [comen].
verboS2(_,s)--> [tiene].
verboS2(_,p)--> [tienen].
verboE1(_,s)--> [corre].
verboE1(_,p)--> [corren].
verboE2(_,s)--> [camina].
verboE2(_,p)--> [caminan].

predicado_directo--> sintagmaNominal(_,_).

%ana y carlos corren
%ana y carlos comen un helado rico
%kevin y valery comen helado de fresa
%kevin y valery comen helado con cuchara
%carlos y ana tienen una camisa linda
predicadoS--> predicado_directo.
predicadoS--> predicado_indirectoS.
predicadoS--> predicado_directo,predicado_indirectoS.
predicado_indirectoS--> sintagmaNominal(_,_), preposicionS, sintagmaNominal(_,_).
%kevin y valery corren en la cocina
%Kevin y ana corren desde la cocina
%carlos y valery caminan hacia los carros
predicadoE--> predicado_indirectoE.
predicado_indirectoE-->preposicionE, sintagmaNominal(_,_).

preposicionS--> [de];[con];[en].
preposicionE--> [desde];[hacia];[en].

%%%
%
% Ejemplos oraciones simples:
%
% ana y carlos corren
% ana y carlos comen un helado rico
%
% Ejemplos con preposiones de referencia:
%
% kevin y valery comen helado de fresa
% kevin y valery comen helado con cuchara
% carlos y ana tienen una camisa linda
%
% Ejemplos con preposiones de espaciales:
% kevin y valery corren en la cocina
% Kevin y ana corren desde la cocina
% carlos y valery caminan hacia los carros
%
%%%
% preguntar([que,tiene,valery,X],[]).
% preguntar([quien,come,helado,X],[]).
% preguntar([donde,come,helado,valery,X],[]).
%%%
preguntar--> (tipo,quien);(tipo2,donde);(tipo3,que).
tipo--> [quien].
tipo2--> [donde].
tipo3--> [que].

quien--> (sintagmaVerbal(_,s),sustantivo(_,_),nombre_personal(_));(sintagmaVerbal(_,s),nombre_personal(_)).

donde--> sintagmaVerbal(_,s),((nombre_personal(_)) ; (nombre_personal(_),conjuncion,nombre_personal(_))),(sustantivo2(_,_);sustantivo4(_,_)).

que--> (verboS1(_,s),((nombre_personal(_));(nombre_personal(_),conjuncion,nombre_personal(_))),(sustantivo8(_,_);sustantivo9(_,_)));(verboS2(_,s),((nombre_personal(_));(nombre_personal(_),conjuncion,nombre_personal(_))),(sustantivo8(_,_);sustantivo5(_,_))).


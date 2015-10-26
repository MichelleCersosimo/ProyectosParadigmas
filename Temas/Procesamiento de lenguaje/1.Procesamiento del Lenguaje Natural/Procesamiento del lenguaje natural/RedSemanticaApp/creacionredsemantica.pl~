%%%%%%
% Definicion de Gramaticas (DCG): Concordandia Genero y Numero
% True: oracion([kevin, y, valery,comen,helado,en,la, cocina],[]).
% False: oracion([kevin, y, valery,comen,helado,hacia, cuchara],[]).
%
% Para crear la red semantica se hace un analisis desde las hojas para
% identificar cada uno de los elementos que se van a agregar a la red.
% Despues se identifica la funcion de cada uno dentro el texto para
% mapearlo a la respectiva red semantica.
% Ej:
% La oracion "kevin y valery corren hacia la cocina linda" y "kevin come
% un rico helado" se debería mapear a:
% kevin-suj>corren
% valery-suj>corren
% corren-hacia>cocina
% cocina-adj>linda
% kevin-suj>come
% come-obj>helado
% helado-adj>rico
%
% Durante el tiempo de ejecucion se veran varias clausulas repetidas en
% pantalla debido a la naturaleza de prolog de tratar de aplicar las
% veces que pueda una misma regla.
%

oracion --> sintagmaNominal(G,N,E1),sintagmaVerbal(G,N,E2),{agregarArco(E1,E2,suj)}.  %G: genero y N: numero

sintagmaNominal(G,N,E)--> nombre_personal(G,E);sustantivo(G,N,E).
sintagmaNominal(G,N,E)--> articulo(G,N),sustantivo(G,N,E).
sintagmaNominal(G,N,E1)--> sustantivo(G,N,E1), adjetivo(G,N,E2),{agregarArco(E1,E2,adj)}.
sintagmaNominal(G,N,E1)--> articulo(G,N),sustantivo(G,N,E1), adjetivo(G,N,E2),{agregarArco(E1,E2,adj)}.
sintagmaNominal(m,p,E1|E2)--> nombre_personal(_,E1),conjuncion,sintagmaNominal(_,_,E2).
sintagmaNominal(m,p,E1|E2)--> articulo(G,N),sustantivo(G,N,E1),conjuncion,sintagmaNominal(_,_,E2).

:-dynamic arco/3.

agregarArco(E1,E2|R,P):-
	assert(arco(E1,E2,p)),
	writef('\n'),
	print(E1),
	print('-'),
	print(P),
	print('>'),
	print(E2),
	agregarArco(R,E2,p).


agregarArco(E1|R,E2,P):-
	assert(arco(E1,E2,p)),
	writef('\n'),
	print(E1),
	print('-'),
	print(P),
	print('>'),
	print(E2),
	agregarArco(R,E2,P).

agregarArco(E1,E2,P):-
	atom(E1),atom(E2),
	assert(arco(E1,E2,p)),
	writef('\n'),
	print(E1),
	print('-'),
	print(P),
	print('>'),
	print(E2).

articulo(f,s)--> [la];[una].
articulo(f,p)--> [las];[unas].
articulo(m,s)--> [el];[un].
articulo(m,p)--> [los];[unos].

sustantivo(m,s,E)--> [helado],{ E =  'helado'};
                     [chocolate],{E =  'chocolate'};
		     [carro],{ E =  'carro'}.
sustantivo(m,p,E)--> [helados],{ E =  'helados'};
                     [chocolates],{E =  'chocolates'};
		     [carros],{E =  'carros'}.
sustantivo(f,s,E)--> [camisa],{E =  'camisa'};
                     [fresa],{E =  'fresa'};
		     [cuchara],{ E =  'cuchara'};
		     [cocina],{ E =  'cocina'}.
sustantivo(f,p,E)--> [camisas],{E =  'cocina'};
                     [fresas],{E =  'cocina'};
		     [cucharas],{ E =  'cocina'}.
nombre_personal(f,E)--> [valery],{E =  'valery'};
                        [ana],{E = 'ana'}.
nombre_personal(m,E)--> [carlos],{E = 'carlos'};
                        [kevin],{E = 'kevin'}.
adjetivo(m,s,E)--> [rico],{E = 'rico'}.
adjetivo(m,p,E)--> [ricos],{E = 'rico'}.
adjetivo(f,s,E)--> [linda],{E = 'linda'}.
adjetivo(f,p,E)--> [lindas],{E = 'lindas'}.

conjuncion--> [y];[o].

%%
% Sintagma Verbal: Verbo + Predicado
% Conconrdandia de Verbo y Preposiciones
%%

sintagmaVerbal(G,N,E)-->(verboS(G,N,E));(verboE(G,N,E)).
sintagmaVerbal(G,N,E1)-->(verboS(G,N,E1),predicadoS(E2)),{agregarArcosPredicadoS(E1,E2)}.
sintagmaVerbal(G,N,E1)-->(verboE(G,N,E1),predicadoE(E2)),{agregarArcosPredicadoE(E1,E2)}.

agregarArcosPredicadoS(V,E1|P|E2):-
	agregarArco(V,E1,obj),
	agregarArco(V,E2,P).

agregarArcosPredicadoS(V,E1):-
	agregarArco(V,E1,obj).


agregarArcosPredicadoE(V,P|E1):-
	agregarArco(V,E1,P).


verboS(_,s,E)--> [come],{E =  'come'};
                 [tiene],{E =  'tiene'}.
verboS(_,p,E)--> [comen],{E =  'comen'};
                 [tienen],{E =  'tienen'}.
verboE(_,s,E)--> [corre],{E =  'corre'};
                 [camina],{E =  'camina'}.
verboE(_,p,E)--> [corren],{E =  'corren'};
                 [caminan],{E =  'caminan'}.

predicado_directo(E)--> sintagmaNominal(_,_,E).

%ana y carlos comen
%ana y carlos comen un helado rico
%kevin y valery comen helado de fresa
%kevin y valery comen helado con cuchara
%carlos y ana tienen una camisa linda
predicadoS(E)--> predicado_directo(E).
predicadoS(E)--> predicado_indirectoS(E).
predicadoS(E1|E2)--> predicado_directo(E1),predicado_indirectoS(E2).
predicado_indirectoS(E1|P|E2)--> sintagmaNominal(_,_,E1), preposicionS(P), sintagmaNominal(_,_,E2).
%kevin y valery corren en la cocina
%Kevin y ana corren desde la cocina
%carlos y valery caminan hacia los carros
predicadoE(E)--> predicado_indirectoE(E).
predicado_indirectoE(P|E2)-->preposicionE(P), sintagmaNominal(_,_,E2).

preposicionS(E)--> [de],{ E =  'de'};
                   [con],{ E =  'con'};
		   [en],{ E =  'en'}.
preposicionE(E)--> [desde],{ E =  'desde'};
                   [hacia],{ E =  'hacia'};
		   [en],{ E =  'en'}.















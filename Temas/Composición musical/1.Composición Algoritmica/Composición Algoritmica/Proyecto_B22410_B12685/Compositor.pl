% ------------------------------------------------------------------------------
%
% UCR - Facultad de Ingeniería - ECCI
% CI-1441 Paradigmas Computacionales
% I-2015, Prof. Dr. Alvaro de la Ossa
% Oscar Esquivel Oviedo, B22410
% Diana Garbanzo Quirós, B12685
%
% Proyecto de composición musical algorítmica
% Sistema de reglas
%
% ------------------------------------------------------------------------------

%
% Funciones útiles
%

% tamano/2(+L,-T)
tamano([], 0).
tamano([_|R], N) :-
   tamano(R, M), N is M + 1.

% nesimo/3(+N,+L,-X)
nesimo(1,[X|_],X).
nesimo(N,[_|R],E) :-
   M is N - 1, nesimo(M,R,E).

% concatena/3(+L1,+L2,-L3)
concatena([],L,L).
concatena([X|Xr],Y,[X|Zr]) :-
   concatena(Xr,Y,Zr).

% posicion/3(+O,+L,-P)
posicion(O,[O|_],1).
posicion(O,[_|R],N) :-
	posicion(O,R,M), N is M + 1.

% Random
random(R) :-
	R is random_float.

% random_between(+L:int, +U:int, -R:int) is semidet.
random_between(L, U, R) :-
	integer(L), integer(U), !,
	U >= L,
	R is L+random((U+1)-L).
random_between(L, U, _) :-
	must_be(integer, L),
	must_be(integer, U).

loop_through_list(_File, []) :- !.
loop_through_list(File, [Head|Tail]) :-
	write(File, Head),
	write(File, ' '),
	loop_through_list(File, Tail).

escribirLista(List) :-
	open('cancion.txt', write, File),
	loop_through_list(File, List),
	close(File).

% ------------------------------------------------------------------------------------------------------------------

%
% Rock
%

%
% cancionRock/3(+escala,+melodía,-canción)
% Crea una canción de rock a partir de una escala guía y una melodía base.
cancionRock([],[],C) :-			% En su forma más simple pide una canción, sin especificar escala ni melodía inicial
	random_between(2,4,R),		% Crea un número aleatorio para la duración total de la melodía (compases)
	D is R * 4,					% Convierte la duración de compases a tiempos
	escogerEscala(E),			% Escoge una de las escalas que hay
	tamano(E,S),				% Obtiene el tamaño de la escala de una vez para no tener que volver a calcularlo
	generarMelodia(E,S,D,M),	% Genera una melodía a partir de esa escala y esa duración
	cancionRock(E,S,M,C).		% En su forma más compleja pide una canción, especificando una escala y una melodía

cancionRock(E,S,M,X) :-			% Donde se construye la canción realmente
	random_between(4,8,IA),		% Genera números aleatorios para duraciones de distintas partes de la canción
	JA is IA * 4,
	random_between(4,8,IB),
	JB is IB * 4,
	concatena([-1],[-1],ZZ),	% Genera un divisor -1,-1 para dividir las partes de la canción
	generarTransicion(E,S,T),	% Genera una transición a partir de la escala, la retorna en T
	generarVerso(E,S,JA,V),		% Genera un verso a partir de la escala, la duración JA, lo retorna en V
	generarCoro(E,S,JB,C),		% Genera un coro a partir de la escala, la duración JB, lo retorna en C
	generarCoroElevado(E,S,C,K),% Genera el coro elevado a partir del coro normal, lo retorna en K
	concatena(M,[ZZ],AA),		% Mete -1,-1 para dividir
	concatena(AA,T,BB),			% Une lo anterior con la transición
	concatena(BB,[ZZ],CC),		% Mete -1,-1 para dividir
	concatena(CC,V,DD),			% Une lo anterior con el primer verso
	concatena(DD,[ZZ],EE),		% Mete -1,-1 para dividir
	concatena(EE,C,FF),			% Une lo anterior con el primer coro
	concatena(FF,[ZZ],GG),		% Mete -1,-1 para dividir
	concatena(GG,T,HH),			% Une lo anterior con la transición
	concatena(HH,[ZZ],II),		% Mete -1,-1 para dividir
	concatena(II,V,JJ),			% Une lo anterior con el segundo verso
	concatena(JJ,[ZZ],KK),		% Mete -1,-1 para dividir
	concatena(KK,K,LL),			% Une lo anterior con el coro elevado
	concatena(LL,[ZZ],MM),		% Mete -1,-1 para dividir
	concatena(MM,M,NN),			% Une lo anterior con la melodía para terminar
	X = NN,
	escribirLista(X).			% Imprime la canción en un archivo para que Java la lea

%
% escogerEscala/1(-escala)
% Escoge una escala a partir de un valor aleatorio.
escogerEscala(E) :-
	random_between(1,4,A),		% Genera números aleatorios para duraciones de distintas partes de la canción
	escogerEscalaEspecifica(A,E).

% escogerEscalaEspecifica/2(+numeroAleatorio,-escala)
escogerEscalaEspecifica(A,E) :-
	A == 1,
	E = [24,26,28,29,31,33,35, 36,38,40,41,43,45,47, 48,50,52,53,55,57,59, 60,62,64,65,67,69,71, 72,74,76,77,79,81,83, 84,86,88].	% Escala C mayor
escogerEscalaEspecifica(A,E) :-
	A == 2,
	E = [24,26,27,29,31,32,35, 36,38,39,41,43,44,47, 48,50,51,53,55,56,59, 60,62,63,65,67,68,71, 72,74,75,77,79,80,83, 84,86,87].	% Harmonic minor
escogerEscalaEspecifica(A,E) :-
	A == 3,
	E = [24,26,28,31,33, 36,38,40,43,45, 48,50,52,55,57, 60,62,64,67,69, 72,74,76,79,81, 84,86,88].	% Pentatonic Major
escogerEscalaEspecifica(A,E) :-
	A == 4,
	E = [24,25,28,29,31,32,35, 36,37,40,41,43,44,47, 48,49,52,53,55,56,59, 60,61,64,65,67,68,71, 72,73,76,77,79,80,83, 84,85,88].	% Byzantine
% agregar más escalas!!!

%
% generarMelodia/2(+escala,+duracionTotal,-melodia)
% Genera una melodía a partir de una escala.
% Debe escoger una nota aleatoria con una duración aleatoria.
% Por ahora siempre escoge la misma duración, 1.
generarMelodia(_,_,0,[]).
generarMelodia(E,S,D,M) :-
	random_between(1,S,R),		% Crea un número aleatorio para generar notas
	nesimo(R,E,I),				% Escoje una nota inicial
	K is 1,						% Escoje una duración para esa nota inicial
	P is D - K,					% Duración total - duración de nota inicial
	concatena([I],[K],A),		% Genera el par nota,duracion "A" para la nota inicial
	generarNotas(E,S,P,I,1,N),	% Genera una lista de notas consecuentes N
	concatena([A],N,X),			% Finalmente, concatena la nota inicial A con la lista de notas N, en M, la N NO va entre []
	concatena(X,X,M).

% generarNotas/6(+escala,+tamaño,+duracionRestante,+notaAnterior,+duracionAnterior,-listaNotas)
generarNotas(_,_,0,_,_,[]).		% Si la duración restante es 0, retorna la lista que ya trae
generarNotas(_,_,0.0,_,_,[]).	% Si la duración restante es 0, retorna la lista que ya trae
generarNotas(E,S,D,I,Q,X) :-
	random_between(1,5,R),		% Crea un desplazamiento aleatorio a partir de la nota actual para la siguiente, por ahora entre 1 y 5
	random_between(0,1,U),				% Crea un número aleatorio para escoger el signo del desplazamiento, 0 negativo, 1 positivo
	generarNotaSiguiente(E,S,I,R,U,N),
	generarDuracionSiguiente(Q,Z),		% Escoje una duración para esta nueva nota
	redondearDuracion(D,Z,K),			% Se asegura de no sobrepasar el máximo del compás
	% K is 1,
	P is D - K,					% Duración total - duración de nueva nota
	concatena([N],[K],B),		% Genera el par nota,duracion "B" para la siguiente nota
	generarNotas(E,S,P,N,K,M),	% Continúa generando notas
	concatena([B],M,X).			% Concatena la recién generada con las demás, la M NO va entre []

% generarNotaSiguiente/6(+escala,+tamaño,+notaAnterior,+desplazamiento,+signo,-notaSiguiente)
generarNotaSiguiente(E,S,I,R,U,N) :-
	U == 0,						% Si el desplazamiento es negativo
	posicion(I,E,P),			% Guarda la posición de I dentro de E, en P
	Q is P - R,					% Resta la posición de la nota actual menos el desplazamiento
	Q > 0,						% Si el desplazamiento no nos saca de las posiciones de E
	nesimo(Q,E,N).				% La nota siguiente S será la que estaba en ese desplazamiento
generarNotaSiguiente(E,S,I,R,U,N) :-
	U == 0,						% Si el desplazamiento es negativo
	posicion(I,E,P),			% Guarda la posición de I dentro de E, en P
	Q is P + R,					% Resta a la posición de la nota actual el desplazamiento
	Q < S + 1,					% Si el desplazamiento SÍ nos saca de las posiciones de E, sumamos en vez de restar
	nesimo(Q,E,N).				% La nota siguiente S será la que estaba en ese desplazamiento
generarNotaSiguiente(E,S,I,R,U,N) :-
	U == 1,						% Si el desplazamiento es positivo
	posicion(I,E,P),			% Guarda la posición de I dentro de E, en P
	Q is P + R,					% Suma la posición de la nota actual más el desplazamiento
	Q < S + 1,					% Si el desplazamiento no nos saca de las posiciones de E
	nesimo(Q,E,N).				% La nota siguiente S será la que estaba en ese desplazamiento
generarNotaSiguiente(E,S,I,R,U,N) :-
	U == 1,						% Si el desplazamiento es positivo
	posicion(I,E,P),			% Guarda la posición de I dentro de E, en P
	Q is P - R,					% Resta a la posición de la nota actual el desplazamiento
	Q > 0,						% Si el desplazamiento SÍ nos saca de las posiciones de E, restamos en vez de sumar
	nesimo(Q,E,N).				% La nota siguiente S será la que estaba en ese desplazamiento
% Como el desplazamiento máximo es 5 por ahora, nunca ocurrirá que se genere un número que sobrepase ambos límites

% generarDuracionSiguiente/(+duracionAnterior,-duracionSiguiente)
generarDuracionSiguiente(V,N) :-
	random_between(1,3,R),		% Crea un desplazamiento aleatorio a partir de la nota actual para la siguiente, 1=mitad, 2=igual, 3=duplicar
	generarDuracion(V,R,N).
generarDuracion(V,D,N) :-
	D == 1,						% La nueva será la mitad de la anterior
	A is V/2,
	A > 1/4,					% Duración mínima: 1/2
	N is A.
generarDuracion(V,D,N) :-
	D == 1,						% La nueva será la mitad de la anterior
	B is V*2,					% Si es menor a eso, se duplica en lugar de dividir
	N is B.
generarDuracion(V,D,N) :-
	D == 2,						% La nueva será igual a la anterior
	N is V.
generarDuracion(V,D,N) :-
	D == 3,						% La nueva será la mitad de la anterior
	A is V*2,
	A < 2,						% Duración máxima: 1
	N is A.
generarDuracion(V,D,N) :-
	D == 3,						% La nueva será la mitad de la anterior
	B is V/2,					% Si es menor a eso, se duplica en lugar de dividir
	N is B.

% redondearDuracion(+maximo,+duracion,-redondeo)
redondearDuracion(M,D,R) :-
	D < M,						% Si se generó una duración que excede el máximo
	R is D.						% se le resta la diferencia a esa duración
redondearDuracion(M,D,R) :-		% En cualquier otro caso (>=)
	R is M.						% se le resta la diferencia a esa duración
	
%
% generarTransicion/3(+escala,+duracionTotal,-verso)
% Genera un verso a partir de una escala.
% Debe escoger una nota aleatoria con una duración aleatoria.
% Por ahora siempre escoge la misma duración, 4.
generarTransicion(E,S,T) :-
	random_between(1,S,R),		% Crea un número aleatorio para generar notas
	nesimo(R,E,I),				% Escoje una nota inicial
	generarNotas(E,S,8,I,1,T).	% Genera 4 compases de notas (tercer parámetro = 8)

%
% generarVerso/4(+escala,+tamaño,+duracionTotal,-verso)
% Genera un verso a partir de una escala.
% Debe escoger una nota aleatoria con una duración aleatoria.
% Por ahora siempre escoge la misma duración, 4.
generarVerso(_,_,0,[]).
generarVerso(E,S,D,V) :-
	random_between(1,S,R),		% Crea un número aleatorio para generar notas
	nesimo(R,E,I),				% Escoje una nota inicial
	K is 4,						% Escoje una duración para esa nota inicial
	P is D - K,					% Duración total - duración de nota inicial
	concatena([I],[K],A),			% Genera el par nota,duracion "A" para la nota
	generarNotasVerso(E,S,P,I,N),	% Genera una lista de notas consecuentes S para el resto del verso
	concatena([A],N,V).				% Finalmente, concatena la nota inicial A con la lista de notas S, en V
	
% generarNotasVerso/5(+escala,+tamaño,+duracionRestante,+notaAnterior,+duracionAnterior,-listaNotas)
generarNotasVerso(_,_,0,_,[]).		% Si la duración restante es 0, retorna la lista que ya trae
generarNotasVerso(_,_,0.0,_,[]).	% Si la duración restante es 0, retorna la lista que ya trae
generarNotasVerso(E,S,D,I,X) :-
	random_between(1,5,R),			% Crea un desplazamiento aleatorio a partir de la nota actual para la siguiente, por ahora entre 1 y 5
	random_between(0,1,U),				% Crea un número aleatorio para escoger el signo del desplazamiento, 0 negativo, 1 positivo
	generarNotaSiguiente(E,S,I,R,U,N),
	K is 4,
	P is D - K,							% Duración total - duración de nueva nota
	concatena([N],[K],B),				% Genera el par nota,duracion "B" para la siguiente nota
	generarNotasVerso(E,S,P,N,M),		% Continúa generando notas
	concatena([B],M,X).					% Concatena la recién generada con las demás, la M NO va entre []
	
%
% generarCoro/4(+escala,+tamaño,+duracionTotal,-verso)
% Genera un coro a partir de una escala.
% Debe escoger una nota aleatoria con una duración aleatoria.
generarCoro(E,S,D,C) :-
	random_between(1,S,R),		% Crea un número aleatorio para generar notas
	nesimo(R,E,I),				% Escoje una nota inicial
	K is 1,						% Escoje una duración para esa nota inicial
	P is D - K,					% Duración total - duración de nota inicial
	concatena([I],[K],A),		% Genera el par nota,duracion "A" para la nota inicial
	generarNotas(E,S,P,I,1,N),	% Genera una lista de notas consecuentes N
	concatena([A],N,C).			% Finalmente, concatena la nota inicial A con la lista de notas N, en M, la N NO va entre []
	
%
% generarCoroElevado/2(+escala,+tamaño,+coro,-coroElevado)
% Genera un coro nuevo a partir del coro original.
% Eleva todas las notas simplemente.
generarCoroElevado(_,_,[],[]).
generarCoroElevado(E,S,[[A|D]|R],K) :-
	generarNotaSiguiente(E,S,A,4,1,N),
	concatena([N],D,X),
	generarCoroElevado(E,S,R,Z),
	concatena([X],Z,K).












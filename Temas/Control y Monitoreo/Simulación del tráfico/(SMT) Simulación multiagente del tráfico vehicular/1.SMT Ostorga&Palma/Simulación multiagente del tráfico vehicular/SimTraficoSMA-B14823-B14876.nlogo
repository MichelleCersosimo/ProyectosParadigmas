globals
[
  grid-x-inc               ;; the amount of patches in between two roads in the x direction
  grid-y-inc               ;; the amount of patches in between two roads in the y direction
  phase                    ;; keeps track of the phase
  num-cars-stopped         ;; the number of cars that are stopped during a single pass thru the go procedure
  current-light            ;; the currently selected light

  ;; patch agentsets
  intersections ;; agentset containing the patches that are intersections
  roads         ;; agentset containing the patches that are roads
]

turtles-own
[
  speed     ;; the speed of the turtle
  speed-min ;; minimum speed of the turtle
  up-car?   ;; true if the turtle moves downwards and false if it moves to the right
  wait-time ;; the amount of time since the last time a turtle has moved
]

patches-own
[
  intersection?   ;; true if the patch is at the intersection of two roads
  green-light-up? ;; true if the green light is above the intersection.  otherwise, false.
                  ;; false for a non-intersection patches.
  my-row          ;; the row of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-column       ;; the column of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-phase        ;; the phase for the intersection.  -1 for non-intersection patches.
  auto?           ;; whether or not this intersection will switch automatically.
                  ;; false for non-intersection patches.
]

;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;

;; Initialize the display by giving the global and patch variables initial values.
;; Create num-cars of turtles if there are enough road patches for one turtle to
;; be created per road patch. Set up the plots.
to setup
  ca
  setup-globals

  ;; First we ask the patches to draw themselves and set up a few variables
  setup-patches

  set-default-shape turtles "car top" ;; Cambia la figura de la tortuga original por la parte de arriba de un vehiculo

  if (num-cars > count roads)
  [
    user-message (word "There are too many cars for the amount of "
                       "road.  Either increase the amount of roads "
                       "by increasing the GRID-SIZE-X or "
                       "GRID-SIZE-Y sliders, or decrease the "
                       "number of cars by lowering the NUMBER slider.\n"
                       "The setup has stopped.")
    stop
  ]

  ;; Now create the turtles and have each created turtle call the functions setup-cars and set-car-color
  crt num-cars
  [
    setup-cars
    record-data
  ]

  ;; give the turtles an initial speed
  ask turtles [ set-car-speed ]

  reset-ticks
end

;; Initialize the global variables to appropriate values
to setup-globals
  set current-light nobody ;; just for now, since there are no lights yet
  set phase 0
  set num-cars-stopped 0
  set grid-x-inc world-width / 3
  set grid-y-inc world-height / 3
end

;; Make the patches have appropriate colors, set up the roads and intersections agentsets,
;; and initialize the traffic lights to one setting
to setup-patches
  ;; initialize the patch-owned variables and color the patches to a base-color
  ask patches
  [
    set intersection? false
    set auto? false
    set green-light-up? true
    set my-row -1
    set my-column -1
    set my-phase -1
    set pcolor yellow - 3
  ]

  ;; initialize the global variables that hold patch agentsets
  set roads patches with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) or
    (floor((pycor + max-pycor) mod grid-y-inc) = 0)]
  set intersections roads with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) and
    (floor((pycor + max-pycor) mod grid-y-inc) = 0)]

  ask roads [ set pcolor gray - 2 ]
  setup-intersections
end

;; Give the intersections appropriate values for the intersection?, my-row, and my-column
;; patch variables.  Make all the traffic lights start off so that the lights are red
;; horizontally and green vertically.
to setup-intersections
  ask intersections
  [
    set intersection? true
    set green-light-up? true
    set my-phase 0
    set auto? true
    set my-row floor((pycor + max-pycor) / grid-y-inc)
    set my-column floor((pxcor + max-pxcor) / grid-x-inc)
    set-signal-colors
  ]
end

;; Initialize the turtle variables to appropriate values and place the turtle on an empty road patch.
to setup-cars  ;; turtle procedure
  set speed 0.1 + random-float .09 ;; Ajusta la velocidad de un vehículo con un número aleatorio
  set speed-min 0
  set wait-time 0
  put-on-empty-road
  ifelse intersection?
  [
    ifelse random 2 = 0
    [ set up-car? true ]
    [ set up-car? false ]
  ]
  [
    ; if the turtle is on a vertical road (rather than a horizontal one)
    ifelse (floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0)
    [ set up-car? true ]
    [ set up-car? false ]
  ]
  ifelse up-car?
  [ set heading 180 ]
  [ set heading 90 ]
end

to setup-cars2  ;; Procedimiento secundario para las tortugas al crearse de nuevo
  set speed 0.1 + random-float .09 
  set speed-min 0
  set wait-time 0
  put-on-empty-road
  ifelse intersection?
  [
    ifelse random 2 = 0
    [ set up-car? true ]
    [ set up-car? false ]
  ]
  [
    
    ifelse (floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0)
    [ set up-car? true ]
    [ set up-car? false ]
  ]
  ifelse up-car?
  [ set heading 180 
    set ycor max-pycor]   ;; Pone a la tortuga al inicio del carril Y
  [ set heading 90 
    set xcor min-pxcor]   ;; Pone a la tortuga al inicio del carril X
end

;; Find a road patch without any turtles on it and place the turtle there.
to put-on-empty-road  ;; turtle procedure
  move-to one-of roads with [not any? turtles-on self]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Run the simulation
to go
  ;; have the intersections change their color
  set-signals
  set num-cars-stopped 0

  ;; set the turtles speed for this time thru the procedure, move them forward their speed,
  ;; record data for plotting, and set the color of the turtles to an appropriate color
  ;; based on their speed
  ask turtles
  [
    set-random-speed ;; Se le asigna además inicialmente una velocidad aleatoria
    set-car-speed
    ifelse speed = 0 ;; Si un vehículo está en un semáforo en rojo su velocidad es 0, por lo que su avance también debería ser de 0
    [
      fd speed
    ]
    [                ;; Si no, su avance será su velocidad más un valor aleatorio para generar velocidades distintas
      fd speed + random-float .09
    ]
    record-data
  ]
  
  ;; Para determinar si un vehículo deber girar se genera un número aleatorio, si es igual a 2 entonces gira
  ;; Para que la cantidad de vehículos que giran no sea tan grande, en la función interna también se genera
  ;; otro número aleatorio
  ifelse random 10 = 2
  [
    change-direction
  ]
  [    
    kill-and-create ;; funcion para matar a las tortugas cuando van a salir de la cuadrícula y se crean nuevas.
  ]
  
  ;; update the phase and the global clock
  next-phase
  
  tick
end

;; Método para cambiar de dirección de los automóviles al llegar a una intersección
to change-direction
  let killup-car 0
   let killnotup-car 0
   ;;  Pregunta a las tortugas si están en todos las posibles intersecciones.
  ask turtles at-points [ [ -7 7 ] [ 6 7 ][ -7 -5 ] [ 6 -5 ] [-7 -18 ] [ 6 -18 ] [ 18 -18  ] [ 18 7 ] [ 18 -5 ] ]
  [
    ifelse up-car? and random 10 = 6 ;; La posibilidad de que giren
    [ 
      set heading 90
      ;; Esto es para que las tortugas que estan moviéndose por los extremos y desean salir de la cuadrícula.
      ask turtles at-points [ [ 18 7 ] [ 18 -5 ] [ 18 -18 ] ] [ if up-car? [ set killnotup-car 1 die ] ] 
      set up-car? false         
    ]
    [ 
      set heading 180
      ;; Esto es para que las tortugas que estan moviéndose por los extremos y desean salir de la cuadrícula.
      ask turtles at-points [ [ -7 -18 ] [ 6 -18 ] [ 18 -18 ] ] [ if not up-car? [ set killup-car 1 die ] ]
      set up-car? true     
    ]
  ]
  if killup-car = 1  [ crt 1 [ setup-cars2 ] ] ;; Si matan tortugas, entonces se crean más.
   
  if killnotup-car = 1 [ crt 1 [ setup-cars2 ] ]
end

to set-random-speed
  set speed speed + random-float .05
end

;;Método que revisa si las tortugas van a salir de la cuadrícula para matarlas y crear nuevas
to kill-and-create  
   let killup-car 0
   let killnotup-car 0
   ;;  Pregunta a las tortugas si están en el final del carril en el que van.
   ask turtles at-points [ [-7 -18 ][ 6 -18 ][ 18 -18  ] ] [ ifelse up-car? [ set killup-car 1 die ][ ] ]      
   ask turtles at-points [ [ 18 7 ][ 18 -5 ][ 18 -18 ] ] [ ifelse up-car? [ ][ set killnotup-car 1 die ] ]

   if killup-car = 1  [ crt 1 [ setup-cars2 ] ]
   
   if killnotup-car = 1 [ crt 1 [ setup-cars2 ] ]
         
end

;; have the traffic lights change color if phase equals each intersections' my-phase
to set-signals
  ;; Determina si la opción de ticks está habilitada, es decir, si además de la espera por cantidad de vehículos
  ;; también se cambiara de señal en un tiempo determinado
  ifelse ticks?
  [
    ask intersections with [ auto? and phase = floor ((my-phase * ticks-per-cycle) / 100)]
    [    
      set green-light-up? (not green-light-up?)
      set-signal-colors
    ]
  ]
  [
  ask intersections with [ auto? ]
  [ 
    let first-car-x turtles-at -1 0 ;; Determina el primer vehículo detenido frente al semáforo en el eje X
    let first-car-y turtles-at 0 1  ;; Determina el primer vehículo detenido frente al semáforo en el eje Y
    
    let counter-x -1     ;; Contador para parcelas a revisar en el eje X
    let counter-y 1      ;; Contador para parcelas a revisar en el eje Y
    let car-cant-x 0     ;; Contador para la cantidad de vehículos detenidos en el eje X
    let car-cant-y 0     ;; Contador para la cantidad de vehículos detenidos en el eje X
    let change? false    ;; Booleano para determinar si hay que cambiar la señal del semáforo
        
    while[counter-x > -10] ;; Revisión de vehículos detenidos en el eje X
    [
      let cars-at-x turtles-at counter-x 0
      if (any? cars-at-x with [speed = 0]) and green-light-up? ;; Determina si hay algún vehículo detenido en esa parcela
      [
        set car-cant-x car-cant-x + 1 ;; Aumenta la cantidad de vehículos detenidos
      ]
      if (car-cant-x = cant-cars-change and any? first-car-x with [speed = 0]) ;; Si se cumple la cantidad de vehículos detenidos pide cambiar de señal
      [
        set change? true
      ]
      set counter-x counter-x - 1
    ]
    
    while[counter-y < 10] ;; Revisión de vehículos detenidos en el eje X
    [
      let cars-at-y turtles-at 0 counter-y
      if (any? cars-at-y with [ speed = 0]) and (not green-light-up?) ;; Determina si hay algún vehículo detenido en esa parcela
      [
        set car-cant-y car-cant-y + 1 ;; Aumenta la cantidad de vehículos detenidos
      ]
      if (car-cant-y = cant-cars-change and any? first-car-y with [speed = 0]) ;; Si se cumple la cantidad de vehículos detenidos pide cambiar de señal
      [
        set change? true
      ]
      set counter-y counter-y + 1
    ]
    
    if change? ;; Si se solicitó cambiar de señal lo hace
    [
      set green-light-up? (not green-light-up?)
      set-signal-colors
    ]
  ]
  ]
end

;; This procedure checks the variable green-light-up? at each intersection and sets the
;; traffic lights to have the green light up or the green light to the left.
to set-signal-colors  ;; intersection (patch) procedure
  ifelse power?
  [
    ifelse green-light-up?
    [
      ask patch-at -1 0 [ set pcolor red ]
      ask patch-at 0 1 [ set pcolor green ]
    ]
    [
      ask patch-at -1 0 [ set pcolor green ]
      ask patch-at 0 1 [ set pcolor red ]
    ]
  ]
  [
    ask patch-at -1 0 [ set pcolor gray - 2 ]
    ask patch-at 0 1 [ set pcolor gray - 2 ]
  ]
end

to set-car-speed  ;; turtle procedure
  ifelse pcolor = red
  [ set speed 0 ]
  [
    ifelse up-car? ;; Cada vehículo va a revisar si dentro de dos parcelas hay otro vehículo para determinar su velocidad
    [ set-speed-y 0 -1 -2 ]
    [ set-speed-x 1 0 2 ]
  ]
end

to set-speed-y [ delta-x delta-y delta-z]  ;; turtle procedure
  ;; Determina si tiene un vehículo justo en frente
  let turtles-ahead turtles-at delta-x delta-y
  ;; Determina si tiene un vehículo delta-z parcelas adelante en Y
  let turtles-ahead2 turtles-at delta-x delta-z

  ;; Si tiene un vehículo delta-z parcelas adelante vaya desacelerando
  if any? turtles-ahead2
  [
    slow-down turtles-ahead2
  ]
  ;; Si tiene un vehículo justo en frente deténgase
  ifelse any? turtles-ahead
  [
    set speed 0
  ]
  [ 
    speed-up ;; Si no, acelere   
  ]
end

to set-speed-x [ delta-x delta-y delta-z]  ;; turtle procedure
  ;; Determina si tiene un vehículo justo en frente
  let turtles-ahead turtles-at delta-x delta-y
  ;; Determina si tiene un vehículo delta-z parcelas adelante en X
  let turtles-ahead2 turtles-at delta-z delta-y

  ;; Si tiene un vehículo delta-z parcelas adelante vaya desacelerando
  if any? turtles-ahead2
  [
    slow-down turtles-ahead2
  ]
  ;; Si tiene un vehículo justo en frente deténgase
  ifelse any? turtles-ahead
  [
    set speed 0
  ]
  [ 
    speed-up ;; Si no, acelere
  ]
end

;; decrease the speed of the turtle
to slow-down [turtles-ahead2] ;; turtle procedure
  ifelse speed <= 0  ;;if speed < 0
  [ set speed 0 ]
  ;; Si tiene que desacelerar, reduzca su velocidad a la mitad y dismuya el valor de desaceleración
  [ set speed (speed / 2) - deceleration ]
end

;; increase the speed of the turtle
to speed-up  ;; turtle procedure
  ;; Si sobrepasa el límite póngalo justo en él
  ifelse speed > speed-limit
  [ set speed speed-limit ]
  ;; Si no, siga acelerando
  [ set speed speed + acceleration ]
end

;; keep track of the number of stopped turtles and the amount of time a turtle has been stopped
;; if its speed is 0
to record-data  ;; turtle procedure
  ifelse speed = 0
  [
    set num-cars-stopped num-cars-stopped + 1
    set wait-time wait-time + 1
  ]
  [ set wait-time 0 ]
end

to change-current
  ask current-light
  [
    set green-light-up? (not green-light-up?)
    set-signal-colors
  ]
end

;; cycles phase to the next appropriate value
to next-phase
  ;; The phase cycles from 0 to ticks-per-cycle, then starts over.
  set phase phase + 1
  if phase mod ticks-per-cycle = 0
    [ set phase 0 ]
end


; Copyright 2003 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
275
10
876
632
18
18
15.973
1
12
1
1
1
0
1
1
1
-18
18
-18
18
1
1
1
ticks
30.0

PLOT
10
277
270
397
Average Wait Time of Cars
Time
Average Wait
0.0
100.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [wait-time] of turtles"

PLOT
10
395
270
515
Average Speed of Cars
Time
Average Speed
0.0
100.0
0.0
1.0
true
false
"set-plot-y-range 0 speed-limit" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [speed] of turtles"

SWITCH
10
167
138
200
power?
power?
0
1
-1000

SLIDER
10
59
270
92
num-cars
num-cars
1
60
39
1
1
NIL
HORIZONTAL

PLOT
10
513
270
633
Stopped Cars
Time
Stopped Cars
0.0
100.0
0.0
100.0
true
false
"set-plot-y-range 0 num-cars" ""
PENS
"default" 1.0 0 -16777216 true "" "plot num-cars-stopped"

BUTTON
96
10
160
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
8
10
92
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
95
270
128
speed-limit
speed-limit
0
4
0.9
0.1
1
NIL
HORIZONTAL

MONITOR
165
10
270
55
Current Phase
phase
3
1
11

SLIDER
10
203
270
236
ticks-per-cycle
ticks-per-cycle
1
1000
76
1
1
NIL
HORIZONTAL

SLIDER
10
131
138
164
acceleration
acceleration
0
0.0099
0.0090
0.0010
1
NIL
HORIZONTAL

SLIDER
141
131
270
164
deceleration
deceleration
0
0.0099
0.0090
0.0010
1
NIL
HORIZONTAL

SLIDER
10
240
270
273
cant-cars-change
cant-cars-change
0
10
4
1
1
NIL
HORIZONTAL

SWITCH
141
167
270
200
ticks?
ticks?
1
1
-1000

@#$#@#$#@
## ¿QUÉ ES EL MODELO?

Este es un modelo que simula tráfico moviéndose por una ciudad. Permite que el usuario pueda cambiar distintos aspectos como cantidad de carros, semáforos inteligentes o no. Entre otras cosas relacionadas al tráfico.

Se puede intentar ver las distintas estrategias para improvisar el tráfico y entender las distintas maneras de mejorar o empeorar la calidad del mismo.

## ¿CÓMO TRABAJA?

Cada "tick" de la máquina los carros intentan moverse hacia delante según la velocidad asignada aleatoria a cada uno. Si no tienen carros delante aceleran, de lo contrario frenan; según su aceleración y desaceleración configurada. Si el carro se encuentra un semáforo en rojo el coche frena, si está verde, pasan normal.

Hay dos maneras en que pueden cambiar los semáforos, una es que además de que trabajen de manera inteligente (para evitar la congestión del tráfico), puedan también cambiar cada cierta cantidad de ticks de la aplicación, y esto el usuario lo puede personalizar a su gusto.

## ¿CÓMO USAR EL MODELO?

Primero cambiar lo que se desee personalizar con las barras deslizantes e interruptores, luego apretar el botón de SETUP.

Se puede configurar lo siguiente a su gusto : Número de carros, velocidad límite, aceleracion y desaceleración, poner semáforos o no, cambiar semáforos según ticks, la cantidad de ticks por ciclo y la cantidad de carros que conforman una congestión vehicular.

Se inicia la simulación apretando el botón "GO". En media ejecución se pueden cambiar estos mismos atributos y notar el cambio.

### Botones

SETUP - Configura todo lo que se haya tomado en cuenta con los demás elementos de configuración y se muestra en pantalla la cuadrícula 3x3 de automóviles seleccionados.
GO - Inicia la simulación.

### Deslizadores

SPEED-LIMIT - Establece la velocidad límite que pueden alcanzar los vehículos en la cuadrícula.
TICKS-PER-CYCLE - Mide la cantidad de "ticks" de la máquina que hacen falta para cambiar el color de todos los semáforos al mismo tiempo. 
ACCELERATION - Mide la aceleración que van a tener los automóviles.
DECELERATION - Mide la deseleración que van a tener los automóviles.
CANT-CARS-CHANGE - Define la cantidad de carros que el programa tomará en cuenta para determinar si es correcto cambiar la luz del semáforo cuando hay esa "X" cantidad de carros detenidos.

### Interruptores

POWER? - Si está prendido activa los semáforos, de lo contrario los carros andan en la cuadrícula sin semáforos.
TICKS? - Define si el usuario desea que los semáforos se comporten según los "ticks" o sólo según la congestión vehicular.

### Gráficos

STOPPED CARS - Gráfico que mide en determinado tiempo la cantidad de carros detenidos.
AVERAGE SPEED OF CARS - Velocidad de los carros en promedio en cierto tiempo.
AVERAGE WAIT TIME OF CARS - Mide el tiempo promedio de espera de los carros en un tiempo determinado.

### Monitores

CURRENT PHASE - Monitor que avisa simplemente por cuál "fase" va el programa.

## COSAS A NOTAR

Cuando la cantidad de carros en ambos sentidos es grande y empiezan a congestionarse en una intersección, el sistema de semáforos inteligentes empieza a cambiar los semáforos de manera muy rápida, por lo que los carros avanzan de manera muy lenta y de forma intermitente.

Por otro lado, cuando algunos carros deciden cambiar de dirección puede que no se coloquen en el centro de la calle, sino a alguno de los extremos. Esto se debe a que la decisión de cambiar de dirección se cuando un carro entre al patch de la intersección, y no específicamente en el centro del mismo. Por este mismo motivo, algunos carros quedan un poco fuera de los semáforos en rojo.

Para decidir el cambio de dirección se generan números aleatorios, por lo que al pasar por una intersección pueden cumplirse los números aleatorios varias veces, haciendo que el carro en una misma intersección decida cambiar de dirección varias veces. Sin embargo, la posibilidad de cumplimiento de los número aleatorios es baja.

## COSAS A PROBAR

Tratar de cambiar el límite de velocidad de los carros. ¿Cómo afecta esto a la eficiencia de todo el sistema? ¿Hay menos carros detenidos por una menor cantidad de tiempo? ¿Es la velocidad promedio de los carros mayor o menor?

Tratar de cambiar la cantidad de carros. ¿Cómo afecta esto a la eficiencia de todo el sistema? ¿Hay menos carros detenidos por una menor cantidad de tiempo? ¿Es la velocidad promedio de los carros mayor o menor?

Tratar de correr la simulación con el cambio de semáforos controlado por el número de 'ticks'. ¿Cómo afecta esto a la eficiencia de todo el sistema? ¿Hay menos carros detenidos por una menor cantidad de tiempo? ¿Es la velocidad promedio de los carros mayor o menor?

Tratar de correr la simulación con el cambio de semáforos controlado por la congestión vehicular. ¿Cómo afecta esto a la eficiencia de todo el sistema? ¿Hay menos carros detenidos por una menor cantidad de tiempo? ¿Es la velocidad promedio de los carros mayor o menor?

Dadas las condiciones anteriores, tratar de encontrar un balance que permita tener un tráfico fluido.

## EXTENDIENDO EL MODELO

En este momento, las calles poseen solo un carril de circulación. ¿Qué tal si se le agregan carriles? De la misma manera, existe un solo sentido de vía, ¿qué tal si se le agrega el otro sentido de vía a la misma calle?

## CARACTERÍSTICAS DE NETLOGO

Este modelo usa gráficos que permiten mostrar datos sobre la simulación, como el tiempo promedio de espera por carros, velocidad promedio de los carros y cantidad de carros detenidos.

## MODELOS RELACIONADOS

Traffic Basic simula el flujo de un único carril en una dirección
Traffic 2 Lanes agrega un segundo carril en la misma dirección
Traffic Intersection simula una intersección
Traffic Grid simula el flujo de tránsito en una malla con varias intersecciones y semáforos.

## CÓMO CITAR

Si se menciona este modelo en una publicación, se solicita que se incluyan las citas del modelo en que se basa y el software de NetLogo:

* Wilensky, U. (2003).  NetLogo Traffic Grid model.  http://ccl.northwestern.edu/netlogo/models/TrafficGrid.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## AUTORES 

Érick Ostorga Chacón y Erick Palma Solano, Escuela de Ciencias de la Computación e Informática, Universidad de Costa Rica. I CICLO 2015.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

bus
false
0
Polygon -7500403 true true 15 206 15 150 15 120 30 105 270 105 285 120 285 135 285 206 270 210 30 210
Rectangle -16777216 true false 36 126 231 159
Line -7500403 false 60 135 60 165
Line -7500403 false 60 120 60 165
Line -7500403 false 90 120 90 165
Line -7500403 false 120 120 120 165
Line -7500403 false 150 120 150 165
Line -7500403 false 180 120 180 165
Line -7500403 false 210 120 210 165
Line -7500403 false 240 135 240 165
Rectangle -16777216 true false 15 174 285 182
Circle -16777216 true false 48 187 42
Rectangle -16777216 true false 240 127 276 205
Circle -16777216 true false 195 187 42
Line -7500403 false 257 120 257 207

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
true
0
Polygon -7500403 true true 180 15 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 285 165 285 225 285 225 15 180 15
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@

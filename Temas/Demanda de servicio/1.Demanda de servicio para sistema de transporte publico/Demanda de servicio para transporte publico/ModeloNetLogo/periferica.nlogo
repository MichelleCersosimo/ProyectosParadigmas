;; Universidad de Costa Rica
;; Facultad de Ingeniería
;; Escuela de Ciencias de la Computación e Informática
;; Primer Semestre de 2015
;; Curso de Paradigmas Computacionales CI-1441
;; Profesor Dr. Alvaro de la Ossa O
;; Estudiantes: Edmundo Núñez Incer <ednincer@gmail.com> y Freiser Jiménez Corrales <freiserjimenez@gmail.com>
;; Proyecto: Generación de un modelo para el análisis de la demanda de servicio en un sistema de transporte público

extensions [ gis array matrix ]

; variables globales
globals
[
  ; ##### variables de control #####
  maxHoras
  cantParadas 
  dias
  horaSalidaBus
  tiempoSalidaBus
  
  ; #### informacion de bloques, control de salida de buses y arribo de pasajeros####
  arriboBuses
  bloquesHorarios
  cantBloques
  bloqueActual
  arribosBuses
  desviacionEstandarArribosBuses
  proximosArribos 
  
  ; ##### variables estadísticas #####
  totalPasajeros
  numPasajerosServidos
  esperaTotal
  promEsperaTotal
  ; ### gis ###
  paradas-dataset
  base-dataset ; 4 puntos para definir límites del mundo
] ; fin de globals

;; variables de los agentes
breed [paradas parada]  ;; paradas
breed [buses bus] ;; buses
breed [pasajeros pasajero] ;; pasajeros
paradas-own [tamColaPasajeros duracionBus pasajerosParada esperaParada promEsperaParada duracionesBuses bajadasPasajeros arribosPasajeros] ; variables de las paradas
buses-own [velocidad distanciaSgtParada tasaSalida siguienteParada cargaPasajeros bloqueHorario finalizar] ; variables de los buses
pasajeros-own [horaLlegada horaSubida idParada espacioEnFila] ; variables de los pasajeros

;;
;;
;; Inicialización de variables de la simulación
to setup
  clear-all
  setup-globals  
  setup-patches
  setup-paradas-gis
  setup-pasajeros
  setup-buses 
  reset-ticks
end ; fin de setup

;;
;;
;; Inicialización de las variables globales
to setup-globals
  ; ##### inicializar variables de control #####
  set maxHoras 17
  set dias 0
  set horaSalidaBus 0
  set cantParadas 63
  ; ##### inicializar bloques de horarios #####
  setup-bloque-horario
  ; ##### inicializar variables estadísticas ####
  set totalPasajeros 0
  set numPasajerosServidos 0
  set esperaTotal 0
  set promEsperaTotal 0
  ; ##### variables que definen el arribo de buses [prom desv] por bloque horario 
  set arriboBuses matrix:from-row-list [ [841 208] [865 312] [849 280] [1053 403] [1299 444] ]
  
  ; ### control de arribos a las paradas
  set proximosArribos array:from-list n-values cantParadas [0]  
end ; fin de setup-globals

;;
;;
;; Inicializar el bloque de horarios
to setup-bloque-horario
  set arriboBuses matrix:from-row-list [ [841 208] [865 312] [849 280] [1053 403] [1299 444] ]
 
  ;; Para modificar bloques horarios solo se modifican las horas de inicio de los bloques es este vector 
  let horasInicio array:from-list [5 6 9 16 19 22] 

  ;; Inicialización
  set bloqueActual 0
  set arribosBuses (matrix:get arriboBuses bloqueActual 0)
  set desviacionEstandarArribosBuses (matrix:get arriboBuses bloqueActual 1) 
    
  set cantBloques ((array:length horasInicio) - 1)
  let horaInicio array:item horasInicio 0  
  set bloquesHorarios matrix:make-constant (array:length horasInicio - 1) 2 0
  foreach (n-values cantBloques [?])
  [
    matrix:set bloquesHorarios ? 0 (((array:item horasInicio ?) - horaInicio) * 3600) 
    matrix:set bloquesHorarios ? 1 ((((array:item horasInicio (? + 1)) - horaInicio) * 3600) - 1) 
  ]
end ; fin de setup-bloque-horario

;;
;;
;; Inicialización de los "patches"
to setup-patches
  ask patches [set pcolor gray + 1]
end ; fin de setup-patches

;### PARADAS GIS ###
to setup-paradas-gis
  ;; definición del sistema de coordenadas
  gis:load-coordinate-system (word "data/WGS_84_Geographic.prj")
  ;; cargar datasets
  set paradas-dataset gis:load-dataset "data/Paradas_L1.shp"
  set base-dataset gis:load-dataset "data/Base.shp"
  ;; configurar la envolvente a partir del dataset
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of base-dataset))  
  ;; desplegar mapa 
  import-drawing "img/GoogleMap.png"
  ;; desplegar puntos=paradas como tortugas
  display-gis
  
  ;; Definir los primeros arribos de pasajeros a cada parada
  foreach (n-values cantParadas [?])
  [
    array:set proximosArribos ? (getProximoArriboParada ?)
  ]
end ; fin de setup-paradas-gis

to display-gis
  ask paradas [die]
  set-default-shape paradas "parada"
  foreach gis:feature-list-of paradas-dataset
  [ ;gis:set-drawing-color scale-color red (gis:property-value ? "POPULATION") 5000000 1000
    gis:set-drawing-color red
    gis:fill ? 1.0
    ;if label-cities
    ;[ ; a feature in a point dataset may have multiple points, so we
      ; have a list of lists of points, which is why we need to use
      ; first twice here
    let location gis:location-of (first (first (gis:vertex-lists-of ?)))
      ; location will be an empty list if the point lies outside the
      ; bounds of the current NetLogo world, as defined by our current
      ; coordinate transformation
    if not empty? location
    [ create-paradas 1
        [ set xcor item 0 location
          set ycor item 1 location
          set label gis:property-value ? "ID"
          let duraciones matrix:make-constant 5 2 0
          
          matrix:set duraciones 0 0 gis:property-value ? "PROM_1"
          matrix:set duraciones 0 1 gis:property-value ? "DESV_1"
          matrix:set duraciones 1 0 gis:property-value ? "PROM_2"
          matrix:set duraciones 1 1 gis:property-value ? "DESV_2"
          matrix:set duraciones 2 0 gis:property-value ? "PROM_3"
          matrix:set duraciones 2 1 gis:property-value ? "DESV_3"
          matrix:set duraciones 3 0 gis:property-value ? "PROM_4"
          matrix:set duraciones 3 1 gis:property-value ? "DESV_4"
          matrix:set duraciones 4 0 gis:property-value ? "PROM_5"
          matrix:set duraciones 4 1 gis:property-value ? "DESV_5"
          
          set bajadasPasajeros array:from-list [0 0]
          array:set bajadasPasajeros 0 gis:property-value ? "PORC_BAJAD"
          array:set bajadasPasajeros 1 gis:property-value ? "DESV_BAJAD"

          set arribosPasajeros array:from-list [0 0 0 0 0]
          array:set arribosPasajeros 0 gis:property-value ? "ARR_1"
          array:set arribosPasajeros 1 gis:property-value ? "ARR_2"
          array:set arribosPasajeros 2 gis:property-value ? "ARR_3"
          array:set arribosPasajeros 3 gis:property-value ? "ARR_4"
          array:set arribosPasajeros 4 gis:property-value ? "ARR_5"
                      
          set duracionesBuses duraciones                              
        ]
    ]
    ;      set size 0
    ;      set label gis:property-value ? "NAME" ] ] ] 
  ]
  ask paradas[set size 10]
  ask paradas [set label (word tamColaPasajeros "    ")]
  ask paradas [ set label-color red ]
  ask paradas [ set color blue ]  
end ; fin de display-gis

;### FIN PARADAS GIS ###


;####################################### BUSES ########################################

;;
;;
;; Inicialización de los agentes tipo "bus"
to setup-buses
  ask buses [ set label-color blue ]  
end ; fin de setup-buses

;;
;;
;; crear un nuevo bus
to nuevo-bus
  create-buses 1
  [
    setxy -360 -90 ; posición donde arranca el bus
    set siguienteParada 0 ; los buses siempre inician hacia la primer parada 
    set color random 100 
    set label-color blue
    set size 20 
    set pen-mode "down"
    set shape "bus"
    set cargaPasajeros 0
    face parada siguienteParada
    set velocidad 1
    set finalizar 0
    forward velocidad ; distancia / tiempo;
  ]
end ; fin de nuevo-bus

;;
;;
;; mueve el bus de acuerdo a una velocidad predeterminada entre cada parada
to avanzar
  face parada siguienteParada 
  set distanciaSgtParada distance parada siguienteParada
  if velocidad > distanciaSgtParada [set velocidad distanciaSgtParada]
  forward velocidad ; avanzar a la velocidad establecida en la parada anterior
  
  ; si llegó a una parada
  let laParada siguienteParada
  let unaParada one-of paradas-here
  if (unaParada != nobody) and ([who] of unaParada = laParada) ; si llegó a la parada correcta
  [
    ;bajar pasajeros
    if cargaPasajeros > 0
    [
      let aBajar getCantBajadas laParada cargaPasajeros ; calcula la cantidad de gente que se baja en la parada
      set cargaPasajeros cargaPasajeros - aBajar
    ] 

    ;subir pasajeros   
    while [ (cargaPasajeros < maxPasajeros) and ( [tamColaPasajeros] of parada laParada > 0) ]
    [      
      let alguien one-of pasajeros-here with [idParada = laParada]             
      if alguien != nobody ;; si hay un pasajero en estas coordenadas que no esté subido en el bus
      [ 
        ; estadísticas de tiempos de espera de pasajeros
        ask alguien [
          set horaSubida ticks ; marcar la hora de subida al bus de este pasajero
          let esperaPasajero horaSubida - horaLlegada ; calcular el tiempo de espera de este pasajero
          ask parada laParada [set esperaParada esperaParada + esperaPasajero set promEsperaParada (esperaParada / pasajerosParada)] ; sumar el tiempo del pasajero al acumulador de tiempos de la parada
          set esperaTotal esperaTotal + esperaPasajero ; sumar el tiempo de espera de este pasajero al tiempo total
          die ; eliminar al pasajero de la simulación
        ]
        ;; correr la fila de pasajeros un campo hacia arriba
        let filaPasajeros pasajeros with [idParada = laParada]
        if count filaPasajeros > 0
        [
            ask filaPasajeros [set ycor ycor + espacioEnFila]
        ]
        set cargaPasajeros cargaPasajeros + 1 
        ask parada laParada [set tamColaPasajeros tamColaPasajeros - 1 set label (word tamColaPasajeros "    ")]
        set numPasajerosServidos numPasajerosServidos + 1
      ] ; fin si hay alguien en la parada
      
    ] ; fin while para subir pasajeros

    ifelse (finalizar = 1) [die]
    [
      set siguienteParada ((siguienteParada + 1) mod (cantParadas)) ; actualizar la siguiente parada [0, 64]
      
      if siguienteParada = 0 ; si el bus ya dió la vuelta
      [
        ; indicar bandera que en la proxima parada se elimine el bus
        set finalizar 1
      ]
      set label cargaPasajeros ; actualizar la etiqueta de la cantidad de pasajeros que lleva el bus
      let distancia distance parada siguienteParada ; actualizar la velocidad a la que tienen que ir el bus hacia la siguiente parada
      let duracion setDuracionBusParada (siguienteParada)
      let tiempo [duracionBus] of parada siguienteParada ; aquí hay que camiarle la duración por ahora está aleatoria
      set velocidad (distancia / tiempo)    
    ]
  ] ; fin if llegó a la parada correcta
end ; fin de avanzar

;####################################### PASAJEROS ########################################
;;
;;
;; Inicialización de los agentes tipo "pasajero"
to setup-pasajeros
  set-default-shape pasajeros "person"
end ; fin de setup-buses

;;
;;
;; crear un nuevo pasajero
to nuevo-pasajero [p]
  create-pasajeros 1
  [
    set horaLLegada ticks
    set horaSubida 0
    set idParada p
    ask parada idParada [set pasajerosParada pasajerosParada + 1]
    set espacioEnFila espacioFila
    let fila [tamColaPasajeros] of parada idParada
    setxy [xcor] of parada idParada [ycor] of parada idParada - (fila * espacioEnFila)
    set size 10
    set color pink
    ask parada idParada [set tamColaPasajeros tamColaPasajeros + 1]
    set totalPasajeros totalPasajeros + 1
  ]
end ; fin de nuevo-pasajero


;####################################### PRINCIPAL ########################################

;;
;;
;; correr la simulación
to go
  ; definir en qué bloque horario se encuentra
  let bloqueRevisar ((bloqueActual + 1) mod cantBloques)
  let ticksDia (ticks mod 61200)
  if(((bloqueRevisar = 0) and (ticksDia < (matrix:get bloquesHorarios 1 0))) or 
     ((bloqueRevisar > 0) and (ticksDia >= (matrix:get bloquesHorarios bloqueRevisar 0))))
  [ set bloqueActual bloqueRevisar
    ; Ajustar salida de buses
    set arribosBuses (matrix:get arriboBuses bloqueActual 0)
    set desviacionEstandarArribosBuses (matrix:get arriboBuses bloqueActual 1) 
    ask buses [set bloqueHorario (bloqueActual + 1)] ; ajustar el bloque de horario de los buses (de 1 a 5, bloqueActual que va de 0 a 4)
  ]
  
  ; si se acaba el tiempo de la simulacion
  if ticks >= (maxDias * maxHoras * 60 * 60) - 1 ; 1 tick = 1 segundo
  [
    ;; ***** Imprimir Estadísticas *****
    output-show word "Prom espera total: " promEsperaTotal ; promedio espera general
    output-print "Prom espera por parada:" ; escribir salida de promedios de espera de cada parada
    let i 0
    while[i < count paradas]
    [
      ask parada i [output-show promEsperaParada / 60]
      set i i + 1
    ]
    stop; terminar la simulacion
  ]
  
  if ticks != 0 and ticks mod ((maxHoras * 60 * 60) - 1) = 0
  [
    set dias dias + 1
  ]
  
  if ticksDia = 0 ; el primer bus siempre sale a las 5:00 am
  [
    set horaSalidaBus 0
  ]
  
  ;; crear un nuevo bus
  if ticksDia = horaSalidaBus
  [ 
    nuevo-bus
    set tiempoSalidaBus getTiempoSalidaBus arribosBuses desviacionEstandarArribosBuses
    ;set tiempoSalidaBus int (tiempoSalidaBus + (tiempoSalidaBus * variacionSalidas))
    set horaSalidaBus ticksDia + tiempoSalidaBus 
  ]
  
  ;; revisar si deben llegar pasajeros a cada parada 
  foreach (n-values cantParadas [?])
  [    
    let prox array:item proximosArribos ?
    ifelse (prox = 0) 
    [
      nuevo-pasajero ?
      array:set proximosArribos ? (getProximoArriboParada ?)
    ]
    [
      array:set proximosArribos ? (prox - 1)
    ]
    
  ]
  
  
  
  ask buses [avanzar]
  ask paradas [set label (word tamColaPasajeros "    ")]
  if numPasajerosServidos > 0
  [
    set promEsperaTotal ((esperaTotal / numPasajerosServidos) / 60) ; mostrar en minutos
  ]
  
  tick  
end ; fin de go

;###################################### VALORES ALEATORIOS ################################

;;
;;
;; retorna un tiempo normal según cantidad de arribos "m" y una desviación estándar s
to-report getTiempoSalidaBus [m s]
  let sigSalida (abs random-normal m s)
  let salida (int (sigSalida + ((variacionSalidas * sigSalida) / 100)))
  report salida
end ; fin de getTiempoSalidaBus

;;
;;
;; establece la duracion de la parada "p" dependiendo del bloque horario actual
to-report setDuracionBusParada [p]
  let duracion 0
  
  ask parada p [ 
    set duracionBus (abs random-normal (matrix:get duracionesBuses bloqueActual 0) (matrix:get duracionesBuses bloqueActual 1))
    set duracion duracionBus
  ]
  report duracion
end ; fin de setDuracionBusParada

;; establece en cuantos ticks se generará un arribo de usuario en la parada "p"
to-report getProximoArriboParada [p]
  let proxArribo 0
  
  ask parada p [
    let proxArriboTmp (abs (random-exponential (array:item arribosPasajeros bloqueActual)))
    set proxArribo (int (proxArriboTmp + ((variacionArribos * proxArriboTmp) / 100)))
  ]
  
  report proxArribo
end ; fin de getProximoArriboParada

;;
;;
;; define cuantas personas bajan del bus en la parada "p" dada la cantidad de personas actual en el bus "c"
to-report getCantBajadas [p c]
  let bajadas 0
  
  ask parada p [
    let porcBajadas random-normal (array:item bajadasPasajeros 0) (array:item bajadasPasajeros 1)
    set bajadas int (porcBajadas * c)
    if bajadas > c [ set bajadas c ]
  ]
  report bajadas
end


;###################################### UTILITARIOS ################################
;;
;; Retorna el día y hora dependiendo de los ticks actuales
to-report getDateTime
  let diasSem array:from-list ["L" "K" "M" "J" "V"]
  let segDia (ticks mod 61200)
  let hora int ((segDia / 3600) + 5)
  let dia int(ticks / 61200)
  let mins int((ticks - (61200 * dia) - ((hora - 5) * 3600)) / 60)
  let ampm "AM"
  if(hora > 11) [ set ampm "PM" ]
  if(hora > 12) [ set hora (hora - 12) ]
  if(hora < 10) [ set hora (word "0" hora) ]  
  if(mins < 10) [ set mins (word "0" mins) ]
  report (word (array:item diasSem dia) " - " hora ":" mins " " ampm)
end ; fin de getDateTime
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1053
505
400
223
1.04
1
10
1
1
1
0
1
1
1
-400
400
-223
223
1
1
1
ticks
30.0

BUTTON
8
15
71
48
NIL
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

BUTTON
114
16
177
49
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

TEXTBOX
8
98
158
116
Paradas
12
0.0
1

SLIDER
8
116
197
149
variacionArribos
variacionArribos
-10
10
0
1
1
%
HORIZONTAL

TEXTBOX
10
222
160
240
Buses
12
0.0
1

SLIDER
5
243
195
276
variacionSalidas
variacionSalidas
-10
10
0
1
1
%
HORIZONTAL

SLIDER
6
282
196
315
maxPasajeros
maxPasajeros
25
100
80
5
1
NIL
HORIZONTAL

TEXTBOX
9
329
159
347
Pasajeros
12
0.0
1

MONITOR
7
349
150
394
Total Pasajeros
totalPasajeros
0
1
11

MONITOR
8
401
149
446
Pasajeros Servidos
numPasajerosServidos
0
1
11

MONITOR
9
454
157
499
Prom Espera Total (min)
promEsperaTotal
4
1
11

SLIDER
158
351
191
456
espacioFila
espacioFila
1
5
2
1
1
NIL
VERTICAL

OUTPUT
8
154
198
220
12

MONITOR
215
35
307
80
Día - Hora
getDateTime
17
1
11

SLIDER
8
59
198
92
maxDias
maxDias
1
5
5
1
1
dias
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

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

hex
false
0
Polygon -7500403 true true 0 150 75 30 225 30 300 150 225 270 75 270

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

parada
false
0
Circle -7500403 true true 0 0 300
Rectangle -1 true false 60 90 240 240
Circle -7500403 true true 77 195 30
Polygon -1 true false 60 105 60 90 60 75 75 45 225 45 240 75 240 105 60 105
Rectangle -10899396 false false 90 60 210 75
Polygon -7500403 true true 75 150 75 105 90 90 210 90 225 105 225 150
Circle -7500403 true true 197 195 30
Polygon -1 true false 90 225 90 255 105 270 120 255 120 225 90 225
Polygon -1 true false 180 225 180 255 195 270 210 255 210 225 180 225

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

warning
false
0
Polygon -7500403 true true 0 240 15 270 285 270 300 240 165 15 135 15
Polygon -16777216 true false 180 75 120 75 135 180 165 180
Circle -16777216 true false 129 204 42

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

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
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="maxHoras">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxBuses">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxPasajeros">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variacionSalidas">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="variacionArribos">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxDias">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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

;; =======================================================================
;;                    Universidad de Costa Rica
;;          Escuela de Ciencias de la Computación e Informática
;; Simulación multiagente para el curso CI1441 Paradigmas Computacionales
;;       Estudiantes: César Mata Bonilla y Brenda Aymerich Fuentes
;;                         I Ciclo, 2015
;; =======================================================================

;; Las modificaciones a la simulación original se encuentran marcadas con comentarios.

;; =======================================
;; Nuevas razas agregadas a la simulación
;; ---------------------------------------
    breed[peatones peaton]                   ;; agente peatón
    breed[pasos-peatonales paso-peatonal]    ;; objeto paso peatonal
;; =======================================

globals
[
  grid-x-inc               ;; the amount of patches in between two roads in the x direction
  grid-y-inc               ;; the amount of patches in between two roads in the y direction
  acceleration             ;; the constant that controls how much a car speeds up or slows down by if
                           ;; it is to accelerate or decelerate
  phase                    ;; keeps track of the phase
  num-cars-stopped         ;; the number of cars that are stopped during a single pass thru the go procedure
  current-light            ;; the currently selected light

  ;; patch agentsets
  intersections            ;; agentset containing the patches that are intersections
  roads                    ;; agentset containing the patches that are roads

  ;; ====================================================
  ;; Variables globales nuevas agregadas a la simulación
  ;; ---------------------------------------------------
      autos-vertical       ;; cantidad de autos totales en vertical
      autos-horizontal     ;; cantidad de autos totales en horizontal
      predeterminada       ;; verifica si el usuario escogió la simulación predeterminada
      hora                 ;; indica la hora del día
  ;; ====================================================
]

turtles-own
[
  speed     ;; the speed of the turtle
  up-car?   ;; true if the turtle moves downwards and false if it moves to the right
  wait-time ;; the amount of time since the last time a turtle has moved
]

patches-own
[
  ;; =======================================================================
  ;; Atributo nuevo agregado a las propiedades por defecto de la simulación
  ;; ----------------------------------------------------------------------
      tipo        ;; identifica el tipo de parche (calle, intersección, paso peatonal, punto de espera o acera)
  ;; =======================================================================

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

;; =========================================
;; Nuevos atributos de los agentes peatones
;; ----------------------------------------
    peatones-own
    [
      velocidad            ;; velocidad de la peaton (constante pero distinto en cada peatón)
      tiempo-caminata      ;; tiempo de caminata antes de cruzar la calle
      cruce                ;; fases para cruzar la calle
    ]
;; =========================================

;;;;;;;;;;;;;;;;;;;;;;
;; Setup Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;

;; Initialize the display by giving the global and patch variables initial values.
;; Create num-cars of turtles if there are enough road patches for one turtle to
;; be created per road patch. Set up the plots.
to setup
  ca
  setup-globals
  
  ;; =========================================================================
  ;; Inicialización de atributos para la simulación controlada por el usuario
  ;; ------------------------------------------------------------------------
      set hora-inicio 0
      set ticks-por-hora 0 
      set peatones-por-retirar 0
      set peatones-por-ingresar 0
      set autos-por-retirar 0
      set autos-por-ingresar 0
  ;; =========================================================================

  ;; First we ask the patches to draw themselves and set up a few variables
  setup-patches

  ;; ==============================================
  ;; Creación de peatones al iniciar la simulación
  ;; ---------------------------------------------
      crear-peatones
  ;; ==============================================

  make-current one-of intersections
  label-current

  set-default-shape turtles "car"

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
    set-car-color
    record-data
  ]

  ;; give the turtles an initial speed
  ask turtles with [shape = "car"] [ set-car-speed ]

  ;; ========================================================================================
  ;; Si el usuario elige "simulación predeterminada", se inicializan los valores de la misma
  ;; ---------------------------------------------------------------------------------------
      ifelse simulacion-predeterminada?
      [
        set hora 5
        set hora-inicio 5
        set ticks-por-hora 55  
        set peatones-por-ingresar 0
        set autos-por-ingresar 0
        set peatones-por-retirar 0
        set autos-por-retirar 0
      ]
      [
        set hora hora-inicio
      ]
  ;; ========================================================================================

  reset-ticks
end

;; Initialize the global variables to appropriate values
to setup-globals
  set current-light nobody ;; just for now, since there are no lights yet
  set phase 0
  set num-cars-stopped 0
  set grid-x-inc world-width / grid-size-x
  set grid-y-inc world-height / grid-size-y

  ;; don't make acceleration 0.1 since we could get a rounding error and end up on a patch boundary
  set acceleration 0.099
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
    set pcolor brown + 3

    ;; =============================================================================
    ;; Establece el tipo de patch para que los peatones solo caminen por las aceras
    ;; ----------------------------------------------------------------------------
        set tipo "acera"
    ;; =============================================================================
  ]

  ;; initialize the global variables that hold patch agentsets
  set roads patches with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) or
    (floor((pycor + max-pycor) mod grid-y-inc) = 0)]
    
    ;; ==============================================================================================
    ;; Establece el tipo para el ámbito de movimiento de los autos: calles horizontales y verticales
    ;; ---------------------------------------------------------------------------------------------
        ask patches with 
        [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0)] [set tipo "calle-vertical"]
        ask patches with 
        [(floor((pycor + max-pycor) mod grid-y-inc) = 0)] [set tipo "calle-horizontal"]
    ;; ==============================================================================================
    
  set intersections roads with
    [(floor((pxcor + max-pxcor - floor(grid-x-inc - 1)) mod grid-x-inc) = 0) and
    (floor((pycor + max-pycor) mod grid-y-inc) = 0)]

  ask roads [ set pcolor white ]
  
  ;; ======================================================
  ;; Crea los pasos peatonales sobre las calles verticales
  ;; -----------------------------------------------------
      ask patches with [(tipo = "calle-vertical") and (pycor mod 22 = 14 or pycor mod 22 = 20)][    
        sprout-pasos-peatonales 1 [
          set shape "paso-peatonal-horizontal"
        ]
      ]
  ;; ======================================================

  ;; ========================================================
  ;; Crea los pasos peatonales sobre las calles horizontales
  ;; -------------------------------------------------------
      ask patches with [(tipo = "calle-horizontal") and (pxcor mod 40 = 12 or pxcor mod 40 = 28)][  
        sprout-pasos-peatonales 1 [
          set shape "paso-peatonal-vertical"
        ]
      ]
  ;; ========================================================
  
  ;; =====================================================================
  ;; Se asigna el tipo para el ámbito por donde deben cruzar los peatones
  ;; ---------------------------------------------------------------------
      ask pasos-peatonales [
        set tipo "paso-peatonal"
        stamp  
        die
      ]
  ;; =====================================================================
  
  ;; ==============================================
  ;; Se asignan los puntos de espera en las aceras
  ;; ---------------------------------------------
      ask patches with [tipo = "paso-peatonal"] [
        ask neighbors4 [
          if tipo = "acera" [
            set tipo "punto-espera"
            ask patches with [tipo = "punto-espera"] [set pcolor brown + 3]
            ]
          ]
        ]
  ;; ==============================================
  
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
  set speed 0
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
    [ set up-car? true 
      set autos-vertical autos-vertical + 1 ]
    [ set up-car? false 
      set autos-horizontal autos-horizontal + 1 ]
  ]
  ifelse up-car?
  [ set heading 180 ]
  [ set heading 90 ]
end

;; ===================================================================
;; Se crean los agentes peatones con sus propiedades correspondientes
;; ------------------------------------------------------------------
    to crear-peatones  
      while [count peatones < num-of-people] [
        ask one-of patches with [tipo = "acera"] [
          sprout-peatones 1 [
            set velocidad random 7 + 5
            set size 1
            set tiempo-caminata random tiempo-para-cruzar
            set shape "peaton"
          ]
        ]
      ]
    end
;; ===================================================================

;; Find a road patch without any turtles on it and place the turtle there.
to put-on-empty-road  ;; turtle procedure
  move-to one-of roads with [not any? turtles-on self]
end

;;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Procedures ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; Run the simulation
to go
  
  ;; =====================================================================================
  ;; Parar la simulación cuando ya solo queda un carro y ya está saliendo de la simulación
  ;; -------------------------------------------------------------------------------------
  if count turtles with [shape = "car"] = 1 and not any? turtles with [shape = "peaton"] 
  [
     let x [pxcor] of one-of turtles with [shape = "car"]
     let y [pycor] of one-of turtles with [shape = "car"]
     if x >= max-pxcor [stop]
     if y >= max-pycor [stop]
  ]
  ;;======================================================================================
  
  update-current

  ;; have the intersections change their color
  set-signals
  set num-cars-stopped 0

  ;; set the turtles speed for this time thru the procedure, move them forward their speed,
  ;; record data for plotting, and set the color of the turtles to an appropriate color
  ;; based on their speed
  ask turtles with [shape = "car"]  
  [
    set-car-speed
    fd speed
    record-data
    set-car-color
  ]

  ;; update the phase and the global clock
  next-phase

  ;; ==========================================
  ;; Mover los petones dentro de la simulación
  ;; -----------------------------------------
      mover-peatones
  ;; ==========================================

  ;; ==================================================================================================================
  ;; Comprueba si el usuario selecciona la simulación predeterminada y de acuerdo a eso actualiza los siguientes ticks
  ;; -----------------------------------------------------------------------------------------------------------------
      ifelse simulacion-predeterminada?
      [
        actualizar-hora-predeterminada
        controlar-simulacion-predeterminada
      ]
      [
        actualizar-hora-usuario
        controlar-simulacion
      ]
  ;; ==================================================================================================================
  
  tick
end

;; ========================================================================================================
;; Actualiza el monitor de hora de la simulación de acuerdo a la cantidad de ticks incluída por el usuario
;; --------------------------------------------------------------------------------------------------------
    to actualizar-hora-usuario
      if hora = 24 [ set hora 0 ]
      if ((ticks mod ticks-por-hora) = 0)
      [ set hora hora + 1 ]
    end
;; ========================================================================================================

;; ====================================================================================================
;; Actualiza el monitor de hora de la simulación de acuerdo a la cantidad de ticks predeterminada (55)
;; ----------------------------------------------------------------------------------------------------
    to actualizar-hora-predeterminada
      if hora = 24 [ set hora 0 ]
      if ((ticks mod 55) = 0)
      [ set hora hora + 1 ]
    end
;; ====================================================================================================

;; =======================================================================================
;; Aumenta y disminuye el tráfico y los peatones de acuerdo a lo ingresado por el usuario
;; ---------------------------------------------------------------------------------------
    to controlar-simulacion
      aumentar-trafico-usuario
      disminuir-trafico-usuario
      aumentar-peatones-usuario
      disminuir-peatones-usuario
    end
;; =======================================================================================

;; =========================================================================
;; Ingresa la cantidad de autos seleccionada por el usuario a la simulación
;; -------------------------------------------------------------------------
    to aumentar-trafico-usuario
      crt autos-por-ingresar
      [
        setup-cars
        set-car-color
        record-data
        set autos-por-ingresar autos-por-ingresar - 1
      ]
    end
;; =========================================================================

;; ========================================================================
;; Retira la cantidad de autos seleccionada por el usuario a la simulación
;; -----------------------------------------------------------------------
    to disminuir-trafico-usuario
      ask patches with [(tipo = "calle-vertical") or (tipo = "calle-horizontal")] [
           repeat autos-por-retirar [
              if any? turtles-here [
                   ask one-of turtles-here [ die ]
                   set autos-por-retirar autos-por-retirar - 1
                ]
           ]
         ]
    end
;; ========================================================================

;; ============================================================================
;; Ingresa la cantidad de peatones seleccionada por el usuario a la simulación
;; ---------------------------------------------------------------------------
    to aumentar-peatones-usuario
      while [peatones-por-ingresar > 0] [
        ask one-of patches with [tipo = "acera"] [
          sprout-peatones 1 [
            set velocidad random 7 + 5
            set size 1
            set tiempo-caminata random tiempo-para-cruzar
            set shape one-of ["peaton"]
          ]
        ]
        set peatones-por-ingresar peatones-por-ingresar - 1
      ]
    end
;; ============================================================================

;; ===========================================================================
;; Retira la cantidad de peatones seleccionada por el usuario a la simulación
;; --------------------------------------------------------------------------
    to disminuir-peatones-usuario
      ask patches with [(tipo = "acera") or (tipo = "punto-espera")] [
           repeat peatones-por-retirar [
              if any? turtles-here [
                   ask one-of turtles-here [ die ]
                   set peatones-por-retirar peatones-por-retirar - 1
                ]
           ]
         ]
    end
;; ===========================================================================

;; =======================================================================================
;; Aumenta y disminuye el tráfico y los peatones de acuerdo a los valores predeterminados
;; --------------------------------------------------------------------------------------
    to controlar-simulacion-predeterminada
      aumentar-trafico-predeterminada
      disminuir-trafico-predeterminada
      aumentar-peatones-predeterminada
      disminuir-peatones-predeterminada
    end
;; =======================================================================================

;; =======================================================================
;; Ingresa una cantidad aleatoria de autos dependiendo de la hora del día
;; ----------------------------------------------------------------------
    to aumentar-trafico-predeterminada
      let cantidad 0

      ;; La cantidad de autos a ingresar es aleatoria y depende de la hora del día para poder simular "horas pico"
      if ticks <= 165 [ set cantidad 5 ]                  ;; 5 - 6 - 7 - 8 
      if ticks > 165 and ticks <= 385 [ set cantidad 1 ]  ;; 8 - 9- 10 - 11 - 12
      if ticks > 385 and ticks <= 440 [ set cantidad 6 ]  ;; 12 - 1pm
      if ticks > 440 and ticks <= 660 [ set cantidad 1 ]  ;; 1pm - 2pm - 3pm - 5pm
      if ticks > 660 and ticks <= 715 [ set cantidad 8 ]  ;; 5 pm - 6pm
      if ticks > 715 and ticks <= 1045[ set cantidad 1 ]  ;; hasta las 12 am
     
      let cantidad-autos random cantidad
      crt cantidad-autos
      [
        setup-cars
        set-car-color
        record-data
      ]
    end
;; =======================================================================

;; =============================================================================
;; Retira los carros que salen del marco de la simulación para agregar realismo
;; ----------------------------------------------------------------------------
    to disminuir-trafico-predeterminada
      ask turtles with [ shape = "car" and xcor > max-pxcor ] [ die ]
      ask turtles with [ shape = "car" and ycor > max-pycor ] [ die ]
    end
;; =============================================================================

;; ==========================================================================
;; Ingresa una cantidad aleatoria de peatones dependiendo de la hora del día
;; -------------------------------------------------------------------------
    to aumentar-peatones-predeterminada
      let cantidad 0

      ;; La cantidad de peatones por ingresar es aleatoria y depende de la hora del día
      if ticks <= 165 [ set cantidad 2 ]                   ;; 5 - 6 - 7 - 8 
      if ticks > 165 and ticks <= 350 [ set cantidad 1 ]   ;; 8 - 9- 10 - 11
      if ticks > 350 and ticks <= 430 [ set cantidad 4 ]   ;; 11- 12:50 pm
      if ticks > 430 and ticks <= 650 [ set cantidad 1 ]   ;; 1pm - 2pm - 3pm - 4:50 pm
      if ticks > 650 and ticks <= 705 [ set cantidad 6 ]   ;; 5 pm - 6pm
      if ticks > 705 and ticks <= 1045[ set cantidad 1 ]   ;; hasta las 12 am
      
      let cantidad-peatones random cantidad
      repeat cantidad-peatones[
        ask one-of patches with [tipo = "acera" or tipo = "punto-espera"] [
          sprout-peatones 1[
            set velocidad random 7 + 5
            set size 1
            set tiempo-caminata random tiempo-para-cruzar
            set shape one-of ["peaton"]
          ]
        ]
      ]
    end
;; ==========================================================================

;; ==========================================================================
;; Retira una cantidad aleatoria de peatones dependiendo de la hora del día
;; -------------------------------------------------------------------------
    to disminuir-peatones-predeterminada
      let cantidad 0
      if ticks <= 165 [ set cantidad 1 ]                   ;; 5 - 6 - 7 - 8 
      if ticks > 165 and ticks <= 350 [ set cantidad 1 ]   ;; 8 - 9- 10 - 11
      if ticks > 350 and ticks <= 430 [ set cantidad 1 ]   ;; 11- 12:50 pm
      if ticks > 430 and ticks <= 650 [ set cantidad 2 ]   ;; 1pm - 2pm - 3pm - 4:50 pm
      if ticks > 650 and ticks <= 705 [ set cantidad 3 ]   ;; 5 pm - 6pm
      if ticks > 705 and ticks <= 1045[ set cantidad 3 ]   ;; hasta las 12 am
      
      let cantidad-peatones random cantidad
      ask patches with [(tipo = "acera") or (tipo = "punto-espera")] [
           repeat cantidad-peatones [
              if any? turtles-here [
                   ask one-of turtles-here [ die ]
                   set cantidad-peatones cantidad-peatones - 1
                ]
           ]
         ]
    end
;; ==========================================================================

to choose-current
  if mouse-down?
  [
    let x-mouse mouse-xcor
    let y-mouse mouse-ycor
    if [intersection?] of patch x-mouse y-mouse
    [
      update-current
      unlabel-current
      make-current patch x-mouse y-mouse
      label-current
      stop
    ]
  ]
end

;; Set up the current light and the interface to change it.
to make-current [light]
  set current-light light
  set current-phase [my-phase] of current-light
  set current-auto? [auto?] of current-light
end

;; update the variables for the current light
to update-current
  ask current-light [
    set my-phase current-phase
    set auto? current-auto?
  ]
end

;; label the current light
to label-current
  ask current-light
  [
    ask patch-at -1 1
    [
      set plabel-color black
      set plabel "current"
    ]
  ]
end

;; unlabel the current light (because we've chosen a new one)
to unlabel-current
  ask current-light
  [
    ask patch-at -1 1
    [
      set plabel ""
    ]
  ]
end

;; have the traffic lights change color if phase equals each intersections' my-phase
to set-signals
  ask intersections with [auto? and phase = floor ((my-phase * ticks-per-cycle) / 100)]
  [
    set green-light-up? (not green-light-up?)
    set-signal-colors
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
    ask patch-at -1 0 [ set pcolor white ]
    ask patch-at 0 1 [ set pcolor white ]
  ]
end

;; set the turtles' speed based on whether they are at a red traffic light or the speed of the
;; turtle (if any) on the patch in front of them
to set-car-speed  ;; turtle procedure
  
  ifelse pcolor = red
  [ set speed 0 ]
  [
    ifelse up-car?
    [ set-speed 0 -1 ]
    [ set-speed 1 0 ]
    
  ]
end

;; set the speed variable of the car to an appropriate value (not exceeding the
;; speed limit) based on whether there are cars on the patch in front of the car
to set-speed [ delta-x delta-y ]  ;; turtle procedure
  ;; get the turtles on the patch in front of the turtle
  let turtles-ahead turtles-at delta-x delta-y

  ;; if there are turtles in front of the turtle, slow down
  ;; otherwise, speed up
  ifelse any? turtles-ahead
  [
    ifelse any? (turtles-ahead with [ up-car? != [up-car?] of myself ])
    [
      set speed 0
    ]
    [
      set speed [speed] of one-of turtles-ahead
      slow-down
    ]
  ]
  [ speed-up ]
end

;; decrease the speed of the turtle
to slow-down  ;; turtle procedure
  ifelse speed <= 0  ;;if speed < 0
  [ set speed 0 ]
  [ set speed speed - acceleration ]
end

;; increase the speed of the turtle
to speed-up  ;; turtle procedure
  ifelse speed > speed-limit
  [ set speed speed-limit ]
  [ set speed speed + acceleration ]
end

;; set the color of the turtle to a different color based on how fast the turtle is moving
to set-car-color  ;; turtle procedure
  ifelse speed < (speed-limit / 2)
  [ set color blue ]
  [ set color cyan - 2 ]
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Procedimientos de los peatones ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; =================================================================================================
;; Controla el movimiento de los peatones en la simulación (desde caminar normalmente hasta cruzar)
;; ------------------------------------------------------------------------------------------------
    to mover-peatones
      ask peatones [  
        ifelse tiempo-caminata >= tiempo-para-cruzar [                           ;; si ya el agente peatón debe buscar cruzar la calle
          if cruce >= 1[                                                         ;; si el agente se encuentra sobre el punto de espera
            cruzar-la-calle                                                      ;; puede cruzar la calle
            stop
          ]
          if tipo = "punto-espera" [                                             ;; cuando llega a un punto de espera el peatón se dispone a cruzar
            set cruce 1
          ]
          face min-one-of patches with [tipo = "punto-espera"] [distance myself] ;; el peatón busca el punto de espera más cercano
          caminar
        ]
        [caminar]                                                         
      ] 
    end
;; =================================================================================================

;; ==========================================================================================================
;; Controla la caminata por aceras o rectifica el rumbo de los peatones si caminan por un punto no permitido
;; ---------------------------------------------------------------------------------------------------------
    to caminar
      ;; los peatones pueden caminar solo por las aceras o los puntos de espera
      ;; cada vez que el peatón avanza se aumenta el tiempo de caminata en una unidad
      
      ifelse [tipo] of patch-ahead 1 = "acera" or [tipo] of patch-ahead 1 = "punto-espera" [
        ifelse any? other peatones-on patch-ahead 1[
          rt random 45
          lt  random 45
          set tiempo-caminata tiempo-caminata + 1 
        ]
        [fd velocidad / 200 set tiempo-caminata tiempo-caminata + 1]
      ]  
      
      ;; sino modifica su rumbo hasta un patch permitido
      [ 
        rt random 120
        lt random 120
        if [tipo] of patch-ahead 1 = "acera" or [tipo] of patch-ahead 1 = "punto-espera" [
          fd velocidad / 200
        ]
        set tiempo-caminata tiempo-caminata + 1
      ] 
    end
;; ==========================================================================================================

;; ==========================================================================================
;; Controla el proceso de cruzar la calle de los peatones cuando acaba su tiempo de caminata
;; -----------------------------------------------------------------------------------------
    to cruzar-la-calle
      if cruce = 1[
        face min-one-of patches with [tipo = "paso-peatonal"] in-radius 4 [distance myself]        ;; se asigna el paso peatonal más cercano por el cual el peatón debe cruzar
        set cruce 2                                                                                ;; el peatón está listo para realizar el cruce
      ]
      
      ;; cuando el peatón está sobre el paso peatonal asignado, prepara su posición para cruzar   
      if tipo = "paso-peatonal" and cruce = 2 [                                                    
        if heading > 315 and heading < 45 [set heading 0]
        if heading > 45 and heading < 135 [set heading 90]
        if heading > 135 and heading < 225 [set heading 180]
        if heading > 225 and heading < 315 [set heading 270]
        rt 195
        lt 195
        set cruce 3
      ] 
      
      ;; se reinician las variables 'tiempo-caminata' y 'cruce' porque ya se llegó al punto de espera contrario (ya se cruzó la calle)
      if cruce = 3 and tipo = "punto-espera" [ 
        rt 195
        lt 195
        set cruce 0
        set tiempo-caminata 0
      ]
      
      ;; avanza hacia adelante
      fd velocidad / 200      
    end
;; ==========================================================================================
@#$#@#$#@
GRAPHICS-WINDOW
625
10
1463
629
34
24
12.0
1
12
1
1
1
0
1
1
1
-34
34
-24
24
1
1
1
ticks
30.0

SLIDER
108
35
205
68
grid-size-y
grid-size-y
1
9
5
1
1
NIL
HORIZONTAL

SLIDER
12
35
106
68
grid-size-x
grid-size-x
1
9
5
1
1
NIL
HORIZONTAL

SWITCH
12
107
107
140
power?
power?
0
1
-1000

SLIDER
12
71
293
104
num-cars
num-cars
1
400
51
1
1
NIL
HORIZONTAL

BUTTON
224
202
288
235
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
0

BUTTON
208
35
292
68
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
11
177
165
210
speed-limit
speed-limit
0
1
1
0.1
1
NIL
HORIZONTAL

MONITOR
176
115
281
160
Current Phase
phase
3
1
11

SLIDER
11
143
165
176
ticks-per-cycle
ticks-per-cycle
1
100
26
1
1
NIL
HORIZONTAL

SLIDER
146
256
302
289
current-phase
current-phase
0
99
0
1
1
%
HORIZONTAL

BUTTON
9
292
143
325
Change light
change-current
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
9
256
144
289
current-auto?
current-auto?
0
1
-1000

BUTTON
145
292
300
325
Select intersection
choose-current
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
215
180
248
num-of-people
num-of-people
0
300
48
1
1
NIL
HORIZONTAL

SLIDER
7
328
179
361
tiempo-para-cruzar
tiempo-para-cruzar
100
2000
221
1
1
NIL
HORIZONTAL

MONITOR
954
10
1112
55
Hora
hora
17
1
11

INPUTBOX
346
173
451
233
autos-por-retirar
0
1
0
Number

INPUTBOX
454
173
568
233
autos-por-ingresar
0
1
0
Number

INPUTBOX
467
233
594
293
peatones-por-ingresar
0
1
0
Number

INPUTBOX
346
233
464
293
peatones-por-retirar
0
1
0
Number

PLOT
12
368
213
518
Autos detenidos
Tiempo
Autos detenidos
0.0
100.0
0.0
100.0
true
false
"set-plot-y-range 0 num-cars" ""
PENS
"default" 1.0 0 -16777216 true "" "plot num-cars-stopped"

PLOT
220
369
421
519
Promedio velocidad autos
Tiempo
Promedio velocidad
0.0
100.0
0.0
1.0
true
false
"set-plot-y-range 0 speed-limit" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [speed] of turtles"

PLOT
426
369
623
519
Promedio tiempo espera autos
Tiempo
Promedio espera
0.0
100.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [wait-time] of turtles"

SWITCH
365
78
562
111
simulacion-predeterminada?
simulacion-predeterminada?
0
1
-1000

INPUTBOX
468
113
623
173
ticks-por-hora
100
1
0
Number

INPUTBOX
312
113
467
173
hora-inicio
5
1
0
Number

@#$#@#$#@
## SIMULACIÓN MULIAGENTE

Problema: NetLogo no cuenta con representaciones de tráfico particularmente precisas.
Objetivo general: Adaptar el modelo de simulación de tráfico que contiene la plataforma NetLogo incluyendo variaciones más realistas.
Objetivos específicos:
  - Agregar pasos peatonales al modelo de simulación.
  - Agregar un modelo de creación de automóviles más dinámico.

## AGENTES Y OBJETOS

Peatones: se movilizan por las aceras y pasos peatonales. Tienen interacción solamente con los automóviles, ya que no se implementa pasos peatonales con
semáforos.
Vehículos: cuentan con vías (calles y avenidas) de un solo sentido dentro de las cuales se pueden movilizar siempre y cuando no existan obstáculos (luces rojas o peatones).
Semáforos: son diseñados como objetos ligados a un control de tiempo.
Pasos peatonales: medio de cruce de los peatones representado por un área coloreada.
Calles y avenidas: medio por el cual se movilizan los autos.

## ¿CÓMO UTILIZARLA?

Lo primero a configurar en la simulación son los valores iniciales de la cantidad de peatones y automóviles. Esto se puede lograr mediante los sliders que indican dichas cantidades (se debe tener en cuenta que una gran cantidad de automóviles y peatones pueden saturar la simulación y provocar errores en NetLogo; por lo tanto, se recomienda utilizar números razonables o incrementar el tamaño del mundo para evitar esta situación). A continuación, seleccionar el botón de "Setup" y comprobar que el mundo fue creado bajo los parámetros deseados.
Una vez seleccionadas estas cantidades se debe elegir el modo. La simulación propuesta tiene dos modos que pueden ser activados mediante el switch "simulacion-predeterminada". Si se activa la simulación predeterminada, se simularán las horas pico en el sistema, incrementando y decrementando la cantidad de peatones y automóviles durante las horas del día indicadas en el monitor de horas. Esta es una simulación de aproximadamente un día (dependiendo de los valores aleatorios que se generen para una determinada ejecución) y se pueden apreciar los cambios gracias a las gráficas que se actualizan en tiempo real. Si no se activa este modo, se deberán ingresar dos valores más en las cajas de texto debajo del switch: hora de inicio y cantidad de ticks por hora. Estos dos valores permiten que el usuario pueda controlar la simulación de manera más personalizada. El monitor de hora se actualizará de acuerdo a la cantidad de ticks por hora que ingrese el usuario y la hora de inicio permite iniciar la simulación en la hora del día que el usuario desee (en "hora militar"). En este caso, la hora no influirá en la cantidad de tráfico o peatones, sin embargo, es útil para que el usuario monitoree el desarrollo de los mismos. Posteriormente, el usuario podrá agregar y retirar automóviles y peatones como desee, con las cajas de texto debajo de las mencionadas anteriormente, lo cual se registrará en las gráficas de la simulación.
Finalmente, cuando todos los parámetros han sido inicializados correctamente, es necesario presionar el botón "Go" y la simulación comenzará a ejecutarse. Es importante mencionar que si la simulación predeterminada sobrepasa las 24 horas y aún existen autos dentro del mundo, se reiniciará el contador de horas, es decir, volverá a iniciar un nuevo día. Esta simulación culminará cuando no queden automóviles dentro del mundo; no obstante, la simulación controlada por el usuario terminará sólamente cuando él lo indique, pues es él el encargado de controlar los cambios externos que sufrirá el mundo.
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

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

containerh
false
0
Rectangle -7500403 false true 75 0 225 300
Rectangle -7500403 true true 75 0 225 300
Line -16777216 false 210 300 210 0
Line -16777216 false 90 300 90 0
Line -16777216 false 90 150 210 150
Line -16777216 false 90 180 210 180
Line -16777216 false 90 210 210 210
Line -16777216 false 90 60 210 60
Line -16777216 false 90 30 210 30
Line -16777216 false 90 270 210 270
Line -16777216 false 90 240 210 240
Line -16777216 false 90 90 210 90
Line -16777216 false 90 120 210 120

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

paso-peatonal
false
0
Rectangle -7500403 true true 30 30 255 255
Rectangle -16777216 true false 60 60 240 240
Rectangle -7500403 true true 90 60 90 195
Line -7500403 true 90 60 90 255
Rectangle -7500403 true true 90 60 105 240
Rectangle -7500403 true true 135 60 150 255
Rectangle -7500403 true true 180 60 195 240
Rectangle -7500403 true true 240 45 255 255
Rectangle -7500403 true true 225 45 255 240
Rectangle -7500403 true true 30 255 255 270

paso-peatonal-horizontal
false
0
Rectangle -7500403 false true 0 75 300 225
Rectangle -1184463 true false 0 0 330 435
Line -16777216 false 0 270 300 270
Line -16777216 false 0 30 300 30
Line -16777216 false 90 30 90 270
Line -16777216 false 240 30 240 270
Line -16777216 false 60 90 60 210
Line -16777216 false 210 90 210 210
Rectangle -16777216 true false 60 30 90 270
Rectangle -16777216 true false 210 30 240 270
Rectangle -16777216 true false 135 30 165 270

paso-peatonal-vertical
false
0
Rectangle -7500403 false true 75 0 225 300
Rectangle -1184463 true false 0 -30 435 300
Line -16777216 false 270 300 270 0
Line -16777216 false 30 300 30 0
Line -16777216 false 30 210 270 210
Line -16777216 false 30 60 270 60
Line -16777216 false 30 240 270 240
Line -16777216 false 30 90 270 90
Rectangle -16777216 true false 30 210 270 240
Rectangle -16777216 true false 30 60 270 90
Rectangle -16777216 true false 30 135 270 165

peaton
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

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

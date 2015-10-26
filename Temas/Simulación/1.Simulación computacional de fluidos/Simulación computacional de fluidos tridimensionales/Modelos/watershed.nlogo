; Watershed Model and Terrain Generator
; Version 1.1.2
; James Steiner

globals
[ ; levels-changed ; obsolete, used to flag if levels changed, to notify 3d update
  peak  ; the highest level of all the patches
  middle ; the mean of the elev and level
  valley ; the lowest elev of all the patches
  spread ; the difference between the valley and peak
  vm ; the valley-middle line, used for coloring
  pm ; the peak-middle line, used for coloring
  ; both of the above normally equal to spread and peak
  tics ; count of flow-frames rendered, for by-eye estimation of fram rate
]

breeds
[ backdrops ; the backdrop of the 3d inset window
  nodes     ; the points of the 3d rendering
] 

nodes-own
[ my-patch ; the source patch linked to this node
  ox oy oe ; original coordinates
  px py pel ; projected coordinates
  pre-hide? ; part of the projection process
]

patches-own
[ elev   ; "surface" level
  level  ; "water" level, equals elev when dry
         ; may never be less than elev
  volume ; level - elev, the depth of the water, or the volume of water
  temp   ; used for various things
  temp2
  temp3
  water-in
  water-out
  neighbors-nowrap ; the neighbors, without edge-wrapping
]

to startup
;     river-valley
end

to update-all
  ; apply color and, if required, labels
  no-display    ; freeze display while updating
  color-all ; apply color
  label-all ; apply labels
  display       ; refresh display
  ; set levels-changed 1
end

to dry-all
  ; resets the "water" level to the elevation
  ; effectively drying the landscape
  ask patches
  [ set level elev ]
  calc-measures
  update-all
end

to diffuse-elev-nowrap 
  ask patches
  [ set level .5 * ( elev + mean values-from neighbors-nowrap [ elev ] )
  ]
  ask patches
  [ set elev level
  ]
end

to define-neighbors-nowrap
  ask patches
  [ set neighbors-nowrap neighbors in-radius-nowrap 2
  ]
end
  

to river-valley
  locals
  [ lump-size
    num-lumps
  ]
  ; generates a passable simulation of the elevations of a river valley
  ; flowing north to south
  clear-turtles
  clear-patches
  define-neighbors-nowrap
  if presets?
  [ set river? true
    set drain? true
    set erupt? false
    set source-rate 2
    set altitude? false
    set scale .5
    set shift-x .45
    set shift-y .45
  ]
  note "creating valley contours"
  ; impress a valley shape
  ; store in LEVEL
  ask patches
  [ do-valley
  ] 

  set valley min values-from patches [ level ]
  set peak max values-from patches [ level ]
  if valley = peak
  [ set valley valley - 2
    set peak peak + 2
  ]
  set spread peak - valley

  ;adjust valley to 0 .. 1
  ask patches
  [ set elev ( level - valley ) / spread  * screen-edge-x]
  
  note "adding random lumps"
  dry-all wait .5
  
  
  set num-lumps  sqrt (screen-size-x * screen-size-y) * ( 1 - lumpiness * .01 )
  ask random-n-of num-lumps patches
  [ set lump-size 1 + screen-edge-x * .01 * (random-float lumpiness)
    without-interruption
    [ ask patches in-radius-nowrap lump-size
      [ set elev elev + lump-size  - ( distance-nowrap myself )
      ]
    ]
  ]
  
  note "tilting landscape"
  dry-all wait .5

  ; tilt the landscape so everything runs downhill
  ; slope set by steepness
  ask patches
  [ set elev elev + (pycor / screen-edge-y ) * spread * steepness * .02 ]

  note ""
  dry-all

end


to normalize-elev
  ; set min to 0, max to 100
  calc-measures
  ask patches 
  [ ; set min to 0
    set elev (elev - valley ) 
    ; set max to screen-edge-x
    set elev elev * 100 / spread
  ]
  ; adjust valley, peak, spread, middle
  set valley 0
  set peak screen-edge-x
  set spread screen-edge-x
end

to do-valley 
   locals
   [ elev-east-west
     elev-north-south
     elev-meander
     px%
     py%
     adj-px%
     px-cos
     sweep-width
     meander-freq
     pwr
   ]
   set pwr 1
   set px%       pxcor / screen-edge-x ; pxcor ==> -1 .. 1
   set py%       1 - ( pycor + screen-edge-y ) / screen-size-y ; pycor ==> 0 .. 1
   set sweep-width  .01 * meander% ; .25 + .25 * sin ( py% * 45 )
   set meander-freq  py% * 180 * 4
   set adj-px% ( (px% + sweep-width * sin ( meander-freq ) ) )
   set elev-meander (abs adj-px%) 
   set level elev-meander
   ; set elev elev * ( 1 - scale) + level * elev-meander * scale
end
  
  
to calc-measures
  ; caluclate peak, valley, spread 
  set peak max values-from patches [ elev ]
  set valley min values-from patches [ elev ]
  if peak = valley
  [ set peak peak + 2
    set valley valley - 2
  ]
  set middle (peak + valley) * .5
  set spread abs ( peak - valley )
  set vm (valley + middle) * 0.5
  set pm (peak + middle) * 0.5
  
end
    
to add-wall
  ; add wall along back / top to prevent water
  ; from flowing backwards wrapping from bottom, etc.

  ; first, caluclate peak, valley, spread 
  set peak max values-from patches [ elev ]
  set valley min values-from patches [ elev ]
  set spread abs ( peak - valley )
  ; use values to elevate back edge %10 of depth of model
  
  ask patches with [ pycor = screen-edge-y ]
  [ set elev peak + spread * .1 ]

  ; scale it up
  ; ask patches
  ; [ set elev elev * 1000 ]

  dry-all

end

to add-dam
  locals [ height spillway ]
  ; adds a dam-like structure to the map
  
  set height 1.3 * mean values-from patches [ elev ]
  set spillway  elev-of patch 0 0 + ( height - elev-of patch 0 0 ) * .5
  
  ask patches with [ pycor = 0 and abs pxcor < screen-edge-x / 2.0 and elev < height ]
  [ set elev height ]
  ask patch 0 0
  [ set elev spillway ]
  dry-all
end
  
to volcano
   locals [ deepest peaks ]
   ; build an irregular, circular island
   ; with a shallow center lagoon
   ; "clear patches"
   cp
   clear-3d
   define-neighbors-nowrap
   if presets?
   [ set river? false
     set drain? false
     set erupt? true
     set source-rate 50
     set altitude? true
     set scale .5
     set shift-x .45
     set shift-y .45
   ]
   
   ; "create overall ring shape"
   ask patches
   [ ; get distance from center
     ; "doing math"
     
     set temp distancexy 0 0 
     ; sin wave, 0 at center, peak in middle, 0 at corners
     set temp3 temp * 360 / 3 / screen-edge-x
     ; scale as distance from edge
     set temp2  2 * sin ( temp * 180 / screen-edge-x ) * ( screen-edge-x - abs pxcor) / screen-edge-x * ( screen-edge-y - abs pycor) / screen-edge-y
     set elev screen-size-x * sin temp3 * temp2
   ]
 
   
   ; "add random peaks and dips, repeat"
   repeat screen-edge-x
   [ ; "picking peak/pit location"
     set elev-of patch 0 0 (- screen-size-x)
     set peaks random-n-of screen-edge-x patches
     ; "talking to peaks"
     ask peaks
     [ ; "set temp"
       set temp random 2 * 2 - 1 ]
    ; "talking to peaks"
    ask peaks
     [ ; "set elev"
       without-interruption
       [ set elev elev + screen-edge-x * temp
       ]
     ]
   ]
   ; erode, just a bit
   repeat 4
   [ set elev-of patch 0 0 (- screen-edge-x)
     diffuse-elev-nowrap
   ]

   ; add "stress ridges"
  ask patches
  [ ; get distance from center
    set temp distancexy 0 0
    ; get angle from center
    ifelse temp = 0
    [ set temp2 0 ]
    [ set temp2 ( towardsxy 0 0 + 180 ) 
      if temp2 > 360
      [ set temp2 temp2 - 360 ]
    ]
    ; set number of ridges
    set temp3 temp2 * screen-edge-x / 3
    set elev elev + screen-edge-x * sin temp3 * sin temp * .2
  ]   
   dry-all
end

to rain
   ; add water to entire surface, using rain-rate slider
   ; adds depth of rain that is up to 1/10000 the height of the terrain
   ask patches
   [ set level level + rain-rate * spread * .0001 ]
   update-all

end ; rain 

to rain-hard
   ; adds depth of rain that is up to 1/1000 height of terrain
   
   ask patches
   [ set level level + rain-rate * spread * .001 ]
   update-all

end ; rain-hard

to do-sources-and-drains
  ; adds water at top center of window
  if river?
  [ ask min-one-of patches with [ pycor = ( screen-edge-y - 1 ) ] [ elev ]
    [ set level level + source-rate
    ]
  ]
  if erupt?
  [ ask patch 0 0
    [ set level level + source-rate ]
  ]
  if drain?
  [ ; removes water from bottom
    ask patches with [ pycor = (- screen-edge-y) ]
    [ set level level - volume * .1 
    ]
  ]
end ; do-sources-and-drains

to evaporate-all
   ; reduce water level by "evap rate"
   ; which is linear and not proportional
   ; as it is due to surface area, not volume
      
   if e-rate > 0 and evap?
   [ ask patches with [ level > elev ] 
     [ set level level - e-rate
       if level < elev
       [ ; don't allow level to be below elev!
         set level elev
       ]
     ]
   ]

end ; evaporate-all

to flow-all
  evaporate-all
  ; to reduce flow bias created by natural netlogo patch code scheduling, 
  ; only update 1 in 5 patches every turn
  ask patches with [ level > elev  and random 3 = 0 ]
  [ flow-ver-2 ]
  ask patches [ set level level - water-out + water-in set water-out 0 set water-in 0 ]
  ; add water every 5 turns
  ;if tics mod 5 = 0
  ;[ 
    do-sources-and-drains
    update-all
  ;]
  set tics tics + 1
  if tics > 1000000 [ set tics 0 ]
end

to flow-ver-1
; if any neighbors with lower  level
; pick random one of neigbors with LOWEST  level
; move 1/2 of difference in level to that neighbor
; (so both are at a level)
  locals 
  [ local-min 
    min-level
    extra
    portion
    max-portion
  ]
  without-interruption
  [
  if level - elev > 0
  ; if I am wet...
  [ set min-level min values-from (neighbors-nowrap) [ level ]
    if level > min-level
    [ set local-min random-one-of (neighbors-nowrap) with [ level = min-level ]
      set extra level - min-level
      ifelse extra < .001
      ; if less than 1/1000 unit, it all flows down
      [ set portion extra
      ]
      [ set portion extra * .5 
        ; if portion is more than is here, just take all of it
        if portion > ( level - elev )
        [ set portion level - elev
        ]
      ]
      ; adjust the levels
      set level level - portion
      ask local-min 
      [ set level level + portion
      ]
    ]    
  ]
  ]
end

to flow-ver-2
; pick random one of neigbors with LOWEST level (lower than me!)
; move "flow-rate" (50%) of difference in level to that neighbor
; 
  locals 
  [ local-min 
    min-level
    extra
    portion
    max-portion
    low-neighbors
    count-low-neighbors
    slope
  ]
   if level - elev > 0
  ; if I am wet...
  [ set min-level min values-from (neighbors-nowrap) [ level ]
    if level > min-level
    [ set local-min random-one-of (neighbors-nowrap) with [ level = min-level ]
      set extra level - min-level
      ; set slope atan 1 extra 
      ifelse extra < .001
      ; if less than 1/1000 unit, it all flows down
      [ set portion extra
      ]
      [ set portion extra * flow-rate
        ; if portion is more than is here, just take all of it
        if portion > ( level - elev )
        [ set portion level - elev
        ]
      ]
      ; adjust the levels
      set water-out portion
      set water-in-of local-min (water-in-of local-min) + portion
    ]    
  ]
end


to label-all
  ; are labels requested?
  ifelse labels?
  [ ; yes. labels are requested
    ; ; altitude, or water depth?
    ifelse altitude?
    [ ; ; altitude / surface level
      ask patches
      [ set plabel (int (level))
      ]
    ]
    [ ; show depth
      ask patches 
      [ set plabel (int (level - elev))
      ]
    ]
  ]
  [ ; no labels
    ; does patch 1 1 have a label?
    if plabel-of patch 1 1 != no-label
    [ ; it does, implying that all patches have labels.
      ; so, clear all labels
      ask patches [ set plabel no-label ]
    ]
    ; this would seem to be faster than clearing all the labels every cycle
  ]
end

to color-all

   ifelse hide-water?
  [ ; use elev, not level, for display, and don't show water colors
    ifelse false-color?
    [ ; color using rainbow, to show-off contours
      ask patches [ set pcolor 20 + 7 * scale-color gray elev valley peak ]
    ]
    [ ask patches [ set pcolor get-earth-color ]
    ]
  ]
  [ ; use level for display, using water colors as needed.
    ask patches [ set volume level - elev ]
    ifelse false-color?
    [ ; color using rainbow, to show off contours
      ask patches [ set pcolor 20 + 7 * scale-color gray level valley peak ]
    ]
    [ ask patches [ set pcolor get-color ]
    ]
  ]
end

to-report get-color-from [ agent ]
  locals [ result ]
  ask agent [ set result get-color ]
  report result
end

to-report get-color ; patch procedure
  ifelse volume <= 0
  [ report get-earth-color ]
  [ report get-water-color ]
end

to-report get-water-color ; patch procedure
locals [ scaled-color ]
  ifelse altitude? 
  [ set scaled-color -4 + .8 * scale-color gray level  valley peak   ]
  [ set scaled-color  4 - .8 * scale-color gray volume 0      spread ]
  ifelse erupt? or volume < .01
  [ report red + scaled-color  ]
  [ report blue + scaled-color ]
end

to-report get-earth-color ; patch procedure
  ifelse elev <= vm
  [ report gray - 4 + .8 * scale-color gray elev valley middle ]
  [ ifelse elev <= pm
    [ report green - 4 + .8 * scale-color gray elev valley peak ]
    [ report brown - 4 + .8 * scale-color gray elev middle peak ]
  ]
end

to setup-3d
  clear-turtles
  ; create a turtle to use as a backdrop to hide the patches
  ; (instead of coloring the patches black)
  create-custom-backdrops 1
  [ setxy 0 0
    set color black + 1
    set shape "box-large"
    set size screen-size-x
  ]
  ; these turtles, one for each patch
  ; show the points of elevation
  ask patches
  [ ; make a node turtle
    sprout 1
    [ set breed nodes
      set my-patch patch-here
      set color pcolor
      set shape "circle-large"
      set size 1.0
      set heading 0
      set ox xcor
      set oy ycor
      set oe level
    ]
  ]
  render-3d
end
 
to render-3d
  locals [ insetx insety insetw inseth insett insetl insetb insetr]
  if not any? backdrops [ stop ]
  set insetx screen-edge-x * shift-x
  set insety screen-edge-y * shift-y
  set insetw screen-edge-x * scale
  set inseth screen-edge-y * scale
    
  no-display
  ask backdrops
  [ setxy insetx insety
    set size insetw * 2.1
  ]
  ask nodes
  [ set oe level-of my-patch
    set color pcolor-of my-patch
    ; scale elevation so screen-edge-x cubic volume fits into 1/2 screen-height
    set pel ( oe - valley ) / screen-size-x * screen-edge-y - screen-edge-y * .5
    ; spin X
    set px ox * cos spin + oy * sin spin
    ; spin and tilt Y
    set py (oy * cos spin - ox * sin spin) * cos tilt + pel * sin tilt
    ; scale and adjust center
    set px px * scale 
    set py py * scale
    set pre-hide? ( abs px > insetw or abs py > inseth)
    set px px + insetx
    set py py + insety
    set hidden? pre-hide? or ( abs px > screen-edge-x or abs py > screen-edge-y ) or (slice-on? and ox != int (screen-edge-x * slice)) 
    setxy px py
  ]
  display
end

to full-view
set scale 1.0
set shift-x 0
set shift-y 0
set slice 0
set tilt 90
set spin 90
set spin? false
set presets? false

end 
 
to render-3d-no-slice
  locals [ insetx insety insetw inseth insett insetl insetb insetr]
  if not any? backdrops [ stop ]
  set insetx screen-edge-x * shift-x
  set insety screen-edge-y * shift-y
  set insetw screen-edge-x * scale
  set inseth screen-edge-y * scale
    
  no-display
  ask backdrops
  [ setxy insetx insety
    set size insetw * 2.1
  ]
  ask nodes
  [ set oe level-of my-patch
    set color pcolor-of my-patch
    ; scale elevation so screen-edge-x cubic volume fits into 1/2 screen-height
    set pel ( oe - valley ) / screen-size-x * screen-edge-y - screen-edge-y * .5
    ; spin X
    set px ox * cos spin + oy * sin spin
    ; spin and tilt Y
    set py (oy * cos spin - ox * sin spin) * cos tilt + pel * sin tilt
    ; scale and adjust center
    set px px * scale 
    set py py * scale
    set pre-hide? ( abs px > insetw or abs py > inseth)
    set px px + insetx
    set py py + insety
    set hidden? pre-hide? or ( abs px > screen-edge-x or abs py > screen-edge-y )
    setxy px py
  ]
  if size-of one-of nodes != scale * 2 [ ask nodes [ set size scale * 2 ] ]
  display
end

to clear-3d
   ask backdrops [ die ]
   ask nodes [ die ]
   update-all
end


to note [ text ]
   ask patch 0 0
   [ ifelse text = ""
     [ set plabel no-label ]
     [ set plabel text ]
   ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
649
470
16
16
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

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
NetLogo 5.1.0
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

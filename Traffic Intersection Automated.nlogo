globals [
  ticks-at-last-change  ; value of the tick counter the last time a light changed
  active-queue          ;* the queue that is currently being processed
  west-queue            ;* the car queue for the west-east lane
  south-queue           ;* the car queue for the south-north lane
  west-light            ;*
  south-light           ;*
  total-accident        ;*
]

breed [ lights light ]

breed [ accidents accident ]
accidents-own [
  clear-in              ; how many ticks before an accident is cleared
]

breed [ cars car ]
cars-own [
  speed                 ; how many patches per tick the car moves
  wait-ticks            ;* how many ticks the car has been in the queue for
]

;;;;;;;;;;;;;;;;;;;;
;;SETUP PROCEDURES;;
;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  set-default-shape lights "square"
  set-default-shape accidents "fire"
  set-default-shape cars "car"

  ; initialise queues (lists) for both lanes
  set west-queue [] ;*
  set south-queue [] ;*
  set active-queue south-queue ;*

  ask patches [
    ifelse abs pxcor <= 1 or abs pycor <= 1
      [ set pcolor black ]     ; the roads are black
      [ set pcolor green - 1 ] ; and the grass is green
  ]
  ask patch 0 -1 [ sprout-lights 1 [ set color green ] ]
  ask patch -1 0 [ sprout-lights 1 [ set color red ] ]
  
  set west-light lights at-points [[-1 0]] ;*
  set south-light lights at-points [[0 -1]] ;*
  
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;
;;RUNTIME PROCEDURES;;
;;;;;;;;;;;;;;;;;;;;;;

to go
  ask cars [ move ]
  check-for-collisions
  set west-queue filter-queue west-queue ;*
  set south-queue filter-queue south-queue ;*
;  set west-queue 
;        if west-queue = active-queue and member? self west-queue[ ;*
;        set west-queue remove self west-queue ;*
;      ] 
;      if south-queue = active-queue and member? self south-queue[ ;*
;        set south-queue remove self south-queue ;*
;      ]
  set south-queue make-new-car freq-north 0 min-pycor 0 south-queue ;*
  set west-queue make-new-car freq-east min-pxcor 0 90 west-queue ;*

  update-active-queue ;*

  if traffic-light?[ ;*
    ; if we are in "auto" mode and a light has been
    ; green for long enough, we turn it yellow
    if auto? and elapsed? green-length [
      change-to-yellow
    ]
    
    ; if a light has been yellow for long enough,
    ; we turn it red and turn the other one green
    if any? lights with [ color = yellow ] and elapsed? yellow-length [
      change-to-red
    ]
  ]
  tick
end

to-report filter-queue [queue];*
  set queue filter [c -> c != nobody] queue ;*
  ask turtles with [member? self queue][ ;*
    ifelse queue = west-queue[ ;*
      if pxcor > -1 [ set queue remove self queue ] ;*
    ][
      if pycor > -1 [ set queue remove self queue ] ;*
    ]
  ]
  report queue ;*
end

; update the active queue if the cum wait time of the passive queue
; exceeds the cum wait time of the active queue
to update-active-queue ;*

  ; sum the values of the 'wait-ticks' variable for the first 'eval-cars' in the provided queue
  let south-cum-wait sum [wait-ticks] of turtles with [member? self south-queue] ;*
  let west-cum-wait  sum [wait-ticks] of turtles with [member? self west-queue] ;*

  show south-queue
  show west-queue

  ifelse west-cum-wait > south-cum-wait ;*
  [ 
    set active-queue west-queue ;*
    if not traffic-light? [ ;*
      ask west-light [ set color green ] ;*
      ask south-light [ set color red ] ;*
    ]
  ]
  [ 
    set active-queue south-queue  ;*
    if not traffic-light? [ ;*
      ask south-light [ set color green ] ;*
      ask west-light [ set color red ] ;*
    ]
  ]
end

to-report make-new-car [ freq x y h queue]
  if (random-float 100 < freq) and not any? turtles-on patch x y [
    create-cars 1 [
      setxy x y
      set heading h
      set color one-of base-colors
      set queue lput self queue ; add car at end of queue ;*
      adjust-speed
    ]
  ]
  report queue ;*
end

to move ; turtle procedure
  adjust-speed
  update-wait-ticks ;*
  repeat speed [ ; move ahead the correct amount
    fd 1
    if not can-move? 1 [ die ] ; die when I reach the end of the world
    if any? accidents-here [
      ; if I hit an accident, I cause another one
      ask accidents-here [ set clear-in 5 ]
      die
    ]
  ]
end

to update-wait-ticks ;*
  ifelse is-waiting [ ;*
    set wait-ticks wait-ticks + 1 ;*
  ][
    set wait-ticks 0 ;*
  ]
end

; check if the car is in the non-active queue and its speed is 0
to-report is-waiting ;*
  report ;*
    (member? self west-queue or member? self south-queue) ;*
    and not member? self active-queue ;*
    and speed = 0 ;*
end ;*

to adjust-speed

  ; calculate the minimum and maximum possible speed I could go
  let min-speed max (list (speed - max-brake) 0)
  let max-speed min (list (speed + max-accel) speed-limit)

  let target-speed max-speed ; aim to go as fast as possible

  let blocked-patch next-blocked-patch
  if blocked-patch != nobody [
    ; if there is an obstacle ahead, reduce my speed
    ; until I'm sure I won't hit it on the next tick
    let space-ahead (distance blocked-patch - 1)
    while [
      breaking-distance-at target-speed > space-ahead and
      target-speed > min-speed
    ] [
      set target-speed (target-speed - 1)
    ]
  ]

  set speed target-speed

end

to-report breaking-distance-at [ speed-at-this-tick ] ; car reporter
  ; If I was to break as hard as I can on the next tick,
  ; how much distance would I have travelled assuming I'm
  ; currently going at `speed-this-tick`?
  let min-speed-at-next-tick max (list (speed-at-this-tick - max-brake) 0)
  report speed-at-this-tick + min-speed-at-next-tick
end

to-report next-blocked-patch ; turtle procedure
  ; check all patches ahead until I find a blocked
  ; patch or I reach the end of the world
  let patch-to-check patch-here
  while [ patch-to-check != nobody and not is-blocked? patch-to-check ] [
    set patch-to-check patch-ahead ((distance patch-to-check) + 1)
  ]
  ; report the blocked patch or nobody if I didn't find any
  report patch-to-check
end

to-report is-blocked? [ target-patch ] ; turtle reporter
  report
    any? other cars-on target-patch or
    any? accidents-on target-patch or
    any? (lights-on target-patch) with [ color = red ] or
    (any? (lights-on target-patch) with [ color = yellow ] and
      ; only stop for a yellow light if I'm not already on it:
      target-patch != patch-here)
end

to check-for-collisions
  ask accidents [
    set clear-in clear-in - 1
    if clear-in = 0 [ die ]
  ]
  ask patches with [ count cars-here > 1 ] [
    sprout-accidents 1 [
      set size 1.5
      set color yellow
      set clear-in 5
    ]
    set total-accident total-accident + 1 ;*
    ask cars-here [ die ]
  ]
end

to change-to-yellow
  ask lights with [ color = green ] [
    set color yellow
    set ticks-at-last-change ticks
  ]
end

to change-to-red
  ask lights with [ color = yellow ] [
    set color red
    ask other lights [ set color green ]
    set ticks-at-last-change ticks
  ]
end

; reports `true` if `time-length` ticks
; has elapsed since the last light change
to-report elapsed? [ time-length ]
  report (ticks - ticks-at-last-change) > time-length
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
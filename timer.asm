.dseg
Timer_THRESHOLD: .byte 2



.cseg
; TODO vai precisar de interrupcao



Timer_Delay:
  push YH
  push YL

  ; Reset Timer/Counter value
  ldi temp, 0
  out TCNT1H, temp
  out TCNT1L, temp

  ; Load timer threshold in temp and temp2
  ldi YH, HIGH(Timer_THRESHOLD)
  ldi YL, LOW (Timer_THRESHOLD)

  ; temp2 = Timer_THRESHOLD_H
  ; temp  = Timer_THRESHOLD_L
  ld temp2, Y+
  ld temp, Y

  ; Start timer

  pop YL
  pop YH
  ret
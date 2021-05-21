.dseg
Timer_ENDLOOPLAG: .byte 1

.cseg
; TODO vai precisar de interrupcao

Timer_Init:
  ldi temp, 0
  sts Timer_ENDLOOPLAG, temp

  ; Preserve context and disable interrupts
  lds  temp3, SREG
  cli

  ; Normal operation
  ldi temp, 0
  sts TCCR1A, temp

  ; CS1 == b000: timer is not running  
  ; WGM12 == 1:  CTC mode
  ldi temp, (1<<WGM12)
  sts TCCR1B, temp

  ; We won't use any configuration o TCCR1C
  ldi temp, 0
  sts TCCR1C, temp

  ; Sets initial value of OCR1A to 255
  ldi temp2, 0x00
  ldi temp,  0xFF
  sts OCR1AH, temp
  sts OCR1AL, temp

  ; Resets timer
  ldi temp, 0
  sts TCNT1H, temp
  sts TCNT1L, temp

  ; Enable output compare interrupt with OCR1A
  ldi temp, (1<<OCIE1A)
  sts TIMSK1, temp
  
  ; Restore context
  sts SREG, temp3
  ret


Timer_Delay:
  ; Starts timer with clk = io clock / 64 (~256kHz)
  ldi temp, (1<<WGM12)|(1<<CS11)|(1<<CS10)
  sts TCCR1B, temp

Timer_Delay_loop:
  lds  temp, Timer_ENDLOOPLAG
  cpi  temp, 1
  brne Timer_Delay_loop
  ldi  temp, 0
  sts  Timer_ENDLOOPLAG, temp
  ret


TIM1_COMPA:
  ; Stop timer
  ldi temp, (1<<WGM12)
  sts TCCR1B, temp

  ldi temp, 1
  sts Timer_ENDLOOPLAG, temp
  reti
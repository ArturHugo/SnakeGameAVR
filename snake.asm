.dseg
; cabeca  -> 6 bits
; tail    -> 6 bits
; direcao -> 2 bits
Snake_HEAD: .byte 1
Snake_TAIL: .byte 1
Snake_FOOD: .byte 1
; Snake_DIR: 0 = right
;            1 = up
;            2 = left
;            3 = down
Snake_DIR:  .byte 1
Snake_LEN:  .byte 1
; Snake_BODY(0) = Snake_TAIL
; Snake_BODY(Snake_LEN - 1) = Snake_HEAD
Snake_BODY: .byte 64

Snake_ERASETAILFLAG: .byte 1
Snake_SPAWNFOODFLAG: .byte 1
Snake_GAMEOVERFLAG:  .byte 1

.equ Snake_RIGHT = 4
.equ Snake_UP    = 1
.equ Snake_LEFT  = 2
.equ Snake_DOWN  = 3

.cseg
Snake_Init:
  push YH
  push YL

  ldi YH, HIGH(Snake_LEN)
  ldi YL, LOW (Snake_LEN)
  ldi temp, 1
  st  Y, temp

  ldi YH, HIGH(Snake_DIR)
  ldi YL, LOW (Snake_DIR)
  ldi temp, Snake_RIGHT
  st  Y, temp

  ldi YH, HIGH(Snake_HEAD)
  ldi YL, LOW (Snake_HEAD)
  ldi temp, 2
  st  Y, temp

  ldi YH, HIGH(Snake_TAIL)
  ldi YL, LOW (Snake_TAIL)
  ldi temp, 2
  st  Y, temp

  ldi YH, HIGH(Snake_BODY)
  ldi YL, LOW (Snake_BODY)
  ldi temp, 2
  st  Y, temp

  ldi YH, HIGH(LEDMatrix_DISPLAYDATA)
  ldi YL, LOW (LEDMatrix_DISPLAYDATA)
  ldi temp, 0x04
  st  Y, temp

  ldi YH, HIGH(Snake_FOOD)
  ldi YL, LOW (Snake_FOOD)
  ldi temp, 30
  st  Y, temp

  ldi YH, HIGH(Snake_ERASETAILFLAG)
  ldi YL, LOW (Snake_ERASETAILFLAG)
  ldi temp, 1
  st  Y, temp

  ldi YH, HIGH(Snake_SPAWNFOODFLAG)
  ldi YL, LOW (Snake_SPAWNFOODFLAG)
  ldi temp, 1
  st  Y, temp

  ldi YH, HIGH(Snake_GAMEOVERFLAG)
  ldi YL, LOW (Snake_GAMEOVERFLAG)
  ldi temp, 0
  st  Y, temp

  pop YL
  pop YH
  ret

; TODO Talvez isso tenha que ficar dentro de uma ISR de timer para
; acelerar a taxa de atualizacao dos frames a cada vez que a cobra aumentar
Snake_DrawFrame:
  ; If SPAWNFOODFLAG = 1: spawn food  and clear SPAWNFOODFLAG
  lds   temp, Snake_SPAWNFOODFLAG
  cpi   temp, 0
  breq  Snake_DrawFrame_moveHead
  rcall Snake_SpawnFood
  
  ; Clear SPAWNFOODFLAG
  ldi temp, 0
  sts Snake_SPAWNFOODFLAG, temp

Snake_DrawFrame_moveHead:
  ; Set erase tail flag (it will be cleared if snake eats food)
  ldi temp, 1
  sts Snake_ERASETAILFLAG, temp

  rcall Snake_MoveHead

  ; If head is in a coordinate that was already set:
  ;    If it was food: set SPAWNFOODFLAG and clear ERASETAILFLAG
  ;    Else: game over
  lds  temp, Snake_HEAD
  lds  temp2, Snake_FOOD
  cp   temp, temp2
  brne Snake_DrawFrame_eraseTail

  ; Set SPAWNFOODFLAG
  ldi temp, 1
  sts Snake_SPAWNFOODFLAG, temp

  ; Grow Snake_LEN and clear ERASETAILFLAG
  lds temp, Snake_LEN
  inc temp
  sts Snake_LEN, temp

  ldi temp, 0
  sts Snake_ERASETAILFLAG, temp

Snake_DrawFrame_eraseTail:
  rcall Snake_EraseTail
  
  ; Check game over conditions
  rcall Snake_CheckGameOver
  lds   temp, Snake_GAMEOVERFLAG
  cpi   temp, 1
  brne  Snake_DrawFrame_end

Snake_DrawFrame_gameOver:
  ; TODO coisas no game over
  rcall LEDMatrix_Clear
  rcall Delay
  rcall LEDMatrix_WriteDisplay
  rcall Delay
  rcall LEDMatrix_Clear
  rcall Delay
  rcall LEDMatrix_WriteDisplay
  rcall Delay
  rcall LEDMatrix_Clear
  rcall Delay
  rcall LEDMatrix_WriteDisplay
  rcall Delay

  ; rcall Snake_HandleGameOver

Snake_DrawFrame_end:
  ret

; TODO fazer cabecalho da subrotina
Snake_EraseTail:
  push YH
  push YL
  push XH
  push XL

  ; Get current position of snake's tail
  ldi YH, HIGH(Snake_TAIL)
  ldi YL, LOW (Snake_TAIL)
  ld  col, Y
  ld  colmask, Y

  ; Calculate in which column the tail is
  lsr col
  lsr col
  lsr col

  ; Access the column in the LED matrix display data memory region
  ldi YH, HIGH(LEDMatrix_DISPLAYDATA)
  ldi YL, LOW (LEDMatrix_DISPLAYDATA)
  add YL, col
  ldi temp, 0
  adc YH, temp

  ; Sets the mask to the tail LED that should be erased in the column
  lsl col
  lsl col
  lsl col
  mov temp, colmask
  sub temp, col
  ldi colmask, 1

  rcall Snake_MakeMask
  
  ; Invert mask to clear tail with and operation
  com colmask

  lds  temp, Snake_ERASETAILFLAG
  cpi  temp, 0
  breq Snake_EraseTail_end

  ; Get the current state of the column
  ld temp, Y

  ; Clear tail bit and writes back to display data memory
  and temp, colmask
  st  Y, temp

  ; Update Snake_TAIL
  ldi  YH, HIGH(Snake_BODY)
  ldi  YL, LOW (Snake_BODY)
  mov  XH, YH
  mov  XL, YL
  adiw X, 1
  ld   temp, X
  sts  Snake_TAIL, temp 

  ; Loop to erase tail in snake body and update segment positions
  lds  temp, Snake_LEN
Snake_EraseTail_loop:
  ; Swap: BODY(i) <- BODY(i+1)
  ; X = i+1 and Y = i
  ; temp2 receives BODY(X)
  ; and then, we store temp2 in BODY(Y)
  ld   temp2, X
  st   Y, temp2
  dec  temp
  breq Snake_EraseTail_end
  adiw X, 1
  adiw Y, 1
  rjmp Snake_EraseTail_loop

Snake_EraseTail_end:
  pop XL
  pop XH
  pop YL
  pop YH
  ret

; TODO fazer cabecalho da subrotina
Snake_MoveHead:
  push YH
  push YL
  push XH
  push XL

  ; Get current position of snake's head
  ldi YH, HIGH(Snake_HEAD)
  ldi YL, LOW (Snake_HEAD)
  ld  col, Y
  ld  colmask, Y

  ; Calculate in which column the head is
  lsr col
  lsr col
  lsr col

  ; Access the column in the LED matrix display data memory region
  ldi YH, HIGH(LEDMatrix_DISPLAYDATA)
  ldi YL, LOW (LEDMatrix_DISPLAYDATA)
  add YL, col
  ldi temp, 0
  adc YH, temp
  
  ; Sets the mask to the head LED that should be set in the column
  mov temp2, col
  lsl temp2
  lsl temp2
  lsl temp2
  mov temp, colmask
  sub temp, temp2
  ldi colmask, 1
  
  rcall Snake_MakeMask

  ; Check snake's current direction
  ; If right:  col += 1
  ; If left:   col -= 1
  ; If up:     colmask << 1
  ; If down:   colmask >> 1
  ; TODO verificar ser a cobrinha nao ta batendo na parede

  ldi XH, HIGH(Snake_DIR)
  ldi XL, LOW (Snake_DIR)
  ld  temp, X

  cpi temp, Snake_RIGHT
  breq Snake_MoveHead_right
  cpi temp, Snake_LEFT
  breq Snake_MoveHead_left
  cpi temp, Snake_UP
  breq Snake_MoveHead_up
  cpi temp, Snake_DOWN
  breq Snake_MoveHead_down
  
Snake_MoveHead_right:
  adiw Y, 1
  inc  col
  
  ; Check if snake hit right wall
  cpi  col, 8
  brne Snake_MoveHead_right_end
  ldi  col, 0
  sbiw Y, 8

Snake_MoveHead_right_end:
  rjmp Snake_MoveHead_end

Snake_MoveHead_left:
  sbiw Y, 1
  dec  col

  ; Check if snake hit left wall
  brbc SREG_N, Snake_MoveHead_right_end
  ldi  col, 7
  adiw Y, 8

Snake_MoveHead_left_end:
  rjmp Snake_MoveHead_end

Snake_MoveHead_up:
  lsl  colmask

  ; Check if snake hit top wall
  cpi  colmask, 0
  brne Snake_MoveHead_up_end
  ldi  colmask, BIT0

Snake_MoveHead_up_end:
  rjmp Snake_MoveHead_end

Snake_MoveHead_down:
  lsr colmask

  ; Check if snake hit bottom wall
  cpi  colmask, 0
  brne Snake_MoveHead_end
  ldi  colmask, BIT7

Snake_MoveHead_end:
  ; Get the current state of the column and updates column data
  ld temp, Y
  or temp, colmask
  st Y, temp

  ; Atualiza Snake_HEAD
  ldi temp, 0
Snake_MoveHead_updateHead_loop:
  lsr  colmask
  breq Snake_MoveHead_updateHead_continue
  inc  temp
  rjmp Snake_MoveHead_updateHead_loop

Snake_MoveHead_updateHead_continue:
  ; Update Snake_HEAD: temp2 = col*8, temp = col % 8
  mov temp2, col
  lsl temp2
  lsl temp2
  lsl temp2
  add temp, temp2
  ldi YH, HIGH(Snake_HEAD)
  ldi YL, LOW (Snake_HEAD)
  st  Y,  temp

  ; Get snake length
  ldi YH, HIGH(Snake_LEN)
  ldi YL, LOW (Snake_LEN)
  ld  temp2, Y

  ; Get base address of Snake_BODY
  ldi YH, HIGH(Snake_BODY)
  ldi YL, LOW (Snake_BODY)

Snake_MoveHead_getToNewHeadPositionInBody:
  ; Increments Y until position in BODY where we want to append new head
  adiw Y, 1
  dec  temp2
  brne Snake_MoveHead_getToNewHeadPositionInBody

  ; Appends new head to body
  st Y, temp

  pop XL
  pop XH
  pop YL
  pop YH
  ret

; Snake_MakeMask
; Arguments:
;   - colmask register with value 1
;   - temp register with the number of times to shift colmask
; Returns: colmask as a mask with only BIT<temp> set
Snake_MakeMask:
  ; Loop to shift colmask to the right position of the masked bit
  cpi  temp, 0
  breq Snake_MakeMask_continue
  dec  temp
  lsl  colmask
  rjmp Snake_MakeMask
Snake_MakeMask_continue:
  ret


Snake_ChangeDirection:
  ; If usart_data == 'd':
  ;    If DIR != LEFT: DIR = RIGHT
  ; If usart_data == 'w':
  ;    If DIR != DOWN: DIR = UP
  ; If usart_data == 'a':
  ;    If DIR != RIGHT: DIR = LEFT
  ; If usart_data == 's':
  ;    If DIR != UP: DIR = DOWN
  cpi  usart_data, 'd'
  breq Snake_ChangeDirection_right
  cpi  usart_data, 'w'
  breq Snake_ChangeDirection_up
  cpi  usart_data, 'a'
  breq Snake_ChangeDirection_left
  cpi  usart_data, 's'
  breq Snake_ChangeDirection_down

Snake_ChangeDirection_right:
  lds  temp, Snake_DIR
  cpi  temp, Snake_LEFT
  breq Snake_ChangeDirection_end
  ldi  temp, Snake_RIGHT
  sts  Snake_DIR, temp
  rjmp Snake_ChangeDirection_end

Snake_ChangeDirection_up:
  lds  temp, Snake_DIR
  cpi  temp, Snake_DOWN
  breq Snake_ChangeDirection_end
  ldi  temp, Snake_UP
  sts  Snake_DIR, temp
  rjmp Snake_ChangeDirection_end

Snake_ChangeDirection_left:
  lds  temp, Snake_DIR
  cpi  temp, Snake_RIGHT
  breq Snake_ChangeDirection_end
  ldi  temp, Snake_LEFT
  sts  Snake_DIR, temp
  rjmp Snake_ChangeDirection_end

Snake_ChangeDirection_down:
  lds  temp, Snake_DIR
  cpi  temp, Snake_UP
  breq Snake_ChangeDirection_end
  ldi  temp, Snake_DOWN
  sts  Snake_DIR, temp

Snake_ChangeDirection_end:
  ret

Snake_SpawnFood:
  ; Get a random position to spawn the food
  rcall RNG_GetNumber
  mov   col, rng_reg
  
  ; Make coordinate be in range 0 to 63
  andi col, 0x3f
  mov  colmask, col

  ; Keeps food coordinate to update Snake_FOOD in the end
  mov temp3, col

  ; Get column index
  lsr col
  lsr col
  lsr col

  ; Access the column in the LED matrix display data memory region
  ldi YH, HIGH(LEDMatrix_DISPLAYDATA)
  ldi YL, LOW (LEDMatrix_DISPLAYDATA)
  add YL, col
  ldi temp, 0
  adc YH, temp
  
  ; Sets the mask to the food LED that should be set in the column
  mov temp2, col
  lsl temp2
  lsl temp2
  lsl temp2
  mov temp, colmask
  sub temp, temp2
  ldi colmask, 1
  
  rcall Snake_MakeMask

  ; temp2 and temp = current column state
  ld  temp, Y
  mov temp2, temp

  ; If there is a bit already set where we want to spawn food, try again
  and  temp, colmask
  brne Snake_SpawnFood

  ; Set food LED in DISPLAYDATA
  or temp2, colmask
  st Y, temp2

  ; Update Snake_FOOD
  ldi YH, HIGH(Snake_FOOD)
  ldi YL, LOW (Snake_FOOD)
  st  Y, temp3
  ret


;TODO
Snake_CheckGameOver:
  ; Iterate through Snake_BODY up until the last byte (previous HEAD)
  ; If new head is equal to any byte in body other then itself
  ; it is a game over
  push YH
  push YL

  ; Load Snake_BODY base address
  ldi YH, HIGH(Snake_BODY)
  ldi YL, LOW (Snake_BODY)

  ; temp  = coordinate of snake's current head
  ; temp2 = length of snake's body
  lds temp, Snake_HEAD
  lds temp2, Snake_LEN

  ; So we dont compare snake's head with itself
  dec temp2

Snake_CheckGameOver_loop:
  ; If temp2 == 0: end loop
  cpi  temp2, 0
  breq Snake_CheckGameOver_end

  ; Compare current segment coordinate with head's coordinate
  ld   temp3, Y+
  cp   temp3, temp
  breq Snake_CheckGameOver_setFlag
  dec  temp2
  rjmp Snake_CheckGameOver_loop

Snake_CheckGameOver_setFlag:
  ldi temp, 1
  sts Snake_GAMEOVERFLAG, temp

Snake_CheckGameOver_end:
  pop YL
  pop YH
  ret
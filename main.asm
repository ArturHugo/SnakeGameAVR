;;;;TODO Roadmap de amanha e depois:
; [OK] Spawnar frutinha
; [  ] Aumentar velocidade do jogo com timer (usar timer na rotina de delay e reduzir threshold
; quando a cobrinha comer uma fruta)
; [OK] Verificar se frutinha foi comida e aumentar a cobra
; [OK] Verificar condicao de game over (head acertou body)
; [OK] Verificar bordas (ver se eh melhor dar game over ou loop no display)
;
; SnakeGame.asm
;
; Created: 30-Apr-21 11:57:49
; Author : User
;
.cseg
.org 0x0000
  ; ldi temp, (1<<CLKPCE)
  ; sts CLKPR, temp
  ; ldi temp, (1<<CLKPS2)
  ; sts CLKPR, temp
  ldi rng_reg, 0x16
  jmp Setup

.org 0x0016
  jmp TIM1_COMPA

.org 0x0024
  jmp USART_RXC

;==========
; Includes:
.nolist
.include "m328Pdef.inc"
.include "./spi.asm"
.include "./usart.asm"
.include "./ledmatrix.asm"
.include "./rng.asm"
.include "./snake.asm"
.include "./timer.asm"
.list

;==============
; Declarations:
.equ BIT0 = 0x01
.equ BIT1 = 0x02
.equ BIT2 = 0x04
.equ BIT3 = 0x08
.equ BIT4 = 0x10
.equ BIT5 = 0x20
.equ BIT6 = 0x40
.equ BIT7 = 0x80

; Registers
.def temp  = r16
.def temp2 = r20
.def temp3 = r21
.def temp4 = r22
.def colmask = r24
.def col = r23

;=============
; Subroutines:
.cseg

Setup:
  rcall LEDMatrix_ClearDisplayData
  rcall Snake_Init
  ; rcall Snake_DrawFrame
  ; rcall Snake_DrawFrame
  ; rcall Snake_DrawFrame

  rcall Timer_Init

  rcall USART_Init
  rcall SPI_MasterInit
  sei

  ldi   spi_data,     DISPLAYTEST_ADDRESS
  ldi   spi_data_low, 0
  rcall SPI_MasterTransmitWord

  ldi   spi_data,     SCANLIMIT_ADDRESS
  ldi   spi_data_low, 0x07
  rcall SPI_MasterTransmitWord

  ldi   spi_data,     DECODEMODE_ADDRESS
  ldi   spi_data_low, NO_DECODE
  rcall SPI_MasterTransmitWord

  ldi   spi_data,     SHUTDOWN_ADDRESS
  ldi   spi_data_low, shutdown
  rcall SPI_MasterTransmitWord

  ldi   spi_data,     SHUTDOWN_ADDRESS
  ldi   spi_data_low, normal_operation
  rcall SPI_MasterTransmitWord

  ldi   spi_data,     INTENSITY_ADDRESS
  ldi   spi_data_low, 0x00
  rcall SPI_MasterTransmitWord

  ; rcall LEDMatrix_ClearDisplayData

Main:
  rcall Timer_Delay 

Draw_RandomPointInDisplay:

  rcall Snake_DrawFrame

  rcall LEDMatrix_WriteDisplay

  rcall Timer_Delay 

end:
  rjmp Main

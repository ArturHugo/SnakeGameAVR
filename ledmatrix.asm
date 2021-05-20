;==============
; Data segment:
.dseg
LEDMatrix_DISPLAYDATA: .byte 8

;==============
; Declarations:
.equ NOOP_ADDRESS        = 0x00
.equ DIGIT0_ADDRESS      = 0x01
.equ DIGIT1_ADDRESS      = 0x02
.equ DIGIT2_ADDRESS      = 0x03
.equ DIGIT3_ADDRESS      = 0x04
.equ DIGIT4_ADDRESS      = 0x05
.equ DIGIT5_ADDRESS      = 0x06
.equ DIGIT6_ADDRESS      = 0x07
.equ DIGIT7_ADDRESS      = 0x08
.equ DECODEMODE_ADDRESS  = 0x09
.equ INTENSITY_ADDRESS   = 0x0A
.equ SCANLIMIT_ADDRESS   = 0x0B
.equ SHUTDOWN_ADDRESS    = 0x0C
.equ DISPLAYTEST_ADDRESS = 0x0F

.equ NO_DECODE      = 0x00
.equ CODE_B_FOR_0   = 0x01
.equ CODE_B_FOR_LSN = 0x0F
.equ CODE_B_FOR_ALL = 0xFF

.equ shutdown         = 0
.equ normal_operation = 1

;============
; Subroutines
.cseg

; LEDMatrix_Clear
; Arguments: none
; Returns: none
; Description: clears LED matrix display
LEDMatrix_Clear:
  ldi temp, DIGIT7_ADDRESS
LEDMatrix_Clear_loop:
  mov   spi_data, temp
  ldi   spi_data_low, 0
  rcall SPI_MasterTransmitWord
  dec   temp
  brne  LEDMatrix_Clear_loop
  ret

; LEDMatrix_ClearDisplayData
; Arguments: none
; Returns: none
; Description: clears LEDMatrix_DISPLAYDATA memory area
LEDMatrix_ClearDisplayData:
  push YH
  push YL
  ldi YH, HIGH(LEDMatrix_DISPLAYDATA)
  ldi YL, LOW (LEDMatrix_DISPLAYDATA)
  ldi temp, 0
  st  Y+, temp
  st  Y+, temp
  st  Y+, temp
  st  Y+, temp
  st  Y+, temp
  st  Y+, temp
  st  Y+, temp
  st  Y+, temp
  pop YL
  pop YH
  ret

; LEDMatrix_WriteDisplay
; Arguments:
;   - data segment LEDMatrix_DISPLAYDATA
; Returns: none
; Description: transmits diplay data to the LED matrix via SPI
LEDMatrix_WriteDisplay:
  ; Preserve context
  push YH
  push YL

  ldi temp, DIGIT7_ADDRESS
  ldi YH, HIGH(LEDMatrix_DISPLAYDATA)
  ldi YL, LOW (LEDMatrix_DISPLAYDATA)
LEDMatrix_WriteDisplay_loop:
  mov   spi_data, temp
  ld    spi_data_low, Y+
  rcall SPI_MasterTransmitWord
  dec   temp
  brne  LEDMatrix_WriteDisplay_loop

  ; Restore context
  pop YL
  pop YH
  ret
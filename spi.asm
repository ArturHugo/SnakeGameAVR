;==============
; Declarations:
.equ SPI_PORT   = PORTB
.equ SPI_SS     = PB1
.equ DDR_SPI    = DDRB
.equ DD_SCK     = DDB5
.equ DD_MOSI    = DDB3
.equ DD_SS      = DDB1
.equ SPI_CONFIG = (1<<SPE)|(1<<MSTR)|(1<<SPR1)|(1<<SPR0)

; Registers
.def spi_data      = r17
.def spi_data_low  = r18

;=============
; Subroutines:
.cseg

; SPI_MasterInit
; Arguments: none
; Returns: none
; Description: configures SPI device as master
SPI_MasterInit:
  ; Keeps SS dedicated pin as output high
  sbi PORTB, PB2
  sbi DDRB,  DDB2
  ; Drives SS high (SS low means start of transmission)
  sbi SPI_PORT, SPI_SS
  ; Sets SS pin as output
  sbi DDR_SPI, DD_SS
  ; Configures SPI control register
  ldi temp, SPI_CONFIG
  out SPCR, temp
  ; Set SCK, MOSI and SS pins as output
  sbi DDR_SPI, DD_SCK
  sbi DDR_SPI, DD_MOSI
  ret

; SPI_MasterTransmitByte
; Arguments:
;   - spi_data: register with the byte to be transmited
; Returns: none
; Description: transmists one byte of data through SPI
SPI_MasterTransmitByte:
  ; Start transmission of data (spi_data)
  out SPDR, spi_data
SPI_MasterTransmitByte_wait:
  ; Wait for transmission complete
  in   spi_data, SPSR
  sbrs spi_data, SPIF
  rjmp SPI_MasterTransmitByte_wait
  ret

; SPI_MasterTransmitWord
; Arguments:
;   - spi_data:     register with the most significant byte of the word
;   - spi_data_low: register with the leat significant byte of the word
; Returns: none
; Description: transmists one word of data through SPI
SPI_MasterTransmitWord:
  ; Drives SS' low to start transmission
  cbi SPI_PORT, SPI_SS
  rcall SPI_MasterTransmitByte
  mov   spi_data, spi_data_low
  rcall SPI_MasterTransmitByte
  sbi   SPI_PORT, SPI_SS
  ret

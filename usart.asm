;==============
; Declarations:
.equ BAUDRATE_H = 0
.equ BAUDRATE_L = 103

.def usart_data = r25

;=============
; Subroutines:
USART_Init:
  ; Set baud rate
  ldi temp, BAUDRATE_H
  sts UBRR0H, temp
  ldi temp, BAUDRATE_L
  sts UBRR0L, temp
  ; Enable receiver and transmitter
  ldi temp, (1<<RXEN0)|(1<<TXEN0)|(1<<RXCIE0)
  sts UCSR0B, temp
  ; Set frame format: 8data, 2stop bit
  ldi temp, (1<<USBS0)|(3<<UCSZ00)
  sts UCSR0C, temp
  ret

USART_Transmit:
  ; Wait for empty transmit buffer
  lds  temp, UCSR0A
  sbrs temp, UDRE0
  rjmp USART_Transmit
  ; Put data (usart_data) into buffer, sends the data
  sts UDR0, usart_data
  ret

USART_Receive:
  ; Wait for data to be received
  lds  temp, UCSR0A
  sbrs temp, RXC0
  rjmp USART_Receive
  ; Get and return received data from buffer
  lds usart_data, UDR0
  ret

USART_RXC:
  lds   usart_data, UDR0
  rcall Snake_ChangeDirection
  ; rcall USART_Transmit
  ldi   usart_data, 0
  reti
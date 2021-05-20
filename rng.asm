.def rng_reg = r19
.cseg
; RNG_GetNumber
; Arguments: none
; Returns: rng_reg(5..0)
; Description: generates pseudo random 6-bit number in rng_reg with lfsr
RNG_GetNumber:
  ldi  temp, 1
  ldi  temp2, 1
  sbrc rng_reg, 6
  eor  temp2, temp
  sbrc rng_reg, 5
  eor  temp2, temp
  sbrc rng_reg, 4
  eor  temp2, temp
  sbrc rng_reg, 0
  eor  temp2, temp

  lsr  rng_reg
  sbrc temp2, 0
  ori  rng_reg, 0x80
  ret

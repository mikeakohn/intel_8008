.8008

.org 0x4000
start:
  ;; Set HL (also called M) to 0x8008.
  ;; This is the address of the IO port.
  mvi h, 0x80
  mvi l, 0x08

  ;; d = value of LED.
  mvi d, 1
main:
  mov M, d

  ;; Loop c to cause delay.
  mvi c, 0
delay:
  dcr c
  jnz delay

  inr d
  jmp main 


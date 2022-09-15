.8008

// This could have been written with 3 instructions, but writing it
// this way to exercise the CPU.
.org 0x4000
main:
  in 0
  cpi 1
  jnz no_button
  mvi a, 1
  out 8
  jmp main

no_button:
  mvi a, 0
  out 8
  jmp main


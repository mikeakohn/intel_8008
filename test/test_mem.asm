.8008

block_ram_test:
  mvi h, 0xc0
  mvi l, 0x00
  mvi M, 0x55

  mvi h, 0xc0
  mvi l, 0x01
  mvi M, 0xaa

  mvi h, 0xc0
  mvi l, 0x00
  mov a, M
  hlt


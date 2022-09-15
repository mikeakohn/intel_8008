.8008

immediate:
  mvi h, data >> 8
  mvi l, data & 0xff
  mvi a, 0x80
  ora M
  hlt

  mvi a, 128
  adi 1
  hlt

  mvi a, 0xff
  adi 1
  mvi b, 1
  adc b
  hlt

data:
  .db 0x20


#!/usr/bin/env python3

import sys

if len(sys.argv) != 2:
  print("Usage: python3 create_rom.py <prog.bin>")
  sys.exit(0)

address = 0

fp = open(sys.argv[1], "rb")

while True:
  a = fp.read(1)
  if not a: break
  a = int.from_bytes(a, "big")

  print("     %d: data <= 8'h%02x;" % (address, a))
  address += 1

fp.close()


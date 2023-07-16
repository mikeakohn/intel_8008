#!/usr/bin/env python3

import sys

indent = "     "
address = 0

fp = open(sys.argv[1], "r")

for line in fp:
  if not "cycles" in line: continue
  line = line.strip()
  line = line.split("         ")[0].strip()
  line = line[8:]
  opcodes = line[:6].strip()
  code = line[6:].strip()
  print(indent + "// " + code)

  opcodes = opcodes.split()

  for opcode in opcodes:
    print(indent + str(address) + ": data <= 8'h" + opcode + ";")
    address += 1

fp.close()


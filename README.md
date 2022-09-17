Soft Core Intel 8008
====================

This is an Intel 8008 CPU implemented in an FPGA.

https://www.mikekohn.net/micro/intel_8008_fpga.php

Differences
===========

A couple things are different from an actual Intel 8008.

* PC is 16 bit (instead of 14 bit on the original chip).
* Hardcoded ROM program or load program from an AT93C86A EEPROM.
* in / out are mapped to 0x4000/0x4008.

Registers
=========

* 0: A (accumulator)
* 1: B
* 2: C
* 3: D
* 4: E
* 5: H
* 6: L

Internally there is an HL register which is simply { H, L }. The
HL register is used as indirect memory access when the assembly
language uses M instead of a register. When encoding instructions
that have a source or destination as a register, M (aka [HL]) is
encoded as register 7.

Flags
=====
* zero   (set if ALU result is 0)
* carry  (set if ALU result requires bit 8)
* sign   (set if ALU result sets bit 7)
* party  (set if count of ALU bits set to 1 are even)

Instructions
============

CPU control
-----------
    00 000 00x    hlt
    11 111 111    hlt

Input / Output
-------------

In this implementation:

  MMM is equalent to address 0x8000 + (0 to 7).
RRMMM is equalent to address 0x8000 + (8 to 31).

    01 00M MM1    in   (A = port[MMM])
    01 RRM MM1    out  (port[RRMMM] = A, RR != 00)

Jump / Call
-----------

All intructions are 3 byte and the 2 byte address is always absolute
instead of relative.

    01 xxx 100    jmp address (jump always)
    01 000 000    jnc address (jump if carry=0)
    01 001 000    jnz address (jump if zero=0, not zero)
    01 010 000    jp  address (jump if sign=0, positive)
    01 011 000    jpo address (jump if parity=0, odd)
    01 100 000    jc  address (jump if carry=1)
    01 101 000    jz  address (jump if zero=1)
    01 110 000    jm  address (jump if sign=1, negative)
    01 111 000    jpe address (jump if parity=1, even)

    01 xxx 110    call address (call always)
    01 000 010    cnc  address (call if carry=0)
    01 001 010    cnz  address (call if zero=0, not zero)
    01 010 010    cp   address (call if sign=0, positive)
    01 011 010    cpo  address (call if parity=0, odd)
    01 100 010    cc   address (call if carry=1)
    01 101 010    cz   address (call if zero=1)
    01 110 010    cm   address (call if sign=1, negative)
    01 111 010    cpe  address (call if parity=1, even)

Return From Subroutine
----------------------

    00 xxx 111    ret  (return always)
    00 000 010    rnc  (return if carry=0)
    00 001 010    rnz  (return if zero=0, not zero)
    00 010 010    rp   (return if sign=0, positive)
    00 011 010    rpo  (return if parity=0, odd)
    00 100 010    rc   (return if carry=1)
    00 101 010    rz   (return if zero=1)
    00 110 010    rm   (return if sign=1, negative)
    00 111 010    rpe  (return if parity=1, even)

    00 AAA 101    rst  (call subroutine at AAA000)

Load / Store
------------

Immediate instrutions are 2 byte. M represents the data pointed to by [HL].
No flags are affected.

    11 DDD SSS    mov d, s   (load d with content of s)
    11 DDD 111    mov d, M   (load d with content of memory pointed to by [HL])
    11 111 SSS    mov M, s   (load memory pointed to by [HL] with s)

    00 DDD 110    mvi d, imm (load d with immediate value)
    00 111 110    mvi M, imm (load memory pointed to by [HL] with immediate value)

ALU
---

Immediate instrutions are 2 byte. M represents the data pointed to by [HL].
All flags are affected.

    10 000 sss    add s    (A = A + s)
    10 001 sss    adc s    (A = A + s + carry)
    10 010 sss    sub s    (A = A - s)
    10 011 sss    sbb s    (A = A - s + carry)
    10 100 sss    ana s    (A = A & s)
    10 101 sss    xra s    (A = A ^ s)
    10 110 sss    ora s    (A = A | s)
    10 111 sss    cmp s    (A - s  don't store result in A)

    10 000 111    add M    (A = A + [HL])
    10 001 111    adc M    (A = A + [HL] + carry)
    10 010 111    sub M    (A = A - [HL])
    10 011 111    sbb M    (A = A - [HL] + carry)
    10 100 111    ana M    (A = A & [HL])
    10 101 111    xra M    (A = A ^ [HL])
    10 110 111    ora M    (A = A | [HL])
    10 111 111    cmp M    (A - [HL]  don't store result in A)

    00 000 sss    adi imm  (A = A + imm)
    00 001 sss    adi imm  (A = A + imm + carry)
    00 010 sss    sui imm  (A = A - imm)
    00 011 sss    sbi imm  (A = A - imm + carry)
    00 100 sss    ani imm  (A = A & imm)
    00 101 sss    xri imm  (A = A ^ imm)
    00 110 sss    ori imm  (A = A | imm)
    00 111 sss    cpi imm  (A - imm  don't store result in A)

Increment / Decrement
-------------------

Note: If d is the A register (register 0) it will conflict with
the hlt instruction which is 00 000 00x).

    00 ddd 000    inr d   (d = d + 1, cannot be A)
    00 ddd 001    dcr d   (d = d - 1, cannot be A)

Shift / Rotate
--------------

Only carry flag is affected.

    00 000 010    rlc    (rotate A left,  shift into bit 0: 0)
    00 001 010    rlc    (rotate A right, shift into bit 7: 0)
    00 010 010    ral    (rotate A left,  shift into bit 0: carry)
    00 011 010    rar    (rotate A right, shift into bit 7: carry)

Memory Map
----------

This implementation of the Intel 8008 has 4 banks of memory.

* Bank 0: RAM (256 bytes)
* Bank 1: ROM (An LED blink program from blink.asm)
* Bank 2: Peripherals
* Bank 3: Empty

On start-up by default, the chip will load a program from a AT93C86A
2kB EEPROM with a 3-Wire (SPI-like) interface but wll run the code
from the ROM. To start the program loaded to RAM, the program select
button needs to be held down while the chip is resetting.

The peripherals area contain the following:

* 0x8000: input from push button
* 0x8008: ioport0 output (in my test case only 1 pin is connected)
* 0x8009: MIDI note value (60-96) to play a tone on the speaker or 0 to stop


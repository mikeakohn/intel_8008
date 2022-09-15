;; AT93C86A EEPROM Programmer
;;
;; Copyright 2022 - By Michael Kohn
;; https://www.mikekohn.net/
;; mike@mikekohn.net
;;
;; Copy Intel 8008 firmware to 3-wire EEPROM so it can be loaded from
;; the IceFUN FPGA.

.include "msp430x2xx.inc"

RAM equ 0x0200

EEPROM_CS equ 0x01
EEPROM_SK equ 0x02
EEPROM_DI equ 0x04
EEPROM_DO equ 0x08

;  r4 = Interrupt counter
;  r5 =
;  r6 =
;  r7 =
;  r8 =
;  r9 =
; r10 =
; r11 =
; r12 =
; r13 = temp in main
; r14 = function param
; r15 = function param and return value

.org 0xf800
start:
  ;; Turn off watchdog
  mov.w #WDTPW|WDTHOLD, &WDTCTL

  ;; Turn off interrupts
  dint

  ;; Setup stack pointer
  mov.w #0x0280, SP

  ;; Set MCLK to 1.0 MHz with DCO
  mov.b #DCO_3, &DCOCTL
  mov.b #RSEL_7, &BCSCTL1
  mov.b #0, &BCSCTL2

  ;; Setup output pins
  ;; P1.0 = EEPROM CS
  ;; P1.1 = EEPROM SK (CLK)
  ;; P1.2 = EEPROM DI (data output on MSP430)
  ;; P1.3 = EEPROM DO (data input on MSP430)
  mov.b #EEPROM_CS|EEPROM_SK|EEPROM_DI, &P1DIR
  mov.b #0, &P1OUT

  ;; Turn on interrupts
  eint

  mov.w #0x200, r15
memset:
  mov.w #0, 0(r15)
  add.w #2, r15
  cmp.w #0x240, r15
  jnz memset

  ;; Not needed, but it was here from older source.
  call #delay_1s

main:
  call #set_write_enable
  call #send_program
  call #read_program

while_1:
  jmp while_1

;; void send_program()
send_program:
  mov.w #program, r6
  mov.w #program_end-program, r7
  mov.w #0, r8
send_program_next:
  mov.w r8, r15
  mov.b @r6+, r14
  call #write_to_address
  inc.w r8
  dec.w r7
  jnz send_program_next
  ret

;; void read_program()
read_program:
  mov.w #0, r15
  mov.w #32, r14
  call #read_at_address
  ret

;; void set_write_enable()
set_write_enable:
  bis.b #EEPROM_CS, &P1OUT
  mov #0x9800, r15
  mov #14, r14
  call #eeprom_send
  bic.b #EEPROM_CS, &P1OUT
  ret

;; int read_at_address(address=r15, count=r14)
read_at_address:
  mov.w r14, r4
  mov.w #0x200, r5
  bis.b #EEPROM_CS, &P1OUT
  rla.w r15
  rla.w r15
  bis.w #0xc000, r15
  mov.w #14, r14
  call #eeprom_send
read_at_address_next:
  call #eeprom_read_byte
  mov.b r15, 0(r5)
  inc.w r5
  dec.w r4
  jnz read_at_address_next
  bic.b #EEPROM_CS, &P1OUT
  ret

;; int write_to_address(address=r15, value=r14)
write_to_address:
  mov.b r14, r4
  bis.b #EEPROM_CS, &P1OUT
  rla.w r15
  rla.w r15
  bis.w #0xa000, r15
  mov.w #14, r14
  call #eeprom_send
  mov.b r4, r15
  swpb r15
  mov.w #8, r14
  call #eeprom_send
  bic.b #EEPROM_CS, &P1OUT
  nop
  bis.b #EEPROM_CS, &P1OUT
write_to_address_busy:
  bis.b #EEPROM_SK, &P1OUT
  bit.b #EEPROM_DO, &P1IN
  bic.b #EEPROM_SK, &P1OUT
  jz write_to_address_busy
  bic.b #EEPROM_CS, &P1OUT
  ret

;; void eeprom_send(data=r15, bitcount=r14)
eeprom_send:
  rla.w r15
  jnc eeprom_send_not_1
  bis.b #EEPROM_DI, &P1OUT
eeprom_send_not_1:
  bis.b #EEPROM_SK, &P1OUT
  nop
  bic.b #EEPROM_SK, &P1OUT
  bic.b #EEPROM_DI, &P1OUT
  dec.b r14
  jnz eeprom_send
  ret

;; int eeprom_read_byte()
eeprom_read_byte:
  mov.w #0, r15
  mov.w #8, r14
eeprom_read_byte_next:
  rla.w r15
  bis.b #EEPROM_SK, &P1OUT
  bit.b #EEPROM_DO, &P1IN
  jz eeprom_read_byte_0
  bis.b #1, r15
eeprom_read_byte_0:
  bic.b #EEPROM_SK, &P1OUT
  dec.w r14
  jnz eeprom_read_byte_next
  ret

delay_50ms:
  mov.w #467 * 50, r15
delay_loop_50ms:
  dec.w r15
  jnz delay_loop_50ms
  ret

delay_1s:
  mov.w #20, r14
delay_1s_loop:
  call #delay_50ms
  dec.w r14
  jnz delay_1s_loop
  ret

program:
  .binfile "play_song.bin"
program_end:

.org 0xfffe
  dw start                 ; Reset


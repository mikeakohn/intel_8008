
INCLUDE=/usr/local/share/naken_asm/include/msp430

default:
	naken_asm -l -type bin -o play_song.bin -I$(INCLUDE) play_song.asm
	naken_asm -l -o programmer.hex -I$(INCLUDE) programmer.asm

clean:
	@rm -f *.hex *.bin *.lst *.ndbg
	@echo "Clean!"


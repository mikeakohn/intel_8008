.8008

;; Set org to 0x4000 to run from rom.v.
;.org 0x4000
.org 0x0000
main:
  // c = note count in song.
  // HL = pointer to next note.

  call wait_for_button

  mvi c, (march_end - march) / 2
  mvi h, march >> 8
  mvi l, march & 0xff
  call play_song

  call wait_for_button

  mvi c, (trilogy_end - trilogy) / 2
  mvi h, trilogy >> 8
  mvi l, trilogy & 0xff
  call play_song

  call wait_for_button

  mvi c, (intel_end - intel) / 2
  mvi h, intel >> 8
  mvi l, intel & 0xff
  call play_song

  jmp main

wait_for_button:
  in 0
  cpi 1
  jnz wait_for_button
  ret

play_song:
  ;; Turn on LED.
  mvi a, 1
  out 8
  ;; Play current note.
  mov a, M
  out 9
  ;; HM += 1;
  mov a, l
  adi 1
  mov l, a
  mov a, h
  aci 0
  mov h, a
  ;; Get current note delay.
  mov d, M
  ;; HM += 1;
  mov a, l
  adi 1
  mov l, a
  mov a, h
  aci 0
  mov h, a
  ;; Delay for length of note.
play_song_delay:
  mvi b, 200
play_song_delay_inner:
  dcr b
  jnz play_song_delay_inner
  dcr d
  jnz play_song_delay
  ;; Turn off LED.
  mvi a, 0
  out 8
  ;; Delay for little pause between notes.
  mvi a, 0
  out 9
  mvi b, 150
play_song_off_delay:
  dcr b
  jnz play_song_off_delay
  ;; note_count -= 1;
  dcr c
  jnz play_song
  ret

march:
  .db 76, 9, 76, 9, 76, 9, 72, 4, 0, 2, 79, 2, 76, 9, 72, 4, 0, 2,
  .db 79, 2, 76, 9, 0, 9, 83, 9, 83, 9, 83, 9, 84, 4, 0, 2, 79, 2,
  .db 75, 9, 72, 4, 0, 2, 79, 2, 76, 9, 0, 4
march_end:

trilogy:
  .db 81, 2, 84, 2, 88, 2, 81, 2, 84, 2, 88, 2, 83, 2, 86, 2, 89, 2,
  .db 83, 2, 86, 2, 89, 2, 80, 2, 83, 2, 86, 2, 80, 2, 83, 2, 86, 2,
  .db 81, 2, 84, 2, 88, 2, 81, 2, 84, 2, 88, 2, 77, 2, 81, 2, 84, 2,
  .db 77, 2, 81, 2, 84, 2, 78, 2, 81, 2, 84, 2, 78, 2, 81, 2, 84, 2,
  .db 89, 2, 88, 2, 86, 2, 84, 2, 83, 2, 78, 2, 80, 2, 81, 2, 83, 2,
  .db 88, 2, 89, 2, 91, 2
trilogy_end:

intel:
  .db 73, 4, 78, 4, 73, 4, 80, 4
intel_end:


// Intel 8008 FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2022 by Michael Kohn

// This is a hardcoded program that blinks an external LED.

module rom
(
  input  [5:0] address,
  output [7:0] data_out
);

reg [7:0] data;
assign data_out = data;

always @(address) begin
  case (address)
     // mvi h, 0x80
     0: data <= 8'h2e;
     1: data <= 8'h80;
     // mvi l, 0x08
     2: data <= 8'h36;
     3: data <= 8'h08;
     // mvi d, 1
     4: data <= 8'h1e;
     5: data <= 8'h01;
     // mov M, d
     6: data <= 8'hfb;
     // mvi c, 0
     7: data <= 8'h16;
     8: data <= 8'h00;
     // dcr c
     9: data <= 8'h11;
    // jnz 0x4009
    10: data <= 8'h48;
    11: data <= 8'h09;
    12: data <= 8'h40;
    // inr d
    13: data <= 8'h18;
    // jmp 0x4006
    14: data <= 8'h44;
    15: data <= 8'h06;
    16: data <= 8'h40;
    default: data <= 0;
  endcase
end

endmodule


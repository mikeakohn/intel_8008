// Intel 8008 FPGA Soft Processor 
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2022 by Michael Kohn

// This creates 256 bytes of RAM on the FPGA itself.

module ram
(
  input  [8:0] address,
  input  [7:0] data_in,
  output [7:0] data_out,
  input write_enable,
  input clk
);

reg [7:0] storage [256:0];
assign data_out = storage[address];

always @(posedge clk) begin
  if (write_enable)
    storage[address] <= data_in;
end

endmodule


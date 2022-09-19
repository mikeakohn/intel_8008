// Intel 8008 FPGA Soft Processor 
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2022 by Michael Kohn

// The purpose of this module is to route reads and writes to the 4
// different memory banks. Originally the idea was to have ROM and RAM
// be SPI EEPROM (this may be changed in the future) so there would also
// need a "ready" signal that would pause the CPU until the data can be
// clocked in and out of of the SPI chips.

module memory_bus
(
  input [15:0] address,
  input  [7:0] data_in,
  output [7:0] data_out,
  input write_enable,
  input clk,
  input raw_clk,
  output speaker_p,
  output speaker_m,
  output ioport_0,
  input button_0,
  input reset
);

wire [7:0] rom_data_out;
wire [7:0] ram_data_out;
wire [7:0] peripherals_data_out;

reg [7:0] ram_data_in;
reg [7:0] peripherals_data_in;

reg ram_write_enable;
reg peripherals_write_enable;

// Based on the selected bank of memory (address[15:14]) select if
// memory should read from ram.v, rom.v, peripherals.v or hardcoded 0.
assign data_out = address[15] == 0 ?
  (address[14] == 0 ? ram_data_out : rom_data_out) :
  (address[14] == 0 ? peripherals_data_out : 0);

// Based on the selected bank of memory, decided which module the
// memory write should be sent to.
always @(posedge clk) begin
  if (write_enable) begin
    case (address[15:14])
      2'b00:
        begin
          ram_data_in <= data_in;
          ram_write_enable <= 1;
        end
      2'b01:
        begin
          ram_write_enable <= 0;
          peripherals_write_enable <= 0;
        end
      2'b10:
        begin
          peripherals_data_in <= data_in;
          peripherals_write_enable <= 1;
        end
      2'b11:
        begin
          ram_write_enable <= 0;
          peripherals_write_enable <= 0;
        end
    endcase
  end else begin
    ram_write_enable <= 0;
    peripherals_write_enable <= 0;
  end
end

rom rom_0(
  .address   (address[5:0]),
  .data_out  (rom_data_out)
);

ram ram_0(
  .address      (address[8:0]),
  .data_in      (ram_data_in),
  .data_out     (ram_data_out),
  .write_enable (ram_write_enable),
  .clk          (clk)
);

peripherals peripherals_0(
  .address      (address[5:0]),
  .data_in      (peripherals_data_in),
  .data_out     (peripherals_data_out),
  .write_enable (peripherals_write_enable),
  .clk          (clk),
  .raw_clk      (raw_clk),
  .speaker_p    (speaker_p),
  .speaker_m    (speaker_m),
  .ioport_0     (ioport_0),
  .button_0     (button_0),
  .reset        (reset)
);

endmodule


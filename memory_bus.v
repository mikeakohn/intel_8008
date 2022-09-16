// Intel 8008 FPGA Soft Processor 
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2022 by Michael Kohn

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

//reg rom_strobe;
//reg ram_strobe;
//reg peripherals_strobe;

reg ram_write_enable;
reg peripherals_write_enable;

assign data_out = address[15] == 0 ?
  (address[14] == 0 ? ram_data_out : rom_data_out) :
  (address[14] == 0 ? peripherals_data_out : 0);

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


// Intel 8008 FPGA Soft Processor
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2022-2023 by Michael Kohn

module block_ram
(
  input  [13:0] address,
  input  [7:0]  data_in,
  output [7:0]  data_out,
  input write_enable,
  input clk,
  input double_clk
);

reg [7:0] dummy;

/*

SB_SPRAM256KA ram00 (
  .ADDRESS(address[13:0]),
  .DATAIN({ 8'b0, data_in }),
  .MASKWREN({ 1'b0, 1'b0, write_enable, write_enable }),
  .WREN(write_enable),
  .CHIPSELECT(1'b1),
  .CLOCK(clk),
  .STANDBY(1'b0),
  .SLEEP(1'b0),
  .POWEROFF(1'b1),
  .DATAOUT({ dummy, data_out })
);
*/

/*
SB_RAM256x16 ram00 (
  .RDATA(data_out[7:0]),
  .RADDR(address[8:0]),
  .RCLK(clk),
  .RCLKE(1'b1),
  .RE(~write_enable),
  .WADDR(address[8:0]),
  .WCLK(clk),
  .WCLKE(1'b1),
  .WDATA(data_in),
  .WE(write_enable)
);
*/

wire rclke;
wire wclke;
reg re = 0;
reg we = 0;

assign rclke = re ? double_clk : 0;
assign wclke = we ? double_clk : 0;

/*
always @(posedge double_clk) begin
  if (clk) begin
    if (write_enable) begin
      we <= 1;
      re <= 0;
    end else begin
      we <= 0;
      re <= 1;
    end
  end else begin
    if (double_clk == 0) begin
      re <= 0;
      we <= 0;
    end
  end
end
*/

SB_RAM40_4K #(
  .READ_MODE(0),
  .WRITE_MODE(0)
) ram00 (
  .WADDR(address[10:0]),
  .RADDR(address[10:0]),
  .MASK(16'hffff),
  .WDATA({ 8'h00, data_in }),
  .RDATA({ dummy, data_out }),
  .WE(we),
  .WCLKE(wclke),
  .WCLK(double_clk),
  .RE(re),
  .RCLKE(rclke),
  .RCLK(double_clk)
);

endmodule


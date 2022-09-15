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


module eeprom
(
  input [10:0] address,
  input  strobe,
  input  raw_clk,
  output reg eeprom_cs,
  output reg eeprom_clk,
  output reg eeprom_di,
  input  eeprom_do,
  output reg ready,
  output reg [7:0] data_out
);

reg [2:0] state = 0;
reg [2:0] clock_div;
wire clk;
assign clk = clock_div[2];

reg [13:0] command;
reg [3:0] count;

parameter STATE_IDLE           = 0;
parameter STATE_SEND_ADDRESS_0 = 1;
parameter STATE_SEND_ADDRESS_1 = 2;
parameter STATE_READ_START     = 3;
parameter STATE_READ_DATA_0    = 4;
parameter STATE_READ_DATA_1    = 5;
parameter STATE_FINISH         = 6;

always @(posedge raw_clk) begin
  clock_div <= clock_div + 1;
end

always @(posedge clk) begin
  case (state)
    STATE_IDLE:
      begin
        if (strobe) begin
          command[13:11] <= 3'b110;
          command[10:0] <= address;
          count <= 14;
          ready <= 0;
          eeprom_cs <= 1;
          state <= STATE_SEND_ADDRESS_0;
        end else begin
          eeprom_cs <= 0;
          eeprom_di <= 0;
          eeprom_clk <= 0;
          ready <= 1;
        end
      end
    STATE_SEND_ADDRESS_0:
      begin
        count <= count - 1;
        eeprom_di <= command[13];
        eeprom_clk <= 0;
        state <= STATE_SEND_ADDRESS_1;
      end
    STATE_SEND_ADDRESS_1:
      begin
        eeprom_clk <= 1;

        if (count == 0) begin
          state <= STATE_READ_START;
        end else begin
          command[13:1] <= command[12:0];
          state <= STATE_SEND_ADDRESS_0;
        end
      end
    STATE_READ_START:
      begin
        eeprom_clk <= 0;
        eeprom_di <= 0;
        count <= 8;
        state <= STATE_READ_DATA_0;
      end
    STATE_READ_DATA_0:
      begin
        count <= count - 1;
        data_out[7:1] <= data_out[6:0];
        eeprom_clk <= 1;
        state <= STATE_READ_DATA_1;
      end
    STATE_READ_DATA_1:
      begin
        data_out[0] <= eeprom_do;
        eeprom_clk <= 0;

        if (count == 0) begin
          state <= STATE_FINISH;
        end else begin
          state <= STATE_READ_DATA_0;
        end
      end
    STATE_FINISH:
      begin
        eeprom_cs <= 0;
        eeprom_di <= 0;
        state <= STATE_IDLE;
      end
  endcase
end

endmodule


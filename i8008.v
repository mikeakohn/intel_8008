// Intel 8008 FPGA Soft Processor 
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2022 by Michael Kohn

module i8008
(
  output [7:0] leds,
  output [3:0] column,
  input raw_clk,
  output eeprom_cs,
  output eeprom_clk,
  output eeprom_di,
  input  eeprom_do,
  output speaker_p,
  output speaker_m,
  output ioport_0,
  input  button_reset,
  input  button_halt,
  input  button_program_select,
  input  button_0
);

// iceFUN 8x4 LEDs used for debugging.
reg [7:0] leds_value;
reg [3:0] column_value;

assign leds = leds_value;
assign column = column_value;

// Memory bus (ROM, RAM, peripherals).
reg [15:0] mem_address = 0;
reg [7:0] mem_data_in = 0;
wire [7:0] mem_data_out;
reg mem_write_enable = 0;

// Clock.
reg [21:0] count = 0;
reg [4:0] state = 0;
reg [4:0] next_state;
reg [19:0] clock_div;
reg [14:0] delay_loop;
wire clk;
assign clk = clock_div[7];

// Registers.
reg [7:0] registers [6:0];
wire [15:0] register_hl;
assign register_hl = { registers[5], registers[6] };

// ALU.
reg [7:0] alu_data_0;
reg [7:0] alu_data_1;
reg [2:0] alu_command;
wire [8:0] alu_result;
reg [7:0] inc_result;
reg [7:0] shift_result;
reg shift_carry;

//  Call stack: 16 bit, array of 8.
reg [15:0] stack [8:0];
reg [2:0] stack_ptr = 0;
reg [15:0] return_address;
reg [15:0] pc = 0;
reg [7:0] instruction;
reg [15:0] arg = 0;

// Flags.
wire [7:0] flags;
reg flag_zero = 0;
reg flag_carry = 0;
reg flag_sign = 0;
reg flag_parity = 0;
assign flags[7:4] = 0;
assign flags[3] = flag_parity;
assign flags[2] = flag_sign;
assign flags[1] = flag_carry;
assign flags[0] = flag_zero;

// Lower 6 its of the instruction.
wire [5:0] opcode;
assign opcode = instruction[5:0];

// Eeprom.
reg  [8:0] eeprom_count;
wire [7:0] eeprom_data_out;
reg [10:0] eeprom_address;
reg eeprom_strobe = 0;
wire eeprom_ready;

// Debug.
//reg [7:0] debug_0 = 0;
//reg [7:0] debug_1 = 0;
//reg [7:0] debug_2 = 0;
//reg [7:0] debug_3;

// This block is simply a clock divider for the raw_clk.
always @(posedge raw_clk) begin
  count <= count + 1;
  clock_div <= clock_div + 1;
end

// This block simply drives the 8x4 LEDs.
always @(posedge raw_clk) begin
  case (count[9:7])
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~instruction; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~register_hl[7:0]; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~debug_1; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~eeprom_count; end
    3'b000: begin column_value <= 4'b0111; leds_value <= ~registers[2]; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~registers[6]; end
    //3'b000: begin column_value <= 4'b0111; leds_value <= ~mem_address[7:0]; end
    //3'b010: begin column_value <= 4'b1011; leds_value <= ~arg[7:0]; end
    3'b010: begin column_value <= 4'b1011; leds_value <= ~flags[7:0]; end
    //3'b100: begin column_value <= 4'b1101; leds_value <= ~mem_address[7:0]; end
    3'b100: begin column_value <= 4'b1101; leds_value <= ~pc[7:0]; end
    3'b110: begin column_value <= 4'b1110; leds_value <= ~state; end
    default: begin column_value <= 4'b1111; leds_value <= 8'hff; end
  endcase
end

parameter STATE_RESET =        0;
parameter STATE_DELAY_LOOP =   1;
parameter STATE_FETCH_OP_0 =   2;
parameter STATE_FETCH_OP_1 =   3;
parameter STATE_START =        4;
parameter STATE_FETCH_LO_0 =   5;
parameter STATE_FETCH_LO_1 =   6;
parameter STATE_FETCH_HI_0 =   7;
parameter STATE_FETCH_HI_1 =   8;
parameter STATE_FETCH_IM_0 =   9;
parameter STATE_FETCH_IM_1 =   10;
parameter STATE_FETCH_SOURCE = 11;
parameter STATE_EXECUTE =      12;
parameter STATE_EXECUTE_WB =   13;
parameter STATE_EXECUTE_RD =   14;
parameter STATE_FINISH_INC =   15;
parameter STATE_FINISH_ALU =   16;
parameter STATE_FINISH_SHIFT = 17;
parameter STATE_FINISH_CALL =  18;
parameter STATE_HALTED =       19;
parameter STATE_ERROR =        20;
parameter STATE_EEPROM_START = 21;
parameter STATE_EEPROM_READ =  22;
parameter STATE_EEPROM_WAIT =  23;
parameter STATE_EEPROM_WRITE = 24;
parameter STATE_EEPROM_DONE =  25;

// 00_000_000
parameter OP_DCR = 6'b000_001;
parameter OP_INR = 6'b000_000;

parameter OP_MVI = 6'b000_110;

parameter OP_ADI = 3'b000; // _100
parameter OP_ACI = 3'b001; // _100
parameter OP_SUI = 3'b010; // _100
parameter OP_SBI = 3'b011; // _100
parameter OP_ANI = 3'b100; // _100
parameter OP_XRI = 3'b101; // _100
parameter OP_ORI = 3'b110; // _100
parameter OP_CPI = 3'b111; // _100

parameter OP_HLT_0 = 6'b000_000;

// 01_000_000
parameter OP_JMP = 6'b000_100;

parameter OP_JNC = 3'b000; // _000
parameter OP_JNZ = 3'b001; // _000
parameter OP_JP =  3'b010; // _000
parameter OP_JPO = 3'b011; // _000
parameter OP_JC =  3'b100; // _000
parameter OP_JZ =  3'b101; // _000
parameter OP_JM =  3'b110; // _000
parameter OP_JPE = 3'b111; // _000

parameter OP_CNC = 3'b000; // _010
parameter OP_CNZ = 3'b001; // _010
parameter OP_CP =  3'b010; // _010
parameter OP_CPO = 3'b011; // _010
parameter OP_CC =  3'b100; // _010
parameter OP_CZ =  3'b101; // _010
parameter OP_CM =  3'b110; // _010
parameter OP_CPE = 3'b111; // _010

parameter OP_RNC = 3'b000; // _011
parameter OP_RNZ = 3'b001; // _011
parameter OP_RP =  3'b010; // _011
parameter OP_RPO = 3'b011; // _011
parameter OP_RC =  3'b100; // _011
parameter OP_RZ =  3'b101; // _011
parameter OP_RM =  3'b110; // _011
parameter OP_RPE = 3'b111; // _011

// 10_000_000
parameter OP_ADD = 3'b000;
parameter OP_ADC = 3'b001;
parameter OP_SUB = 3'b010;
parameter OP_SBB = 3'b011;
parameter OP_ANA = 3'b100;
parameter OP_XRA = 3'b101;
parameter OP_ORA = 3'b110;
parameter OP_CMP = 3'b111;

// 11_000_000
parameter OP_MOV = 6'b000_000;
parameter OP_HLT_1 = 6'b111_111;

// This block is the main CPU instruction execute state machine.
always @(posedge clk) begin
  case (state)
    STATE_RESET:
      begin
        stack_ptr <= 3'b000;
        flag_zero <= 0;
        flag_carry <= 0;
        flag_sign <= 0;
        flag_parity <= 0;
        mem_address <= 0;
        mem_write_enable <= 0;
        mem_data_in <= 0;
        instruction <= 0;
        delay_loop = 12000;
        eeprom_strobe <= 0;
        next_state <= STATE_DELAY_LOOP;
        //next_state <= STATE_FETCH_OP_0;
      end
    STATE_DELAY_LOOP:
      begin
        // This is probably not needed. The chip starts up fine without it.
        if (delay_loop == 0) begin

          // If button is not pushed, start rom.v code otherwise use EEPROM.
          if (button_program_select)
            pc <= 16'h4000;
          else
            pc <= 0;

          next_state <= STATE_EEPROM_START;
        end else begin
          delay_loop <= delay_loop - 1;
        end
      end
    STATE_FETCH_OP_0:
      begin
        mem_address <= pc;
        mem_write_enable <= 1'b0;
        next_state <= STATE_FETCH_OP_1;
      end
    STATE_FETCH_OP_1:
      begin
        instruction <= mem_data_out;
        next_state <= STATE_START;
        pc <= pc + 1;
      end
    STATE_START:
      begin
        case (instruction[7:6])
          2'b00:
            begin
              // Immediate instructions, inc, dec, halt.
              if (opcode[2:0] == 3'b000)
                if (opcode[5:3] == 0)
                  next_state <= STATE_HALTED;
                else
                  next_state <= STATE_EXECUTE;
              else if (opcode[2:0] == 3'b001)
                if (opcode[5:3] == 0)
                  next_state <= STATE_HALTED;
                else
                  next_state <= STATE_EXECUTE;
              else if (opcode[2:0] == 3'b010)
                // Shift: RLC, RRC, RAL, RAR.
                next_state <= STATE_EXECUTE;
              else if (opcode[2:0] == 3'b011)
                begin
                  case (opcode[5:3])
                    OP_RNC: if (!flag_carry)  stack_ptr <= stack_ptr - 1;
                    OP_RNZ: if (!flag_zero)   stack_ptr <= stack_ptr - 1;
                    OP_RP:  if (!flag_sign)   stack_ptr <= stack_ptr - 1;
                    OP_RPO: if (flag_parity)  stack_ptr <= stack_ptr - 1;
                    OP_RC:  if (flag_carry)   stack_ptr <= stack_ptr - 1;
                    OP_RZ:  if (flag_zero)    stack_ptr <= stack_ptr - 1;
                    OP_RM:  if (flag_sign)    stack_ptr <= stack_ptr - 1;
                    OP_RPE: if (!flag_parity) stack_ptr <= stack_ptr - 1;
                  endcase

                  // Return (conditional).
                  next_state <= STATE_EXECUTE;
                end
              else if (opcode[2:0] == 3'b100)
                // ALU with immediate.
                next_state <= STATE_FETCH_IM_0;
              else if (opcode[2:0] == 3'b101)
                begin
                  // RST.
                  return_address <= pc + 2'd2;
                  next_state <= STATE_EXECUTE;
                end
              else if (opcode[2:0] == 3'b110)
                // MVI with immediate.
                next_state <= STATE_FETCH_IM_0;
              else if (opcode[2:0] == 3'b111)
                begin
                  // Return.
                  stack_ptr <= stack_ptr - 1;
                  next_state <= STATE_EXECUTE;
                end
              else
                next_state <= STATE_ERROR;
            end
          2'b01:
            begin
              if (opcode[0] == 1) begin
                if (opcode[5:4] == 0) begin
                  // IN.
                  mem_address <= { 13'b1000_0000_0000_0, opcode[3:1] };
                  mem_write_enable <= 0;
                end else begin
                  // OUT.
                  mem_address <= { 11'b1000_0000_000, opcode[5:1] };
                  mem_data_in <= registers[0];
                  mem_write_enable <= 1;
                end

                next_state <= STATE_EXECUTE;
              end else begin
                if (opcode[2:0] == 3'b010 || opcode[2:0] == 3'b110) begin
                  // Call.
                  return_address <= pc + 2'd2;
                end

                // Jump and call instructions.
                next_state <= STATE_FETCH_LO_0;
              end
            end
          2'b10:
            begin
              // ALU with registers.
              if (opcode[2:0] == 7) begin
                mem_address <= register_hl;
                mem_write_enable <= 0;
              end

              next_state <= STATE_EXECUTE;
            end
          2'b11:
            begin
              //  MOV instructions or halt if source == 7 && dest == 7.
              if (opcode == OP_HLT_1)
                next_state <= STATE_HALTED;
              else
                next_state <= STATE_EXECUTE;
            end
        endcase
      end
    STATE_FETCH_LO_0:
      begin
        mem_address <= pc;
        mem_write_enable <= 0;
        next_state <= STATE_FETCH_LO_1;
      end
    STATE_FETCH_LO_1:
      begin
        arg[7:0] <= mem_data_out;
        next_state <= STATE_FETCH_HI_0;
        pc <= pc + 1;
      end
    STATE_FETCH_HI_0:
      begin
        mem_address <= pc;
        mem_write_enable <= 0;
        next_state <= STATE_FETCH_HI_1;
      end
    STATE_FETCH_HI_1:
      begin
        arg[15:8] <= mem_data_out;
        next_state <= STATE_EXECUTE;
        pc <= pc + 1;
      end
    STATE_FETCH_IM_0:
      begin
        mem_address <= pc;
        mem_write_enable <= 0;
        next_state <= STATE_FETCH_IM_1;
      end
    STATE_FETCH_IM_1:
      begin
        arg[15:8] <= 0;
        arg[7:0] <= mem_data_out;
        next_state <= STATE_EXECUTE;
        pc <= pc + 1;
      end
    STATE_FETCH_SOURCE:
      begin
        arg[7:0] <= registers[opcode[5:3]];
        next_state <= STATE_EXECUTE;
      end
    STATE_EXECUTE:
      begin
        case (instruction[7:6])
          2'b00:
            begin
              if (opcode[2:0] == 3'b000) begin
                // Increment instruction (INR).
                inc_result <= registers[opcode[5:3]] + 1;
                next_state <= STATE_FINISH_INC;
              end else if (opcode[2:0] == 3'b001) begin
                // Decrement instruction (DCR).
                inc_result <= registers[opcode[5:3]] - 1;
                next_state <= STATE_FINISH_INC;
              end else if (opcode[2:0] == 3'b010) begin
                // Rotate instructions.
                case (opcode[5:3])
                  3'b000:
                    begin
                      shift_result[7:1] <= registers[0][6:0];
                      shift_carry <= registers[0][7];
                      next_state <= STATE_FINISH_SHIFT;
                    end
                  3'b001:
                    begin
                      shift_result[6:0] <= registers[0][7:1];
                      shift_carry <= registers[0][0];
                      next_state <= STATE_FINISH_SHIFT;
                    end
                  3'b010:
                    begin
                      shift_result[7:1] <= registers[0][6:0];
                      shift_result[0] <= flag_carry;
                      shift_carry <= registers[0][7];
                      next_state <= STATE_FINISH_SHIFT;
                    end
                  3'b011:
                    begin
                      shift_result[6:0] <= registers[0][7:1];
                      shift_result[7] <= flag_carry;
                      shift_carry <= registers[0][0];
                      next_state <= STATE_FINISH_SHIFT;
                    end
                  default:
                    next_state <= STATE_ERROR;
                endcase
              end else if (opcode[2:0] == 3'b011) begin
                // Return (conditional).
                case (opcode[5:3])
                  OP_RNC: if (!flag_carry)  pc <= stack[stack_ptr];
                  OP_RNZ: if (!flag_zero)   pc <= stack[stack_ptr];
                  OP_RP:  if (!flag_sign)   pc <= stack[stack_ptr];
                  OP_RPO: if (flag_parity)  pc <= stack[stack_ptr];
                  OP_RC:  if (flag_carry)   pc <= stack[stack_ptr];
                  OP_RZ:  if (flag_zero)    pc <= stack[stack_ptr];
                  OP_RM:  if (flag_sign)    pc <= stack[stack_ptr];
                  OP_RPE: if (!flag_parity) pc <= stack[stack_ptr];
                endcase
                next_state <= STATE_FETCH_OP_0;
              end else if (opcode[2:0] == 3'b100) begin
                // ALU with immediate value.
                alu_data_0 <= registers[0];
                alu_data_1 <= arg[7:0];
                alu_command <= opcode[5:3];
                next_state <= STATE_FINISH_ALU;
              end else if (opcode[2:0] == 3'b101) begin
                // RST (call subroutine at address (AAA000).
                pc[2:0] <= 3'd0;
                pc[5:3] <= opcode[5:3];
                pc[15:6] <= 10'd0;
                stack[stack_ptr] <= return_address;
                next_state <= STATE_FINISH_CALL;
              end else if (opcode[2:0] == 3'b110) begin
                // MVI with immediate.
                if (opcode[5:3] == 3'b111) begin
                  mem_address <= register_hl;
                  mem_data_in <= arg[7:0];
                  mem_write_enable <= 1'b1;
                  next_state <= STATE_EXECUTE_WB;
                end else begin
                  registers[opcode[5:3]] <= arg[7:0];
                  next_state <= STATE_FETCH_OP_0;
                end
              end else if (opcode[2:0] == 3'b111) begin
                // Return.
                pc <= stack[stack_ptr];
                next_state <= STATE_FETCH_OP_0;
              end
            end
          2'b01:
            begin
              if (opcode[0] == 1) begin
                if (opcode[5:4] == 0) begin
                  // IN.
                  registers[0] <= mem_data_out;
                end else begin
                  // OUT.
                  mem_write_enable <= 0;
                end

                next_state <= STATE_FETCH_OP_0;
              end else begin
                if (opcode[2:0] == 3'b100) begin
                  // Jump.
                  pc <= arg;
                  next_state <= STATE_FETCH_OP_0;
                end else if (opcode[2:0] == 3'b110) begin
                  // Call.
                  pc <= arg;
                  stack[stack_ptr] <= return_address;
                  next_state <= STATE_FINISH_CALL;
                end else if (opcode[2:0] == 3'b000) begin
                  // Jump (conditional).
                  case (opcode[5:3])
                    OP_JNC: if (!flag_carry)  pc <= arg;
                    OP_JNZ: if (!flag_zero)   pc <= arg;
                    OP_JP:  if (!flag_sign)   pc <= arg;
                    OP_JPO: if (flag_parity)  pc <= arg;
                    OP_JC:  if (flag_carry)   pc <= arg;
                    OP_JZ:  if (flag_zero)    pc <= arg;
                    OP_JM:  if (flag_sign)    pc <= arg;
                    OP_JPE: if (!flag_parity) pc <= arg;
                  endcase
                  next_state <= STATE_FETCH_OP_0;
                end else if (opcode[2:0] == 3'b010) begin
                  // Call (conditional).
                  case (opcode[5:3])
                    OP_CNC: if (!flag_carry)  pc <= arg;
                    OP_CNZ: if (!flag_zero)   pc <= arg;
                    OP_CP:  if (!flag_sign)   pc <= arg;
                    OP_CPO: if (flag_parity)  pc <= arg;
                    OP_CC:  if (flag_carry)   pc <= arg;
                    OP_CZ:  if (flag_zero)    pc <= arg;
                    OP_CM:  if (flag_sign)    pc <= arg;
                    OP_CPE: if (!flag_parity) pc <= arg;
                  endcase
                  stack[stack_ptr] <= return_address;
                  next_state <= STATE_FINISH_CALL;
                end else begin
                  next_state <= STATE_ERROR;
                end
              end
            end
          2'b10:
            begin
              // ALU instructions using registers.
              if (opcode[2:0] == 7) begin
                alu_data_1 <= mem_data_out;
              end else begin
                alu_data_1 <= opcode[2:0];
              end

              alu_data_0 <= registers[0];
              alu_command <= opcode[5:3];

              next_state <= STATE_FINISH_ALU;
            end
          2'b11:
            begin
              // MOV (register load instruction with registers or M).
              if (opcode[5:3] == 7) begin
                mem_address <= register_hl;
                mem_data_in <= registers[opcode[2:0]];
                mem_write_enable <= 1;
                next_state <= STATE_EXECUTE_WB;
              end else if (opcode[2:0] == 7) begin
                mem_address <= register_hl;
                next_state <= STATE_EXECUTE_RD;
              end else begin
                registers[opcode[5:3]] <= registers[opcode[2:0]];
                next_state <= STATE_FETCH_OP_0;
              end
            end
        endcase
      end
    STATE_EXECUTE_WB:
      begin
        // Finish writeback of result to memory.
        mem_write_enable <= 0;
        next_state <= STATE_FETCH_OP_0;
      end
    STATE_EXECUTE_RD:
      begin
        // Finishing reading of memory into a register.
        registers[opcode[5:3]] <= mem_data_out;
        next_state <= STATE_FETCH_OP_0;
      end
    STATE_FINISH_INC:
      begin
        // Finish INR / DCR (increment / decrement).
        registers[opcode[5:3]] <= inc_result[7:0];
        flag_zero <= inc_result[7:0] == 8'd0;
        flag_sign <= inc_result[7];
        flag_parity <=
          inc_result[7] ^ inc_result[6] ^ inc_result[5] ^ inc_result[4] ^
          inc_result[3] ^ inc_result[2] ^ inc_result[1] ^ inc_result[0] ^ 1'b1;

        next_state <= STATE_FETCH_OP_0;
      end
    STATE_FINISH_ALU:
      begin
        // Store ALU result into accumulator.
        if (opcode[5:3] != 7) registers[0] <= alu_result[7:0];
        flag_zero  <= alu_result[7:0] == 0;
        flag_carry <= alu_result[8];
        flag_sign  <= alu_result[7];
        flag_parity <=
          alu_result[7] ^ alu_result[6] ^ alu_result[5] ^ alu_result[4] ^
          alu_result[3] ^ alu_result[2] ^ alu_result[1] ^ alu_result[0] ^ 1'b1;

        next_state <= STATE_FETCH_OP_0;
      end
    STATE_FINISH_SHIFT:
      begin
        // Only affects carry.
        registers[0] <= shift_result;
        flag_carry <= shift_carry;
        next_state <= STATE_FETCH_OP_0;
      end
    STATE_FINISH_CALL:
      begin
        stack_ptr <= stack_ptr + 1;
        next_state <= STATE_FETCH_OP_0;
      end
    STATE_HALTED:
      begin
        if (!button_halt)
          next_state <= STATE_FETCH_OP_0;
        else
          next_state <= STATE_HALTED;

        mem_write_enable <= 0;
      end
    STATE_ERROR:
      begin
        next_state <= STATE_ERROR;
        mem_write_enable <= 0;
      end
    STATE_EEPROM_START:
      begin
        // Initialize values for reading from SPI-like EEPROM.
        if (eeprom_ready) begin
          eeprom_count <= 0;
          next_state <= STATE_EEPROM_READ;
        end
      end
    STATE_EEPROM_READ:
      begin
        // Set the next EEPROM address to read from and strobe.
        eeprom_address <= eeprom_count;
        mem_address <= eeprom_count;
        eeprom_strobe <= 1;
        next_state <= STATE_EEPROM_WAIT;
      end
    STATE_EEPROM_WAIT:
      begin
        // Wait until 8 bits are clocked in.
        eeprom_strobe <= 0;

        if (eeprom_ready) begin
          mem_data_in <= eeprom_data_out;
          eeprom_count <= eeprom_count + 1;
          next_state <= STATE_EEPROM_WRITE;
        end
      end
    STATE_EEPROM_WRITE:
      begin
        // Write value read from EEPROM into memory.
        mem_write_enable <= 1;
        next_state <= STATE_EEPROM_DONE;
      end
    STATE_EEPROM_DONE:
      begin
        // Finish writing and read next byte if needed.
        mem_write_enable <= 0;

        if (eeprom_count == 256)
          next_state <= STATE_FETCH_OP_0;
        else
          next_state <= STATE_EEPROM_READ;
      end
  endcase
end

// On negative edge of clock, check reset and halt buttons and
// change to next state of the CPU execution state machine.
always @(negedge clk) begin
  if (!button_reset)
    state <= STATE_RESET;
  else if (!button_halt)
    state <= STATE_HALTED;
  else
    state <= next_state;
end

memory_bus memory_bus_0(
  .address      (mem_address),
  .data_in      (mem_data_in),
  .data_out     (mem_data_out),
  .write_enable (mem_write_enable),
  .clk          (clk),
  .raw_clk      (raw_clk),
  .speaker_p    (speaker_p),
  .speaker_m    (speaker_m),
  .ioport_0     (ioport_0),
  .button_0     (button_0),
  .reset        (~button_reset)
);

alu alu_0
(
  .data_0     (alu_data_0),
  .data_1     (alu_data_1),
  .flag_carry (flag_carry),
  .command    (alu_command),
  .alu_result (alu_result)
);

eeprom eeprom_0
(
  .address    (eeprom_address),
  .strobe     (eeprom_strobe),
  .raw_clk    (raw_clk),
  .eeprom_cs  (eeprom_cs),
  .eeprom_clk (eeprom_clk),
  .eeprom_di  (eeprom_di),
  .eeprom_do  (eeprom_do),
  .ready      (eeprom_ready),
  .data_out   (eeprom_data_out)
);

endmodule


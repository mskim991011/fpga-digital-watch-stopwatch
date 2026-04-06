`timescale 1ns / 1ps

module fifo #(
    parameter DEPTH = 32,
    parameter BIT_WIDTH = 8
) (
    input clk,
    input reset,
    input push,
    input pop,
    input [BIT_WIDTH-1:0] push_data,
    output [BIT_WIDTH-1:0] pop_data,
    output full,
    output empty
);

  wire [$clog2(DEPTH)-1:0] w_addr, r_addr;
  wire w_we;


  assign w_we = push & ~full;

  fifo_register_file #(
      .DEPTH(DEPTH),
      .BIT_WIDTH(BIT_WIDTH)
  ) U_FIFO_REG_FILE (
      .clk(clk),
      .push_data(push_data),
      .w_addr(w_addr),
      .r_addr(r_addr),
      .we(w_we),
      .pop_data(pop_data)
  );

  fifo_control_unit #(
      .DEPTH(DEPTH)
  ) U_FIFO_CONTROL_UNIT (
      .clk   (clk),
      .reset (reset),
      .push  (push),
      .pop   (pop),
      .w_addr(w_addr),
      .r_addr(r_addr),
      .full  (full),
      .empty (empty)
  );
endmodule

module fifo_register_file #(
    parameter DEPTH = 4,
    parameter BIT_WIDTH = 8
) (
    input clk,
    input [BIT_WIDTH-1:0] push_data,
    input [$clog2(DEPTH)-1:0] w_addr,
    input [$clog2(DEPTH)-1:0] r_addr,
    input we,
    output [BIT_WIDTH-1:0] pop_data
);
  reg [BIT_WIDTH-1:0] register_file[0:DEPTH-1];

  always @(posedge clk) begin
    if (we) begin
      register_file[w_addr] <= push_data;
    end
  end

  assign pop_data = register_file[r_addr];
endmodule

module fifo_control_unit #(
    parameter DEPTH = 4
) (
    input clk,
    input reset,
    input push,
    input pop,
    output [$clog2(DEPTH)-1:0] w_addr,
    output [$clog2(DEPTH)-1:0] r_addr,
    output full,
    output empty
);

  reg [$clog2(DEPTH)-1:0] wptr_reg, wptr_next, rptr_reg, rptr_next;
  reg full_reg, full_next, empty_reg, empty_next;
  assign w_addr  = wptr_reg;
  assign r_addr = rptr_reg;
  assign full  = full_reg;
  assign empty = empty_reg;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      wptr_reg  <= 0;
      rptr_reg  <= 0;
      full_reg  <= 0;
      empty_reg <= 1'b1;
    end else begin
      wptr_reg  <= wptr_next;
      rptr_reg  <= rptr_next;
      full_reg  <= full_next;
      empty_reg <= empty_next;
    end
  end
  always @(*) begin
    wptr_next = wptr_reg;
    rptr_next = rptr_reg;
    full_next = full_reg;
    empty_next = empty_reg;
    case ({
      push, pop
    })
      2'b10: begin
        if (!full) begin
          wptr_next  = wptr_reg + 1;
          empty_next = 1'b0;
          if (wptr_next == rptr_reg) begin
            full_next = 1'b1;
          end
        end
      end
      2'b01: begin
        if (!empty) begin
          rptr_next = rptr_reg + 1;
          full_next = 1'b0;
          if (wptr_reg == rptr_next) begin
            empty_next = 1'b1;
          end
        end
      end

      2'b11: begin
        if (full_reg == 1'b1) begin
          rptr_next = rptr_reg + 1;
          full_next = 1'b0;
        end else if (empty_reg == 1'b1) begin
          wptr_next  = wptr_reg + 1;
          empty_next = 1'b0;
        end else begin
          wptr_next = wptr_reg + 1;
          rptr_next = rptr_reg + 1;
        end
      end
    endcase
  end
endmodule

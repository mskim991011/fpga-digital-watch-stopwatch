`timescale 1ns / 1ps

module ascii_sender (
    input clk,
    input reset,
    input start,
    input tx_done,

    output reg tx_start,
    output reg [7:0] tx_data,

    input [3:0] hour_10,
    input [3:0] hour_1,
    input [3:0] min_10,
    input [3:0] min_1,
    input [3:0] sec_10,
    input [3:0] sec_1,
    input [3:0] msec_10,
    input [3:0] msec_1
);



  reg [7:0] msg[0:9];

  always @(*) begin
        msg[0] = 8'h30 + hour_10;
        msg[1] = 8'h30 + hour_1;
        msg[2] = 8'h3A; 
        msg[3] = 8'h30 + min_10;
        msg[4] = 8'h30 + min_1;
        msg[5] = 8'h3A;
        msg[6] = 8'h30 + sec_10;
        msg[7] = 8'h30 + sec_1;
        msg[8] = 8'h0D; 
        msg[9] = 8'h0A; 
    end

  localparam IDLE = 2'd0, SEND = 2'd1, WAIT = 2'd2;
  reg [1:0] state, state_n;
  reg [3:0] num, num_n;
  
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
      num   <= 0;
    end else begin
      state <= state_n;
      num   <= num_n;
    end
  end

  always @(*) begin
    state_n  = state;
    num_n    = num;
    tx_start = 1'b0;
    tx_data  = 8'h00;

    case (state)
      IDLE: begin
        if (start) begin
          num_n   = 0;
          state_n = SEND;
        end
      end

      SEND: begin
        tx_data  = msg[num];
        tx_start = 1'b1;
        state_n  = WAIT;
      end

      WAIT: begin
        if (tx_done) begin
          if (num == 9) state_n = IDLE;
          else begin
            num_n   = num + 1;
            state_n = SEND;
          end
        end
      end
    endcase
  end
endmodule

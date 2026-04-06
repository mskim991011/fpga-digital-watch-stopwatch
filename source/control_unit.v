`timescale 1ns / 1ps

module control_unit (
    input clk,
    input reset,
    input i_mode,
    input i_runstop,
    input i_clear,
    output o_mode,
    output reg o_runstop,
    output reg o_clear
);

    localparam STOP = 2'b00, RUN = 2'b01;
    reg current_state, next_state;

    assign o_mode = i_mode;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= STOP;
        end else begin
            current_state <= next_state;
        end
    end



    always @(*) begin
        next_state = current_state;
        o_runstop = 1'b0;
        o_clear = i_clear;
        case (current_state)
            STOP: begin
                o_runstop = 1'b0;
                
                if (i_runstop) begin
                    next_state = RUN;
                end 
                
            end
            RUN: begin
                o_runstop = 1'b1;
                
                if (i_runstop) begin
                    next_state = STOP;
                end 
            end
            
        endcase
    end
endmodule

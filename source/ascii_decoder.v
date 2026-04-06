`timescale 1ns / 1ps

module ascii_decoder (
    input clk,
    input rst,
    input [7:0] rx_data,
    input rx_done,
    output reg btn_r,
    output reg btn_l,
    output reg btn_u,
    output reg btn_d,
    output reg ctrl_sw0,
    output reg ctrl_sw1,
    output reg ctrl_sw2,
    output reg send_req
);

  always @(*) begin
    btn_r = 0;
    btn_l = 0;
    btn_u = 0;
    btn_d = 0;
    send_req = 0;

    if (rx_done) begin
      if (rx_data == 8'h72) btn_r = 1;
      else if (rx_data == 8'h6C) btn_l = 1;
      else if (rx_data == 8'h75) btn_u = 1;
      else if (rx_data == 8'h64) btn_d = 1;
      else if (rx_data == 8'h73) send_req =1;
    end
  end

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ctrl_sw0 <= 0;
      ctrl_sw1 <= 0;
      ctrl_sw2 <= 0;
    end else if (rx_done) begin
      case (rx_data)
        "0": ctrl_sw0 <= ~ctrl_sw0;
        "1": ctrl_sw1 <= ~ctrl_sw1;
        "2": ctrl_sw2 <= ~ctrl_sw2;
      endcase
    end
  end


endmodule

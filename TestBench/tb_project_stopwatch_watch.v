`timescale 1ns / 1ps

module tb_system_top;

  reg clk;
  reg reset;
  reg uart_rx;


  reg i_btn_u, i_btn_l, i_btn_r, i_btn_d;
  reg [2:0] sw;


  wire uart_tx;
  wire [3:0] fnd_digit;
  wire [7:0] fnd_data;
  wire WATCH_led;


  system_top DUT (
      .clk(clk),
      .reset(reset),
      .uart_rx(uart_rx),
      .uart_tx(uart_tx),
      .i_btn_u(i_btn_u),
      .i_btn_l(i_btn_l),
      .i_btn_r(i_btn_r),
      .i_btn_d(i_btn_d),
      .sw(sw),
      .fnd_digit(fnd_digit),
      .fnd_data(fnd_data),
      .WATCH_led(WATCH_led)
  );


  always #5 clk = ~clk;


  localparam BIT_TIME = 104166;

  task send_uart(input [7:0] data);
    integer i;
    begin
      uart_rx = 0;
      #(BIT_TIME);
      for (i = 0; i < 8; i = i + 1) begin
        uart_rx = data[i];
        #(BIT_TIME);
      end
      uart_rx = 1;
      #(BIT_TIME);
    end
  endtask

  initial begin

    clk = 0;
    reset = 1;
    uart_rx = 1;
    i_btn_u = 0;
    i_btn_l = 0;
    i_btn_r = 0;
    i_btn_d = 0;
    sw = 0;

    #100;
    reset = 0;


    #1000000;


    send_uart(8'h73);


    #20000000;

    $finish;
  end
endmodule

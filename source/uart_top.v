`timescale 1ns / 1ps

module system_top (
    input clk,
    input reset,
    input uart_rx,
    output uart_tx,
    input i_btn_u,
    input i_btn_l,
    input i_btn_r,
    input i_btn_d,
    input [2:0] sw,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output WATCH_led
);
  wire w_uart_btn_r, w_uart_btn_l, w_uart_btn_u, w_uart_btn_d;
  wire w_db_btn_r, w_db_btn_l, w_db_btn_u, w_db_btn_d;
  wire w_uart_sw0, w_uart_sw1, w_uart_sw2;
  wire w_final_mode_sw;
  assign w_final_mode_sw = sw[1] ^ w_uart_sw1;
  assign WATCH_led = (w_final_mode_sw == 1'b0) ? 1'b1 : 1'b0;
  wire [3:0] w_hour10, w_hour1, w_min10, w_min1, w_sec10, w_sec1, w_msec10, w_msec1;
  wire w_send_req;
  wire w_tx_done;
  wire w_sender_tx_start;
  wire [7:0] w_sender_tx_data;

  uart_top U_UART (
      .clk(clk),
      .reset(reset),
      .uart_rx(uart_rx),
      .uart_tx(uart_tx),
      .o_btn_r(w_uart_btn_r),
      .o_btn_l(w_uart_btn_l),
      .o_btn_u(w_uart_btn_u),
      .o_btn_d(w_uart_btn_d),
      .o_sw0(w_uart_sw0),
      .o_sw1(w_uart_sw1),
      .o_sw2(w_uart_sw2),
      .i_tx_data(w_sender_tx_data),
      .i_tx_start(w_sender_tx_start),
      .o_tx_done(w_tx_done),
      .o_send_req(w_send_req)
  );

  top_stopwatch_watch U_WATCH (
      .clk(clk),
      .reset(reset),
      .sw({(sw[2] ^ w_uart_sw2), (sw[1] ^ w_uart_sw1), (sw[0] ^ w_uart_sw0)}),
      .btn_r(w_db_btn_r | w_uart_btn_r),
      .btn_l(w_db_btn_l | w_uart_btn_l),
      .btn_u(w_db_btn_u | w_uart_btn_u),
      .btn_d(w_db_btn_d | w_uart_btn_d),
      .fnd_digit(fnd_digit),
      .fnd_data(fnd_data),
      .o_hour_10(w_hour10),
      .o_hour_1(w_hour1),
      .o_min_10(w_min10),
      .o_min_1(w_min1),
      .o_sec_10(w_sec10),
      .o_sec_1(w_sec1),
      .o_msec_10(w_msec10),
      .o_msec_1(w_msec1)
  );

  ascii_sender U_TIME_SENDER (
      .clk(clk),
      .reset(reset),
      .start(w_send_req),
      .tx_done(w_tx_done),
      .tx_start(w_sender_tx_start),
      .tx_data(w_sender_tx_data),
      .hour_10(w_hour10),
      .hour_1(w_hour1),
      .min_10(w_min10),
      .min_1(w_min1),
      .sec_10(w_sec10),
      .sec_1(w_sec1),
      .msec_1(w_msec1),
      .msec_10(w_msec10)
  );

  bt_debounce DB_R (
      .clk  (clk),
      .reset(reset),
      .i_btn(i_btn_r),
      .o_btn(w_db_btn_r)
  );
  bt_debounce DB_L (
      .clk  (clk),
      .reset(reset),
      .i_btn(i_btn_l),
      .o_btn(w_db_btn_l)
  );
  bt_debounce DB_U (
      .clk  (clk),
      .reset(reset),
      .i_btn(i_btn_u),
      .o_btn(w_db_btn_u)
  );
  bt_debounce DB_D (
      .clk  (clk),
      .reset(reset),
      .i_btn(i_btn_d),
      .o_btn(w_db_btn_d)
  );

endmodule


module uart_top (
    input clk,
    input reset,
    input uart_rx,
    output uart_tx,
    output o_btn_r,
    output o_btn_l,
    output o_btn_u,
    output o_btn_d,
    output o_sw0,
    output o_sw1,
    output o_sw2,
    input [7:0] i_tx_data,
    input i_tx_start,
    output o_tx_done,
    output o_send_req
);




  wire w_b_tick, w_rx_done;
  wire [7:0] w_rx_data, w_rx_fifo_out, w_tx_fifo_out;
  wire w_tx_done;
  wire w_tx_busy;
  wire w_rx_empty, w_tx_empty;

  reg r_tx_start;
  reg r_fifo_pop;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            r_tx_start <= 0;
            r_fifo_pop <= 0;
        end else begin
            r_tx_start <= 0;
            r_fifo_pop <= 0;
            if ((~w_tx_empty) && (~w_tx_busy) && (~r_tx_start)) begin
                r_fifo_pop <= 1'b1; 
                r_tx_start <= 1'b1; 
            end
        end
    end


  fifo  U_FIFO_RX (
      .clk(clk),
      .reset(reset),
      .push(w_rx_done),
      .pop(~w_rx_empty),
      .push_data(w_rx_data),
      .pop_data(w_rx_fifo_out),
      .full(),
      .empty(w_rx_empty)
  );

  fifo U_FIFO_TX (
      .clk(clk),
      .reset(reset),
      .push(i_tx_start),
      .pop(r_fifo_pop),
      .push_data(i_tx_data),
      .pop_data(w_tx_fifo_out),
      .full(),
      .empty(w_tx_empty)
  );


  uart_rx UART_RX (
      .clk(clk),
      .reset(reset),
      .rx(uart_rx),
      .b_tick(w_b_tick),
      .rx_data(w_rx_data),
      .rx_done(w_rx_done)
  );

  uart_tx UNT_UART_TX (
      .clk(clk),
      .reset(reset),
      .tx_start(r_tx_start),
      .b_tick(w_b_tick),
      .tx_data(w_tx_fifo_out),
      .tx_busy(w_tx_busy),
      .tx_done(w_tx_done),
      .uart_tx(uart_tx)
  );
  b_tick UNT_B_TICK (
      .clk(clk),
      .reset(reset),
      .b_tick(w_b_tick)
  );

  ascii_decoder U_DECODER (
      .clk(clk),
      .rst(reset),
      .rx_data(w_rx_fifo_out),
      .rx_done(~w_rx_empty),
      .btn_r(o_btn_r),
      .btn_l(o_btn_l),
      .btn_u(o_btn_u),
      .btn_d(o_btn_d),
      .ctrl_sw0(o_sw0),
      .ctrl_sw1(o_sw1),
      .ctrl_sw2(o_sw2),
      .send_req(o_send_req)
  );
  assign o_tx_done = w_tx_done;

endmodule


module uart_rx (
    input clk,
    input reset,
    input rx,
    input b_tick,
    output [7:0] rx_data,
    output rx_done
);
  localparam IDLE = 2'd0, START = 2'd1;
  localparam DATA = 2'd2;
  localparam STOP = 2'd3;

  reg [1:0] c_state, n_state;
  reg [2:0] bit_cnt_reg, bit_cnt_next;
  reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
  reg done_reg, done_next;
  reg [7:0] buf_reg, buf_next;

  assign rx_data = buf_reg;
  assign rx_done = done_reg;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      c_state <= 2'd0;
      b_tick_cnt_reg <= 5'd0;
      bit_cnt_reg <= 3'd0;
      done_reg <= 1'b0;
      buf_reg <= 8'd0;
    end else begin
      c_state <= n_state;
      b_tick_cnt_reg <= b_tick_cnt_next;
      bit_cnt_reg <= bit_cnt_next;
      done_reg <= done_next;
      buf_reg <= buf_next;
    end

  end

  always @(*) begin
    n_state = c_state;
    b_tick_cnt_next = b_tick_cnt_reg;
    bit_cnt_next = bit_cnt_reg;
    done_next = done_reg;
    buf_next = buf_reg;
    case (c_state)
      IDLE: begin
        b_tick_cnt_next = 5'd0;
        bit_cnt_next = 3'd0;
        done_next = 1'b0;
        if (b_tick & (rx == 1'b0)) begin
          buf_next = 8'd0;
          n_state  = START;
        end
      end
      START: begin
        if (b_tick)
          if (b_tick_cnt_reg == 7) begin
            b_tick_cnt_next = 0;
            n_state = DATA;
          end else begin
            b_tick_cnt_next = b_tick_cnt_reg + 1;
          end
      end
      DATA: begin
        if (b_tick) begin
          if (b_tick_cnt_reg == 15) begin
            b_tick_cnt_next = 0;
            buf_next = {rx, buf_reg[7:1]};
            if (bit_cnt_reg == 7) begin
              n_state = STOP;
            end else begin
              bit_cnt_next = bit_cnt_reg + 1;
            end
          end else begin
            b_tick_cnt_next = b_tick_cnt_reg + 1;
          end
        end

      end
      STOP: begin
        if (b_tick)
          if (b_tick_cnt_reg == 15) begin
            n_state   = IDLE;
            done_next = 1'b1;
          end else begin
            b_tick_cnt_next = b_tick_cnt_reg + 1;
          end
      end
    endcase
  end

endmodule

module uart_tx (
    input clk,
    input reset,
    input tx_start,
    input b_tick,
    input [7:0] tx_data,
    output tx_busy,
    output tx_done,
    output uart_tx
);
  localparam IDLE = 2'd0, START = 2'd1;
  localparam DATA = 2'd2;
  localparam STOP = 2'd3;




  reg [1:0] c_state, n_state;
  reg tx_reg, tx_next;
  reg [2:0] bit_cnt_reg, bit_cnt_next;
  reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
  reg busy_reg, busy_next;
  reg done_reg, done_next;
  reg [7:0] data_in_buf_reg, data_in_buf_next;
  assign uart_tx = tx_reg;
  assign tx_busy = busy_reg;
  assign tx_done = done_reg;




  always @(posedge clk, posedge reset) begin
    if (reset) begin
      c_state <= IDLE;
      tx_reg <= 1'b1;
      bit_cnt_reg <= 1'b0;
      b_tick_cnt_reg <= 4'h0;
      busy_reg <= 1'b0;
      done_reg <= 1'b0;
      data_in_buf_reg <= 8'h00;

    end else begin
      c_state <= n_state;
      tx_reg <= tx_next;
      bit_cnt_reg <= bit_cnt_next;
      b_tick_cnt_reg <= b_tick_cnt_next;
      busy_reg <= busy_next;
      done_reg <= done_next;
      data_in_buf_reg <= data_in_buf_next;
    end
  end

  always @(*) begin
    n_state = c_state;
    tx_next = tx_reg;
    bit_cnt_next = bit_cnt_reg;
    b_tick_cnt_next = b_tick_cnt_reg;
    busy_next = busy_reg;
    done_next = done_reg;
    data_in_buf_next = data_in_buf_reg;


    case (c_state)
      IDLE: begin
        tx_next = 1'b1;
        bit_cnt_next = 1'b0;
        b_tick_cnt_next = 4'h0;
        busy_next = 1'b0;
        done_next = 1'b0;
        if (tx_start) begin
          n_state = START;
          busy_next = 1'b1;
          data_in_buf_next = tx_data;

        end
      end

      START: begin

        tx_next = 1'b0;
        if (b_tick) begin
          if (b_tick_cnt_reg == 15) begin
            n_state = DATA;
            b_tick_cnt_next = 4'h0;
          end else begin
            b_tick_cnt_next = b_tick_cnt_reg + 1;
          end
        end
      end

      DATA: begin
        tx_next = data_in_buf_reg[0];
        if (b_tick) begin
          if (b_tick_cnt_reg == 15) begin
            if (bit_cnt_reg == 7) begin
              b_tick_cnt_next = 4'h0;
              n_state = STOP;
            end else begin
              b_tick_cnt_next = 4'h0;
              bit_cnt_next = bit_cnt_reg + 1;
              data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
              n_state = DATA;
            end
          end else begin
            b_tick_cnt_next = b_tick_cnt_reg + 1;
          end

        end
      end


      STOP: begin
        tx_next = 1'b1;
        if (b_tick) begin
          if (b_tick_cnt_reg == 15) begin
            done_next = 1'b1;
            n_state   = IDLE;

          end else begin
            b_tick_cnt_next = b_tick_cnt_reg + 1;
          end
        end
      end
    endcase
  end
endmodule







module b_tick (
    input clk,
    input reset,
    output reg b_tick

);

  parameter TIMES = 9600 * 16;
  parameter COUNT = 100_000_000 / TIMES;

  reg [$clog2(COUNT)-1:0] counter_reg;


  always @(posedge clk, posedge reset) begin
    if (reset) begin
      counter_reg <= 1'b0;
      b_tick <= 1'b0;
    end else begin
      counter_reg <= counter_reg + 1;
      if (counter_reg == (COUNT - 1)) begin
        counter_reg <= 0;
        b_tick <= 1'b1;
      end else begin
        b_tick <= 1'b0;
      end
    end
  end

endmodule


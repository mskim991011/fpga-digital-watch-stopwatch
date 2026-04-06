`timescale 1ns / 1ps

module top_stopwatch_watch (
    input        clk,
    input        reset,
    input  [2:0] sw,
    input        btn_r,
    input        btn_l,
    input        btn_u,
    input        btn_d,
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output [3:0] o_hour_10,
    output [3:0] o_hour_1,
    output [3:0] o_min_10,
    output [3:0] o_min_1,
    output [3:0] o_sec_10,
    output [3:0] o_sec_1,
    output [3:0] o_msec_10,
    output [3:0] o_msec_1
);
  wire w_runstop, w_clear, w_mode;
  wire o_btn_runstop, o_btn_clear;
  wire [23:0] w_stopwatch_time;
  wire [23:0] w_watch_time;
  reg  [23:0] w_fnd_in_data;
  wire db_btn_r, db_btn_l, db_btn_u, db_btn_d;
  wire [1:0] w_cursor;


  wire [4:0] cur_hour = w_fnd_in_data[23:19];
  wire [5:0] cur_min = w_fnd_in_data[18:13];
  wire [5:0] cur_sec = w_fnd_in_data[12:7];
  wire [6:0] cur_msec = w_fnd_in_data[6:0];

  
  assign o_hour_10 = cur_hour / 10;
  assign o_hour_1  = cur_hour % 10;
  assign o_min_10  = cur_min / 10;
  assign o_min_1   = cur_min % 10;
  assign o_sec_10  = cur_sec / 10;
  assign o_sec_1   = cur_sec % 10;
  assign o_msec_10 = cur_msec / 10; 
  assign o_msec_1  = cur_msec % 10; 



  wire sel_mode = sw[1];

  assign o_btn_runstop = (sel_mode == 1'b1) ? (db_btn_r | btn_r) : 1'b0;
  assign o_btn_clear   = (sel_mode == 1'b1) ? (db_btn_l | btn_l) : 1'b0;

  wire w_btn_left = (sel_mode == 1'b0) ? (db_btn_l | btn_l) : 1'b0;
  wire w_btn_right = (sel_mode == 1'b0) ? (db_btn_r | btn_r) : 1'b0;
  wire w_btn_up = (sel_mode == 1'b0) ? (db_btn_u | btn_u) : 1'b0;
  wire w_btn_down = (sel_mode == 1'b0) ? (db_btn_d | btn_d) : 1'b0;


  always @(*) begin
    if (sel_mode == 1'b1) w_fnd_in_data = w_stopwatch_time;
    else w_fnd_in_data = w_watch_time;
  end




  control_unit U_CONTROL_UNIT (


      .clk(clk),
      .reset(reset),
      .i_mode(sw[0]),
      .i_runstop(o_btn_runstop),
      .i_clear(o_btn_clear),
      .o_mode(w_mode),
      .o_runstop(w_runstop),
      .o_clear(w_clear)
  );
  stopwatch_datapath U_STOPWATCH_DATAPATH (
      .clk(clk),
      .reset(reset),
      .mode(w_mode),
      .clear(w_clear),
      .run_stop(w_runstop),
      .msec(w_stopwatch_time[6:0]),
      .sec(w_stopwatch_time[12:7]),
      .min(w_stopwatch_time[18:13]),
      .hour(w_stopwatch_time[23:19])
  );

  watch_datapath U_WATCH_DATAPATH (
      .clk(clk),
      .reset(reset),
      .btn_l(w_btn_left),
      .btn_r(w_btn_right),
      .btn_u(w_btn_up),
      .btn_d(w_btn_down),
      .msec(w_watch_time[6:0]),
      .sec(w_watch_time[12:7]),
      .min(w_watch_time[18:13]),
      .hour(w_watch_time[23:19]),
      .o_cursor(w_cursor)
  );

  fnd_controller U_FND_CNT (

      .clk(clk),
      .reset(reset),
      .sel_display(sw[2]),
      .fnd_in_data(w_fnd_in_data),
      .i_cursor((sw[1] == 1'b0) ? w_cursor : 2'b00),
      .fnd_digit(fnd_digit),
      .fnd_data(fnd_data)
  );
endmodule

module watch_datapath (
    input clk,
    input reset,
    input btn_l,
    btn_r,
    input btn_u,
    btn_d,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour,
    output [1:0] o_cursor
);
  wire w_tick_100hz, w_msec_carry, w_sec_carry, w_min_carry;


  tickgen_100hz U_TICK_100HZ (
      .clk(clk),
      .reset(reset),
      .i_runstop(1'b1),
      .clear(1'b0),
      .o_tick_100hz(w_tick_100hz)
  );

  reg [1:0] cursor;
  assign o_cursor = cursor;
  reg prev_l, prev_r, prev_u, prev_d;
  wire edge_l = btn_l & ~prev_l;
  wire edge_r = btn_r & ~prev_r;
  wire edge_u = btn_u & ~prev_u;
  wire edge_d = btn_d & ~prev_d;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      cursor <= 0;
      prev_l <= 0;
      prev_r <= 0;
      prev_u <= 0;
      prev_d <= 0;
    end else begin
      prev_l <= btn_l;
      prev_r <= btn_r;
      prev_u <= btn_u;
      prev_d <= btn_d;

      if (edge_r) begin
        if (cursor == 0) cursor <= 3;
        else cursor <= cursor - 1;
      end else if (edge_l) begin
        if (cursor == 0) cursor <= 1;
        else if (cursor == 3) cursor <= 0;
        else cursor <= cursor + 1;
      end
    end
  end

  wire manual_tick = edge_u | edge_d;
  wire manual_mode = edge_d;

  tick_counter #(
      .BIT_WIDTH(7),
      .TIMES(100),
      .RESET_VALUE(0)
  ) msec_cnt (
      .clk(clk),
      .reset(reset),
      .i_tick(w_tick_100hz),
      .mode(1'b0),
      .clear(1'b0),
      .run_stop(1'b1),
      .o_count(msec),
      .o_tick(w_msec_carry)
  );

  wire sec_tick = (cursor == 1) ? manual_tick : w_msec_carry;
  wire sec_mode = (cursor == 1) ? manual_mode : 1'b0;

  tick_counter #(
      .BIT_WIDTH(6),
      .TIMES(60),
      .RESET_VALUE(0)
  ) sec_cnt (
      .clk(clk),
      .reset(reset),
      .i_tick(sec_tick),
      .mode(sec_mode),
      .clear(1'b0),
      .run_stop(1'b1),
      .o_count(sec),
      .o_tick(w_sec_carry)
  );


  wire min_tick = (cursor == 2) ? manual_tick : (w_sec_carry & (cursor != 1));
  wire min_mode = (cursor == 2) ? manual_mode : 1'b0;

  tick_counter #(
      .BIT_WIDTH(6),
      .TIMES(60),
      .RESET_VALUE(0)
  ) min_cnt (
      .clk(clk),
      .reset(reset),
      .i_tick(min_tick),
      .mode(min_mode),
      .clear(1'b0),
      .run_stop(1'b1),
      .o_count(min),
      .o_tick(w_min_carry)
  );


  wire hour_tick = (cursor == 3) ? manual_tick : (w_min_carry & (cursor != 2));
  wire hour_mode = (cursor == 3) ? manual_mode : 1'b0;

  tick_counter #(
      .BIT_WIDTH(5),
      .TIMES(24),
      .RESET_VALUE(12)
  ) hour_cnt (
      .clk(clk),
      .reset(reset),
      .i_tick(hour_tick),
      .mode(hour_mode),
      .clear(1'b0),
      .run_stop(1'b1),
      .o_count(hour),
      .o_tick()
  );

endmodule

module stopwatch_datapath (
    input clk,
    input reset,
    input mode,
    input clear,
    input run_stop,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
  wire w_tick_100, w_sec_tick, w_min_tick, w_hour_tick;

  tick_counter #(
      .BIT_WIDTH(5),
      .TIMES(24)
  ) hour_counter (
      .clk(clk),
      .reset(reset),
      .i_tick(w_hour_tick),
      .mode(mode),
      .clear(clear),
      .run_stop(run_stop),
      .o_count(hour),
      .o_tick()
  );

  tick_counter #(
      .BIT_WIDTH(6),
      .TIMES(60)
  ) min_counter (
      .clk(clk),
      .reset(reset),
      .i_tick(w_min_tick),
      .mode(mode),
      .clear(clear),
      .run_stop(run_stop),
      .o_count(min),
      .o_tick(w_hour_tick)
  );

  tick_counter #(
      .BIT_WIDTH(6),
      .TIMES(60)
  ) sec_counter (
      .clk(clk),
      .reset(reset),
      .i_tick(w_sec_tick),
      .mode(mode),
      .clear(clear),
      .run_stop(run_stop),
      .o_count(sec),
      .o_tick(w_min_tick)
  );

  tick_counter #(
      .BIT_WIDTH(7),
      .TIMES(100)
  ) msec_counter (
      .clk(clk),
      .reset(reset),
      .i_tick(w_tick_100),
      .mode(mode),
      .clear(clear),
      .run_stop(run_stop),
      .o_count(msec),
      .o_tick(w_sec_tick)
  );

  tickgen_100hz U_TICK (
      .clk(clk),
      .reset(reset),
      .i_runstop(run_stop),
      .o_tick_100hz(w_tick_100)
  );
endmodule



module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100,
    RESET_VALUE = 0
) (
    input clk,
    input reset,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output [BIT_WIDTH-1:0] o_count,
    output reg o_tick
);
  reg [BIT_WIDTH-1:0] counter_reg, counter_next;
  assign o_count = counter_reg;

  always @(posedge clk, posedge reset) begin
    if (reset | clear) begin
      counter_reg <= RESET_VALUE;
    end else begin
      counter_reg <= counter_next;
    end
  end
  always @(*) begin
    counter_next = counter_reg;
    o_tick = 1'b0;
    if (i_tick & run_stop) begin
      if (mode == 1'b1) begin

        if (counter_reg == 0) begin
          counter_next = TIMES - 1;
          o_tick = 1'b1;
        end else begin
          counter_next = counter_reg - 1;
          o_tick = 1'b0;
        end
      end else begin
        if (counter_reg == (TIMES - 1)) begin
          counter_next = 0;
          o_tick = 1'b1;
        end else begin
          counter_next = counter_reg + 1;
          o_tick = 1'b0;
        end
      end
    end
  end
endmodule

module tickgen_100hz (
    input clk,
    input reset,
    input i_runstop,
    input clear,
    output reg o_tick_100hz
);
  parameter F_COUNT = 100;
  reg [$clog2(F_COUNT)-1:0] r_counter;

  always @(posedge clk, posedge reset) begin
    if (reset) begin
      r_counter <= 0;
      o_tick_100hz <= 1'b0;
    end else begin
      if (i_runstop) begin
        r_counter <= r_counter + 1;
        if (r_counter == (F_COUNT - 1)) begin
          r_counter <= 0;
          o_tick_100hz <= 1'b1;
        end else begin
          o_tick_100hz <= 1'b0;

        end
      end
    end
  end
endmodule

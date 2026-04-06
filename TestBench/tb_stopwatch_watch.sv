`timescale 1ns / 1ps

interface stopwatch_watch_if (
    input logic clk
);
  logic       reset;
  logic [2:0] sw;
  logic       btn_r;
  logic       btn_l;
  logic       btn_u;
  logic       btn_d;
  logic [3:0] o_hour_10, o_hour_1;
  logic [3:0] o_min_10, o_min_1;
  logic [3:0] o_sec_10, o_sec_1;
  logic [3:0] o_msec_10, o_msec_1;
endinterface

class transaction;
  rand bit [ 2:0] action;
  rand int        waiting;
  logic           btn_r,      btn_l;
  logic    [31:0] total_time;
  logic    [ 3:0] o_hour_10,  o_hour_1;
  logic    [ 3:0] o_min_10,   o_min_1;
  logic    [ 3:0] o_sec_10,   o_sec_1;
  logic    [ 3:0] o_msec_10,  o_msec_1;


  constraint range {waiting inside {[2000 : 10000]};}
  constraint action_range {action inside {[0 : 2]};}

  function void display(string name);
    $display("[%t] [%s] task=%d, wait=%d, time=%d ms", $time, name, action, waiting, total_time);
  endfunction
endclass

class generator;
  transaction tr;
  mailbox #(transaction) gen2drv_mbox;

  function new(mailbox#(transaction) gen2drv_mbox);
    this.gen2drv_mbox = gen2drv_mbox;
  endfunction

  task run(int run_count);
    repeat (run_count) begin
      tr = new();
      tr.randomize();
      tr.display("GEN");
      gen2drv_mbox.put(tr);
    end
  endtask
endclass

class driver;
  transaction tr;
  virtual stopwatch_watch_if stopwatch_watch_if;
  mailbox #(transaction) gen2drv_mbox;

  function new(virtual stopwatch_watch_if stopwatch_watch_if, mailbox#(transaction) gen2drv_mbox);
    this.stopwatch_watch_if = stopwatch_watch_if;
    this.gen2drv_mbox = gen2drv_mbox;
  endfunction

  task preset();
    stopwatch_watch_if.reset = 1;
    stopwatch_watch_if.btn_r = 0;
    stopwatch_watch_if.btn_l = 0;
    stopwatch_watch_if.sw    = 3'b000;
    @(negedge stopwatch_watch_if.clk);
    @(negedge stopwatch_watch_if.clk);
    stopwatch_watch_if.reset = 0;
    @(negedge stopwatch_watch_if.clk);
  endtask

  task run();
    forever begin
      gen2drv_mbox.get(tr);
      @(posedge stopwatch_watch_if.clk);
      #1;

      case (tr.action)
        1: begin
          stopwatch_watch_if.btn_r = 1;
          @(posedge stopwatch_watch_if.clk);
          stopwatch_watch_if.btn_r = 0;
          $display("[%t] btn_r (RUN) - Waiting %d", $time, tr.waiting);
          #(tr.waiting);
          stopwatch_watch_if.btn_r = 1;
          $display("[%t] btn_r (STOP)", $time);
          @(posedge stopwatch_watch_if.clk);
          stopwatch_watch_if.btn_r = 0;
          @(posedge stopwatch_watch_if.clk);
          @(posedge stopwatch_watch_if.clk);
          @(posedge stopwatch_watch_if.clk);
          @(posedge stopwatch_watch_if.clk);
        end

        2: begin
          stopwatch_watch_if.btn_l = 1;
          @(posedge stopwatch_watch_if.clk);
          #1;
          stopwatch_watch_if.btn_l = 0;
          @(posedge stopwatch_watch_if.clk);
          @(posedge stopwatch_watch_if.clk);
          @(posedge stopwatch_watch_if.clk);
          @(posedge stopwatch_watch_if.clk);
        end

        0: begin
          #(tr.waiting);
        end
      endcase
    end
  endtask
endclass

class monitor;
  transaction tr;
  mailbox #(transaction) mon2scb_mbox;
  virtual stopwatch_watch_if stopwatch_watch_if;
  int prev_time = -1;
  logic prev_r = 0, prev_l = 0;


  function new(mailbox#(transaction) mon2scb_mbox, virtual stopwatch_watch_if stopwatch_watch_if);
    this.mon2scb_mbox = mon2scb_mbox;
    this.stopwatch_watch_if = stopwatch_watch_if;
  endfunction

  task run();
    int current_time;
    forever begin
      @(posedge stopwatch_watch_if.clk);
      #2;
      current_time = (stopwatch_watch_if.o_hour_10 * 36000000) + 
                     (stopwatch_watch_if.o_hour_1  * 3600000)  + 
                     (stopwatch_watch_if.o_min_10  * 600000)   + 
                     (stopwatch_watch_if.o_min_1   * 60000)    + 
                     (stopwatch_watch_if.o_sec_10  * 10000)    + 
                     (stopwatch_watch_if.o_sec_1   * 1000)     + 
                     (stopwatch_watch_if.o_msec_10 * 100)      + 
                     (stopwatch_watch_if.o_msec_1  * 10);

      if (current_time != prev_time || stopwatch_watch_if.btn_r != prev_r || stopwatch_watch_if.btn_l != prev_l) begin
        tr = new();
        tr.btn_r = stopwatch_watch_if.btn_r;
        tr.btn_l = stopwatch_watch_if.btn_l;
        tr.total_time = current_time;
        tr.o_min_10 = stopwatch_watch_if.o_min_10;
        tr.o_min_1 = stopwatch_watch_if.o_min_1;
        tr.o_sec_10 = stopwatch_watch_if.o_sec_10;
        tr.o_sec_1 = stopwatch_watch_if.o_sec_1;
        tr.o_msec_10 = stopwatch_watch_if.o_msec_10;
        tr.o_msec_1 = stopwatch_watch_if.o_msec_1;

        mon2scb_mbox.put(tr);
        prev_time = current_time;
        prev_r = stopwatch_watch_if.btn_r;
        prev_l = stopwatch_watch_if.btn_l;
      end
    end
  endtask
endclass

class scoreboard;
  transaction tr;
  mailbox #(transaction) mon2scb_mbox;

  int start_time = 0;
  int stop_time =0 ;
  logic prev_btn_r = 0;
  logic prev_btn_l = 0;
  bit reg_stage = 0; 

  function new(mailbox#(transaction) mon2scb_mbox);
    this.mon2scb_mbox = mon2scb_mbox;
  endfunction

  task run();
    forever begin
      mon2scb_mbox.get(tr); 

    
      if ((tr.btn_r == 1) && (prev_btn_r == 0)) begin
        reg_stage = ~reg_stage;
        if (reg_stage) begin
          start_time = tr.total_time;
        end else begin
          stop_time = tr.total_time;
          if (stop_time >= start_time) begin
            $display("--------------------------------------------------");
            $display("[%0t] : btn_r [PASS] RUNSTOP Success! ", $time);
            $display("--------------------------------------------------");
          end else begin
            $error("[%0t] : btn_r [FAIL] STOPWATCH Error! %d > E%d", $time, start_time, stop_time);
          end
        end
      end
      
   
      else if ((tr.btn_l == 1) && (prev_btn_l == 0)) begin
       
        reg_stage  = 0;
        start_time = 0;
        stop_time  = 0;

      if (tr.total_time != 0) mon2scb_mbox.get(tr); 

       
        if (tr.total_time == 0) begin
          $display("==================================================");
          $display("[%t] : btn_l [PASS] CLEAR Success! STOPWACH 0", $time);
          $display("==================================================");
        end else begin
          
          $display("[%t] : btn_l [FAIL] CLEAR Failed! Current Time: %0d ms", $time, tr.total_time);
        end
      end
      prev_btn_r = tr.btn_r;
      prev_btn_l = tr.btn_l;
    end
  endtask
endclass

class environment;

  generator gen;
  driver drv;
  monitor mon;
  scoreboard scb;
  mailbox #(transaction) gen2drv_mbox;
  mailbox #(transaction) mon2scb_mbox;

  function new(virtual stopwatch_watch_if stopwatch_watch_if);
    gen2drv_mbox = new();
    mon2scb_mbox = new();

    gen = new(gen2drv_mbox);
    drv = new(stopwatch_watch_if, gen2drv_mbox);
    mon = new(mon2scb_mbox, stopwatch_watch_if);
    scb = new(mon2scb_mbox);
  endfunction

  task run();
    drv.preset();
    fork
      gen.run(10);
      drv.run();
      mon.run();
      scb.run();
    join_none
    #1_000_000;
    $stop;
  endtask
endclass


module tb_stopwatch_watch ();

  logic clk;
  stopwatch_watch_if stopwatch_watch_if (clk);
  environment env;

  top_stopwatch_watch dut (

      .clk(stopwatch_watch_if.clk),
      .reset(stopwatch_watch_if.reset),
      .sw(stopwatch_watch_if.sw),
      .btn_r(stopwatch_watch_if.btn_r),
      .btn_l(stopwatch_watch_if.btn_l),
      .btn_u(stopwatch_watch_if.btn_u),
      .btn_d(stopwatch_watch_if.btn_d),
      .o_hour_10(stopwatch_watch_if.o_hour_10),
      .o_hour_1(stopwatch_watch_if.o_hour_1),
      .o_min_10(stopwatch_watch_if.o_min_10),
      .o_min_1(stopwatch_watch_if.o_min_1),
      .o_sec_10(stopwatch_watch_if.o_sec_10),
      .o_sec_1(stopwatch_watch_if.o_sec_1),
      .o_msec_10(stopwatch_watch_if.o_msec_10),
      .o_msec_1(stopwatch_watch_if.o_msec_1)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    env = new(stopwatch_watch_if);
    env.run();
  end
endmodule

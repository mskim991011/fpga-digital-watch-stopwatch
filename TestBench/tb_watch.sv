`timescale 1ns / 1ps

interface watch_if (
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


 function void display(string name);
    $display("[%t] [%s] Watch Time = %d%d : %d%d : %d%d", 
             $time, name, 
             o_hour_10, o_hour_1, o_min_10, o_min_1, o_sec_10, o_sec_1);
  endfunction
endclass


//class generator;
//  transaction tr;
//  mailbox #(transaction) gen2drv_mbox;
//
//  function new(mailbox#(transaction) gen2drv_mbox);
//    this.gen2drv_mbox = gen2drv_mbox;
//  endfunction
//
//  task run(int run_count);
//    repeat (run_count) begin
//      tr = new();
//      tr.randomize();
//      tr.display("GEN");
//      gen2drv_mbox.put(tr);
//    end
//  endtask
//endclass

class driver;
  transaction tr;
  virtual watch_if watch_if;
 

  function new(virtual watch_if watch_if);
    this.watch_if = watch_if;
  endfunction

  task preset();
    watch_if.reset = 1;
    watch_if.btn_r = 0;
    watch_if.btn_l = 0;
    watch_if.btn_u = 0;
    watch_if.btn_d = 0;
    watch_if.sw    = 3'b000;
    @(negedge watch_if.clk);
    @(negedge watch_if.clk);
    watch_if.reset = 0;
    @(negedge watch_if.clk);
  endtask

   task run();
    preset(); 
    repeat(10) @(posedge watch_if.clk);
    $display("\n==================================================");
    $display("[%t] current time :  23:59:59", $time);
    $display("==================================================\n");
    
   
    tb_watch.dut.U_WATCH_DATAPATH.hour_cnt.counter_reg = 23; 
    tb_watch.dut.U_WATCH_DATAPATH.min_cnt.counter_reg  = 59;
    tb_watch.dut.U_WATCH_DATAPATH.sec_cnt.counter_reg  = 59;
    tb_watch.dut.U_WATCH_DATAPATH.msec_cnt.counter_reg = 99;

    @(posedge watch_if.clk); 
    @(posedge watch_if.clk); 

    release tb_watch.dut.U_WATCH_DATAPATH.hour_cnt.counter_reg;
    release tb_watch.dut.U_WATCH_DATAPATH.min_cnt.counter_reg;
    release tb_watch.dut.U_WATCH_DATAPATH.sec_cnt.counter_reg;
    release tb_watch.dut.U_WATCH_DATAPATH.msec_cnt.counter_reg;

   repeat(20000) @(posedge watch_if.clk);
    $stop; 
  endtask
endclass


class monitor;
  transaction tr;
  mailbox #(transaction) mon2scb_mbox;
  virtual watch_if watch_if;
  int prev_time = -1;
  int curr_time;


  function new(mailbox#(transaction) mon2scb_mbox, virtual watch_if watch_if);
    this.mon2scb_mbox = mon2scb_mbox;
    this.watch_if = watch_if;
  endfunction

   task run();
    forever begin
      @(posedge watch_if.clk);
      #1; 
      curr_time = (watch_if.o_hour_10 * 10 + watch_if.o_hour_1) * 3600 +
                 (watch_if.o_min_10  * 10 + watch_if.o_min_1)  * 60   +
                 (watch_if.o_sec_10  * 10 + watch_if.o_sec_1);  
      if (curr_time != prev_time) begin
        tr = new();
        tr.o_hour_10 = watch_if.o_hour_10; tr.o_hour_1 = watch_if.o_hour_1;
        tr.o_min_10  = watch_if.o_min_10;  tr.o_min_1  = watch_if.o_min_1;
        tr.o_sec_10  = watch_if.o_sec_10;  tr.o_sec_1  = watch_if.o_sec_1;
        tr.display("MON"); 
        mon2scb_mbox.put(tr);
        prev_time = curr_time;
      end
    end
  endtask
endclass

class scoreboard;
  transaction tr;
  mailbox #(transaction) mon2scb_mbox;
  int prev_time = -1;
  int curr_time;

  function new(mailbox #(transaction) mon2scb_mbox);
    this.mon2scb_mbox = mon2scb_mbox;
  endfunction

  task run();
    forever begin
      mon2scb_mbox.get(tr);
      curr_time = (tr.o_hour_10 * 10 + tr.o_hour_1) * 3600 +
                 (tr.o_min_10  * 10 + tr.o_min_1)  * 60   +
                 (tr.o_sec_10  * 10 + tr.o_sec_1);

      if (prev_time != -1) begin

        int expected_time = (prev_time + 1) % 86400; 

        if (curr_time == expected_time) begin
           if (curr_time == 0) begin
             $display("\n********************************************************");
             $display("[%t] [PASS] TIME FLOW SUCCESS", $time);
             $display("********************************************************\n");
           end 
        end else if (prev_time == 43200 && curr_time == 86399);
        else begin
           $display("[%t] [FAIL] TIME ERROR Prev:%d -> Curr:%d (Expect:%d)", 
                   $time, prev_time, curr_time, expected_time);
        end
      end
      prev_time = curr_time;
    end
  endtask
endclass

class environment;
  driver drv;
  monitor mon;
  scoreboard scb;
  mailbox #(transaction) mon2scb_mbox;

  function new(virtual watch_if watch_if);
    mon2scb_mbox = new();
    drv = new(watch_if);
    mon = new(mon2scb_mbox, watch_if);
    scb = new(mon2scb_mbox);
  endfunction

  task run();
    fork
      drv.run();
      mon.run();
      scb.run();
    join
  endtask
endclass


module tb_watch ();

  logic clk;
  watch_if watch_if (clk);
  environment env;

  top_stopwatch_watch dut (

      .clk(watch_if.clk),
      .reset(watch_if.reset),
      .sw(watch_if.sw),
      .btn_r(watch_if.btn_r),
      .btn_l(watch_if.btn_l),
      .btn_u(watch_if.btn_u),
      .btn_d(watch_if.btn_d),
      .o_hour_10(watch_if.o_hour_10),
      .o_hour_1(watch_if.o_hour_1),
      .o_min_10(watch_if.o_min_10),
      .o_min_1(watch_if.o_min_1),
      .o_sec_10(watch_if.o_sec_10),
      .o_sec_1(watch_if.o_sec_1),
      .o_msec_10(watch_if.o_msec_10),
      .o_msec_1(watch_if.o_msec_1)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    env = new(watch_if);
    env.run();
  end
endmodule

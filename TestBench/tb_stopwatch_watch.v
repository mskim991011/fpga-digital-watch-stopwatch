`timescale 1ns / 1ps

interface stopwatch_watch_if(input logic clk);
    logic       reset;
    logic [2:0] sw;       
    logic       btn_r;    
    logic       btn_l;   
    logic       btn_u;   
    logic       btn_d;    
    logic [3:0] o_hour_10, o_hour_1;
    logic [3:0] o_min_10,  o_min_1;
    logic [3:0] o_sec_10,  o_sec_1;
    logic [3:0] o_msec_10, o_msec_1;
endinterface

class transaction;
    rand bit [2:0] action; 
    rand bit      waiting;

    
    logic [31:0]   total_time; 

    
    constraint range { waiting inside {[100:5000]}; }

    function void display(string name);
        $display("[%t] [%s] task=%d, wait=%d, time=%d ms", 
                 $time, name, action, waiting, total_time);
    endfunction
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox #(transaction) gen2drv_mbox, mailbox #(transaction) gen2scb_mbox);
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    task run(int run_count);
        repeat(run_count) begin
            tr = new();
            tr.randomize(); 
            tr.display("GEN");
            gen2drv.put(tr);
        end
    endtask
endclass

class driver;
    transaction tr;
    virtual stopwatch_watch_if stopwatch_watch_if;
    mailbox #(transaction) gen2drv_mbox;

    function new(virtual stopwatch_watch_if stopwatch_watch_if, mailbox #(transaction) gen2drv_mbox);
        this.stopwatch_watch_if = stopwatch_watch_if;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction

    task preset();
        stopwatch_watch_if.reset = 1;
        stopwatch_watch_if.btn_r = 0;
        stopwatch_watch_if.btn_l = 0;
        stopwatch_watch_if.sw    = 3'b010;
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
            tr.display("drv");
            case(tr.action)
                1: begin
                    stopwatch_watch_if.btn_r = 1;
                    @(posedge stopwatch_watch_if.clk);
                    @(posedge stopwatch_watch_if.clk);
                    #1;
                    stopwatch_watch_if.btn_r = 0;
                end
                2: begin
                    stopwatch_watch_if.btn_l = 1;
                    @(posedge stopwatch_watch_if.clk);
                    @(posedge stopwatch_watch_if.clk);
                    #1;
                    stopwatch_watch_if.btn_l = 0;
                end
                0: begin
                end
            endcase
            #(tr.waiting);
        end
    endtask

class monitor;
    transaction tr;
    mailbox#(transaction) mon2scb_mbox;
    virtual stopwatch_watch_if stopwatch_watch_if;
    int prev_time = -1;


    function new(mailbox#(transaction) mon2scb_mbox, 
                virtual stopwatch_watch_if stopwatch_watch_if);
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

        if (current_time != prev_time) begin
            tr = new();
            tr.o_hour_10  = stopwatch_watch_if.o_hour_10;
            tr.o_hour_1   = stopwatch_watch_if.o_hour_1;
            tr.o_min_10  = stopwatch_watch_if.o_min_10;
            tr.o_min_1   = stopwatch_watch_if.o_min_1;
            tr.o_sec_10  = stopwatch_watch_if.o_sec_10;
            tr.o_sec_1   = stopwatch_watch_if.o_sec_1;
            tr.o_msec_10 = stopwatch_watch_if.o_msec_10;
            tr.o_msec_1  = stopwatch_watch_if.o_msec_1;
            tr.total_time = current_time;
            tr.display("MON");
            mon2scb_mbox.put(tr);
            prev_time = current_time;
        end
        end
    endtask 
endclass 

class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    int prev_time = -1;

    function new(mailbox #(transaction) mon2scb_mbox, mailbox #(transaction) gen2scb_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
    endfunction
 task run();
        transaction tr;
        
        forever begin
            mon2scb_mbox.get(tr);
            if (tr.total_time > prev_time || tr.total_time == 0) begin
                $display("[PASS] : %0d%0d:%0d%0d:%0d%0d.%0d%0d)", 
                         tr.total_time, 
                         tr.o_hour_10, tr.o_hour_1, 
                         tr.o_min_10,  tr.o_min_1, 
                         tr.o_sec_10,  tr.o_sec_1, 
                         tr.o_msec_10, tr.o_msec_1);
            end
            else begin
                $error("[FAIL] Time Flow Error! Prev: %0d ms -> Curr: %0d ms", 
                        prev_time, tr.total_time);
            end
            prev_time = tr.total_time;
        end
    endtask   
    
endclass


endclass

module tb_stopwatch_watch();


endmodule

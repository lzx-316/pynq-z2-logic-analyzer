`timescale 1ns/1ps
// TBD-004 / TBD-011..TBD-016 boundary testbench for the logic analyzer.
// Drives one DUT through all cases sequentially and checks internal state.
module logic_analyzer_boundary_tb;

    localparam S_IDLE  = 3'd0;
    localparam S_RUN   = 3'd1;
    localparam S_POST  = 3'd2;
    localparam S_FLUSH = 3'd3;
    localparam S_DONE  = 3'd4;

    reg         clk;
    reg         rst_n;
    reg  [3:0]  probe_i;
    reg  [31:0] ctrl;
    wire [31:0] status;
    wire [3:0]  ram_we_b;
    wire [12:0] ram_addr_b;
    wire [31:0] ram_data_b;

    integer errors;
    integer case_sel;

    // write / wraparound monitor
    integer    wr_count;
    reg        wr_rst;
    reg        wrap_seen;
    reg [12:0] prev_addr;
    reg [10:0] exp_ptr;
    integer    wr_at_trigger;

    logic_analyzer_top dut (
        .sys_clk  (clk),
        .sys_rst_n(rst_n),
        .probe_i  (probe_i),
        .ctrl     (ctrl),
        .status   (status),
        .ram_we_b (ram_we_b),
        .ram_addr_b(ram_addr_b),
        .ram_data_b(ram_data_b)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;      // 50 MHz
    end

    always @(posedge clk) begin
        if (wr_rst) begin
            wr_count  <= 0;
            wrap_seen <= 1'b0;
            prev_addr <= 13'h1FFF;
        end else if (ram_we_b[0]) begin
            wr_count <= wr_count + 1;
            if ((ram_addr_b == 13'd0) && (prev_addr == 13'd8188))
                wrap_seen <= 1'b1;
            prev_addr <= ram_addr_b;
        end
    end

    // global watchdog
    initial begin
        #10000000;
        $display("FAIL: GLOBAL TIMEOUT");
        $finish;
    end

    task chk(input cond, input [8*96-1:0] what);
        begin
            if (cond) $display("    PASS: %0s", what);
            else begin
                $display("    FAIL: %0s", what);
                errors = errors + 1;
            end
        end
    endtask

    task do_reset;
        begin
            rst_n = 1'b0;
            ctrl  = 32'd0;
            probe_i = 4'b0000;
            repeat (10) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
        end
    endtask

    task set_ctrl(input [9:0] pre, input [9:0] post, input [1:0] tmode, input [1:0] tch);
        begin
            ctrl = 32'd0;
            ctrl[25:16] = pre;
            ctrl[15:6]  = post;
            ctrl[5:4]   = tmode;
            ctrl[3:2]   = tch;
        end
    endtask

    task pulse_clear;
        begin
            ctrl[1] = 1'b1;
            @(posedge clk); #1;
            ctrl[1] = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    task pulse_arm;
        begin
            ctrl[0] = 1'b1;
            @(posedge clk); #1;
            ctrl[0] = 1'b0;
        end
    endtask

    // wait for one sample_tick and let the capture engine process it
    task after_tick;
        begin
            @(posedge dut.sample_tick);
            @(posedge clk);
            #1;
        end
    endtask

    task wait_ticks(input integer n);
        integer j;
        begin
            for (j = 0; j < n; j = j + 1)
                @(posedge dut.sample_tick);
            @(posedge clk);
            #1;
        end
    endtask

    task wait_done(input integer max_clk);
        integer j;
        begin
            for (j = 0; j < max_clk && dut.done !== 1'b1; j = j + 1)
                @(posedge clk);
        end
    endtask

    task reset_wr;
        begin
            wr_rst = 1'b1;
            @(posedge clk);
            #1;                 // let the monitor always-block see wr_rst=1
            wr_rst = 1'b0;
        end
    endtask

    initial begin
        errors   = 0;
        case_sel = 0;
        if ($test$plusargs("CASE4"))  case_sel = 4;
        if ($test$plusargs("CASE11")) case_sel = 11;
        if ($test$plusargs("CASE12")) case_sel = 12;
        if ($test$plusargs("CASE13")) case_sel = 13;
        if ($test$plusargs("CASE14")) case_sel = 14;
        if ($test$plusargs("CASE15")) case_sel = 15;
        if ($test$plusargs("CASE16")) case_sel = 16;
        wr_count = 0;
        wr_rst   = 1'b0;
        wrap_seen = 1'b0;
        prev_addr = 13'h1FFF;
        exp_ptr  = 11'd0;
        wr_at_trigger = 0;

        do_reset;
        $display("BOUNDARY_TB start (CASE=%0d, 0=all)", case_sel);

        // ---------------- TBD-004: no trigger ----------------
        if ((case_sel == 0) || (case_sel == 4)) begin
            $display("");
            $display("=== TBD-004: no trigger (probe stays low) ===");
            set_ctrl(10'd8, 10'd4, 2'd0, 2'd0);
            probe_i = 4'b0000;
            pulse_clear;
            wait_ticks(3);
            reset_wr;
            pulse_arm;
            wait_ticks(100);
            chk(dut.u_capture_engine.state == S_RUN, "state stays in RUN");
            chk(dut.u_capture_engine.history_count >= 12'd8, "history_count reached pre_trigger");
            chk(dut.done == 1'b0, "done stays 0");
            chk(dut.trig_flag == 1'b0, "triggered stays 0");
            chk(wr_count >= 90, "ring buffer keeps being written (>=90 samples)");
            pulse_clear;
        end

        // ---------------- TBD-011: rising edge ----------------
        if ((case_sel == 0) || (case_sel == 11)) begin
            $display("");
            $display("=== TBD-011: rising edge (trigger_mode=0) ===");
            set_ctrl(10'd8, 10'd4, 2'd0, 2'd0);
            probe_i = 4'b0000;
            pulse_clear;
            wait_ticks(3);
            pulse_arm;
            wait_ticks(20);
            chk(dut.trig_flag == 1'b0, "no trigger while probe stays low");
            after_tick;
            probe_i[0] = 1'b1;
            exp_ptr = dut.u_capture_engine.wr_ptr;
            after_tick;
            chk(dut.trig_flag == 1'b1, "rising edge triggers");
            chk(dut.u_capture_engine.trigger_ptr == exp_ptr, "trigger_ptr equals wr_ptr at trigger");
            pulse_clear;
        end

        // ---------------- TBD-012: falling edge ----------------
        if ((case_sel == 0) || (case_sel == 12)) begin
            $display("");
            $display("=== TBD-012: falling edge (trigger_mode=1) ===");
            set_ctrl(10'd8, 10'd4, 2'd1, 2'd0);
            probe_i = 4'b0001;
            pulse_clear;
            wait_ticks(4);
            pulse_arm;
            wait_ticks(20);
            chk(dut.trig_flag == 1'b0, "rising transition does NOT trigger in falling mode");
            after_tick;
            probe_i[0] = 1'b0;
            exp_ptr = dut.u_capture_engine.wr_ptr;
            after_tick;
            chk(dut.trig_flag == 1'b1, "falling edge triggers");
            chk(dut.u_capture_engine.trigger_ptr == exp_ptr, "trigger_ptr equals wr_ptr at trigger");
            pulse_clear;
        end

        // ---------------- TBD-013: any edge ----------------
        if ((case_sel == 0) || (case_sel == 13)) begin
            $display("");
            $display("=== TBD-013: any edge (trigger_mode=2) ===");
            set_ctrl(10'd8, 10'd4, 2'd2, 2'd0);
            probe_i = 4'b0000;
            pulse_clear;
            wait_ticks(3);
            pulse_arm;
            wait_ticks(20);
            after_tick;
            probe_i[0] = 1'b1;
            after_tick;
            chk(dut.trig_flag == 1'b1, "any edge: rising transition triggers");
            pulse_clear;
            probe_i = 4'b0001;
            wait_ticks(4);
            pulse_arm;
            wait_ticks(20);
            chk(dut.trig_flag == 1'b0, "any edge: no trigger while stable high");
            after_tick;
            probe_i[0] = 1'b0;
            after_tick;
            chk(dut.trig_flag == 1'b1, "any edge: falling transition triggers");
            pulse_clear;
        end

        // ---------------- TBD-014: pre/post combos ----------------
        if ((case_sel == 0) || (case_sel == 14)) begin
            $display("");
            $display("=== TBD-014: pre/post combinations ===");
            // (a) pre=8 post=4
            set_ctrl(10'd8, 10'd4, 2'd0, 2'd0);
            probe_i = 4'b0000;
            pulse_clear;
            wait_ticks(3);
            reset_wr;
            pulse_arm;
            wait_ticks(20);
            chk(wr_count >= 8, "pre=8/post=4: >=8 samples written before trigger");
            after_tick;
            probe_i[0] = 1'b1;
            after_tick;
            chk(dut.trig_flag == 1'b1, "pre=8/post=4: trigger fires");
            wr_at_trigger = wr_count;
            wait_done(5000);
            chk(dut.done == 1'b1, "pre=8/post=4: done asserts");
            chk((wr_count - wr_at_trigger) == 4, "pre=8/post=4: exactly 4 writes after trigger");
            pulse_clear;

            // (b) pre=0 post=0
            set_ctrl(10'd0, 10'd0, 2'd0, 2'd0);
            probe_i = 4'b0000;
            pulse_clear;
            wait_ticks(2);
            reset_wr;
            pulse_arm;
            after_tick;
            probe_i[0] = 1'b1;
            after_tick;
            chk(dut.trig_flag == 1'b1, "pre=0/post=0: triggers on first allowed edge");
            wr_at_trigger = wr_count;
            wait_done(200);
            chk(dut.done == 1'b1, "pre=0/post=0: done asserts");
            chk((wr_count - wr_at_trigger) == 0, "pre=0/post=0: no post writes");
            pulse_clear;

            // (c) pre=1 post=0
            set_ctrl(10'd1, 10'd0, 2'd0, 2'd0);
            probe_i = 4'b0000;
            pulse_clear;
            wait_ticks(2);
            reset_wr;
            pulse_arm;
            wait_ticks(3);
            after_tick;
            probe_i[0] = 1'b1;
            after_tick;
            chk(dut.trig_flag == 1'b1, "pre=1/post=0: trigger fires");
            wr_at_trigger = wr_count;
            wait_done(200);
            chk(dut.done == 1'b1, "pre=1/post=0: done asserts");
            chk((wr_count - wr_at_trigger) == 0, "pre=1/post=0: no post writes");
            pulse_clear;

            // (d) pre=0 post=1
            set_ctrl(10'd0, 10'd1, 2'd0, 2'd0);
            probe_i = 4'b0000;
            pulse_clear;
            wait_ticks(2);
            reset_wr;
            pulse_arm;
            after_tick;
            probe_i[0] = 1'b1;
            after_tick;
            chk(dut.trig_flag == 1'b1, "pre=0/post=1: trigger fires");
            wr_at_trigger = wr_count;
            wait_done(500);
            chk(dut.done == 1'b1, "pre=0/post=1: done asserts");
            chk((wr_count - wr_at_trigger) == 1, "pre=0/post=1: exactly 1 post write");
            pulse_clear;
        end

        // ---------------- TBD-015: wraparound ----------------
        if ((case_sel == 0) || (case_sel == 15)) begin
            $display("");
            $display("=== TBD-015: ring buffer wraparound (>2048 samples) ===");
            set_ctrl(10'd8, 10'd4, 2'd0, 2'd0);
            probe_i = 4'b0000;
            pulse_clear;
            wait_ticks(3);
            reset_wr;
            pulse_arm;
            wait_ticks(2100);
            chk(wrap_seen == 1'b1, "write address wrapped 8188 -> 0");
            chk(dut.u_capture_engine.history_count == 12'd2048, "history_count capped at 2048");
            chk(wr_count >= 2095, ">=2095 samples written before trigger");
            $display("    INFO: wr_count=%0d  wr_ptr=%0d  wr_count%%2048=%0d", wr_count, dut.u_capture_engine.wr_ptr, wr_count % 2048);
            chk(dut.u_capture_engine.wr_ptr == (wr_count % 2048), "wr_ptr == writes mod 2048");
            after_tick;
            probe_i[0] = 1'b1;
            exp_ptr = dut.u_capture_engine.wr_ptr;
            after_tick;
            chk(dut.trig_flag == 1'b1, "trigger still detected after wraparound");
            chk(dut.u_capture_engine.trigger_ptr == exp_ptr, "trigger_ptr correct after wraparound");
            wait_done(5000);
            chk(dut.done == 1'b1, "done asserts after wraparound capture");
            pulse_clear;
        end

        // ---------------- TBD-016: clear during capture ----------------
        if ((case_sel == 0) || (case_sel == 16)) begin
            $display("");
            $display("=== TBD-016: clear while capturing ===");
            set_ctrl(10'd8, 10'd4, 2'd0, 2'd0);
            probe_i = 4'b0000;
            pulse_clear;
            wait_ticks(3);
            pulse_arm;
            wait_ticks(50);
            chk(dut.u_capture_engine.state == S_RUN, "capture is running");
            chk(dut.done == 1'b0, "done low while running");
            ctrl[1] = 1'b1;
            @(posedge clk); #1;
            ctrl[1] = 1'b0;
            chk(dut.u_capture_engine.state == S_IDLE, "clear during capture returns FSM to IDLE");
            chk(dut.done == 1'b0, "done cleared");
            chk(dut.trig_flag == 1'b0, "triggered cleared");
            chk(dut.u_capture_engine.wr_ptr == 11'd0, "wr_ptr cleared");
            wait_ticks(3);
            pulse_arm;
            wait_ticks(20);
            after_tick;
            probe_i[0] = 1'b1;
            after_tick;
            chk(dut.trig_flag == 1'b1, "re-arm after clear captures again");
            wait_done(5000);
            chk(dut.done == 1'b1, "done asserts after re-arm");
            pulse_clear;
        end

        $display("");
        if (errors == 0) $display("BOUNDARY_SUMMARY: ALL PASS");
        else             $display("BOUNDARY_SUMMARY: %0d FAILURE(S)", errors);
        $finish;
    end
endmodule
`timescale 1ns/1ps

module logic_analyzer_tb;
    reg         clk;
    reg         rst_n;
    reg  [3:0]  probe_i;
    reg  [31:0] ctrl;
    wire [31:0] status;
    wire [3:0]  ram_we_b;
    wire [12:0] ram_addr_b;
    wire [31:0] ram_data_b;

    localparam PRE  = 10'd8;
    localparam POST = 10'd4;

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
        forever #10 clk = ~clk;
    end

    initial begin
        rst_n   = 1'b0;
        probe_i = 4'b0000;
        ctrl    = 32'd0;

        repeat (10) @(posedge clk);
        rst_n = 1'b1;

        ctrl = (PRE << 16) | (POST << 6) | (2'd0 << 4) | (2'd0 << 2);
        @(posedge clk);
        ctrl[1] = 1'b1;
        @(posedge clk);
        ctrl[1] = 1'b0;
        ctrl[0] = 1'b1;
        @(posedge clk);
        ctrl[0] = 1'b0;

        repeat (1200) @(posedge clk);
        probe_i[0] = 1'b1;

        repeat (20000) @(posedge clk);

        if (status[0] !== 1'b1)
            $display("FAIL: done did not assert, status=0x%08X", status);
        else
            $display("PASS: done=1, trigger_ptr=%0d", (status >> 2) & 11'h7FF);

        ctrl[1] = 1'b1;
        @(posedge clk);
        #1;
        ctrl[1] = 1'b0;

        if (status[0] !== 1'b0)
            $display("FAIL: clear did not reset done");
        else
            $display("PASS: clear returned FSM to IDLE");

        $finish;
    end
endmodule

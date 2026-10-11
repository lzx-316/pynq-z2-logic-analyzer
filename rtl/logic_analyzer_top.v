module logic_analyzer_top (
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    input  wire [3:0]  probe_i,
    input  wire [31:0] ctrl,
    output wire [31:0] status,
    output wire [3:0]  ram_we_b,
    output wire [12:0] ram_addr_b,
    output wire [31:0] ram_data_b
);

    wire        arm          = ctrl[0];
    wire        clear        = ctrl[1];
    wire [1:0]  trigger_ch   = ctrl[3:2];
    wire [1:0]  trigger_mode = ctrl[5:4];
    wire [9:0]  post_trigger = ctrl[15:6];
    wire [9:0]  pre_trigger  = ctrl[25:16];
    wire        test_mode    = ctrl[31];

    wire sample_tick;
    wire [3:0] probe_sync;
    wire done;
    wire trig_flag;
    wire [10:0] trigger_ptr;
    wire [10:0] capture_addr_b;

    reg [3:0] test_counter;

    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            test_counter <= 4'b0000;
        else if (sample_tick)
            test_counter <= test_counter + 1'b1;
    end

    wire [3:0] probe_input = test_mode ? test_counter : probe_i;

    sample_divider #(
        .CLK_HZ    (50_000_000),
        .SAMPLE_HZ (1_000_000),
        .CNT_WIDTH (16)
    ) u_sample_divider (
        .clk         (sys_clk),
        .rst_n       (sys_rst_n),
        .sample_tick (sample_tick)
    );

    sync_4ch u_sync_4ch (
        .clk     (sys_clk),
        .rst_n   (sys_rst_n),
        .async_i (probe_input),
        .sync_o  (probe_sync)
    );

    capture_engine #(
        .ADDR_WIDTH (11),
        .DEPTH      (2048)
    ) u_capture_engine (
        .clk          (sys_clk),
        .rst_n        (sys_rst_n),
        .arm          (arm),
        .clear        (clear),
        .sample_tick  (sample_tick),
        .probe_sync   (probe_sync),
        .trigger_ch   (trigger_ch),
        .trigger_mode (trigger_mode),
        .pre_trigger  (pre_trigger),
        .post_trigger (post_trigger),
        .done         (done),
        .triggered    (trig_flag),
        .trigger_ptr  (trigger_ptr),
        .ram_we_b     (ram_we_b),
        .ram_addr_b   (capture_addr_b),
        .ram_data_b   (ram_data_b)
    );

    // BMG 32位地址模式使用字节地址。
    // 低两位固定为0，使每个样本占一个完整的32位字。
    assign ram_addr_b = {capture_addr_b, 2'b00};

    assign status = {19'd0, trigger_ptr, trig_flag, done};

endmodule
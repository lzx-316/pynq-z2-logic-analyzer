module capture_engine #(
    parameter integer ADDR_WIDTH = 11,
    parameter integer DEPTH      = 2048
) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   arm,
    input  wire                   clear,
    input  wire                   sample_tick,
    input  wire [3:0]             probe_sync,
    input  wire [1:0]             trigger_ch,
    input  wire [1:0]             trigger_mode,
    input  wire [9:0]             pre_trigger,
    input  wire [9:0]             post_trigger,
    output reg                    done,
    output reg                    triggered,
    output reg  [ADDR_WIDTH-1:0]  trigger_ptr,
    output wire [3:0]             ram_we_b,
    output wire [ADDR_WIDTH-1:0]  ram_addr_b,
    output wire [31:0]            ram_data_b
);

    localparam S_IDLE  = 3'd0;
    localparam S_RUN   = 3'd1;
    localparam S_POST  = 3'd2;
    localparam S_FLUSH = 3'd3;
    localparam S_DONE  = 3'd4;

    reg [2:0]  state;
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] post_count;
    reg [ADDR_WIDTH:0]   history_count;
    reg [27:0] timestamp;
    reg [3:0]  probe_sample_d;
    reg        arm_d;

    wire arm_rise = arm & ~arm_d;

    wire sel_now  = probe_sync[trigger_ch];
    wire sel_prev = probe_sample_d[trigger_ch];
    wire rising   = sel_now & ~sel_prev;
    wire falling  = ~sel_now & sel_prev;
    wire any_edge = sel_now ^ sel_prev;

    wire edge_now =
        (trigger_mode == 2'd0) ? rising  :
        (trigger_mode == 2'd1) ? falling :
        (trigger_mode == 2'd2) ? any_edge : 1'b0;

    wire history_ok = (history_count >= pre_trigger);
    wire trigger_event = sample_tick && (state == S_RUN) &&
                         history_ok && edge_now;
    wire write_enable = sample_tick && ((state == S_RUN) || (state == S_POST));

    assign ram_we_b   = {4{write_enable}};
    assign ram_addr_b = wr_ptr;
    assign ram_data_b = {timestamp, probe_sync};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= S_IDLE;
            wr_ptr         <= {ADDR_WIDTH{1'b0}};
            post_count     <= {ADDR_WIDTH{1'b0}};
            history_count  <= {(ADDR_WIDTH+1){1'b0}};
            timestamp      <= 28'd0;
            probe_sample_d <= 4'b0000;
            arm_d          <= 1'b0;
            done           <= 1'b0;
            triggered      <= 1'b0;
            trigger_ptr    <= {ADDR_WIDTH{1'b0}};
        end else begin
            arm_d <= arm;

            if (clear) begin
                state          <= S_IDLE;
                wr_ptr         <= {ADDR_WIDTH{1'b0}};
                post_count     <= {ADDR_WIDTH{1'b0}};
                history_count  <= {(ADDR_WIDTH+1){1'b0}};
                timestamp      <= 28'd0;
                probe_sample_d <= 4'b0000;
                done           <= 1'b0;
                triggered      <= 1'b0;
                trigger_ptr    <= {ADDR_WIDTH{1'b0}};
            end else begin
                if (sample_tick)
                    probe_sample_d <= probe_sync;

                case (state)
                    S_IDLE: begin
                        if (arm_rise) begin
                            state         <= S_RUN;
                            wr_ptr        <= {ADDR_WIDTH{1'b0}};
                            post_count    <= {ADDR_WIDTH{1'b0}};
                            history_count <= {(ADDR_WIDTH+1){1'b0}};
                            timestamp     <= 28'd0;
                            done          <= 1'b0;
                            triggered     <= 1'b0;
                            trigger_ptr   <= {ADDR_WIDTH{1'b0}};
                        end
                    end

                    S_RUN: begin
                        if (sample_tick) begin
                            wr_ptr    <= (wr_ptr == DEPTH - 1) ?
                                         {ADDR_WIDTH{1'b0}} : wr_ptr + 1'b1;
                            timestamp <= timestamp + 1'b1;

                            if (history_count < DEPTH)
                                history_count <= history_count + 1'b1;

                            if (trigger_event) begin
                                triggered   <= 1'b1;
                                trigger_ptr <= wr_ptr;

                                if (post_trigger == 10'd0) begin
                                    state <= S_FLUSH;
                                end else begin
                                    post_count <= {ADDR_WIDTH{1'b0}};
                                    state      <= S_POST;
                                end
                            end
                        end
                    end

                    S_POST: begin
                        if (sample_tick) begin
                            wr_ptr    <= (wr_ptr == DEPTH - 1) ?
                                         {ADDR_WIDTH{1'b0}} : wr_ptr + 1'b1;
                            timestamp <= timestamp + 1'b1;

                            if (history_count < DEPTH)
                                history_count <= history_count + 1'b1;

                            if (post_count == post_trigger - 1'b1)
                                state <= S_FLUSH;
                            else
                                post_count <= post_count + 1'b1;
                        end
                    end

                    S_FLUSH: begin
                        state <= S_DONE;
                        done  <= 1'b1;
                    end

                    S_DONE: begin
                        done <= 1'b1;
                    end

                    default: begin
                        state <= S_IDLE;
                    end
                endcase
            end
        end
    end

endmodule

module sample_divider #(
    parameter integer CLK_HZ    = 50_000_000,
    parameter integer SAMPLE_HZ = 1_000_000,
    parameter integer CNT_WIDTH = 16
) (
    input  wire                   clk,
    input  wire                   rst_n,
    output reg                    sample_tick
);

    localparam integer DIV_VALUE = CLK_HZ / SAMPLE_HZ;

    reg [CNT_WIDTH-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter     <= {CNT_WIDTH{1'b0}};
            sample_tick <= 1'b0;
        end else if (counter == DIV_VALUE - 1) begin
            counter     <= {CNT_WIDTH{1'b0}};
            sample_tick <= 1'b1;
        end else begin
            counter     <= counter + 1'b1;
            sample_tick <= 1'b0;
        end
    end

endmodule

module sync_4ch (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] async_i,
    output reg  [3:0] sync_o
);

    (* ASYNC_REG = "TRUE" *) reg [3:0] meta;
    (* ASYNC_REG = "TRUE" *) reg [3:0] sync_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            meta     <= 4'b0000;
            sync_reg <= 4'b0000;
            sync_o   <= 4'b0000;
        end else begin
            meta     <= async_i;
            sync_reg <= meta;
            sync_o   <= sync_reg;
        end
    end

endmodule

module clock_divider #(
    parameter int DIV = 50_000_000   // 50 MHz → 1 Hz tick
)(
    input  logic clk,
    input  logic rst_n,
    output logic tick                // single-cycle pulse every second
);
    logic [$clog2(DIV)-1:0] cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt  <= '0;
            tick <= 1'b0;
        end else if (cnt == DIV - 1) begin
            cnt  <= '0;
            tick <= 1'b1;
        end else begin
            cnt  <= cnt + 1'b1;
            tick <= 1'b0;
        end
    end
endmodule
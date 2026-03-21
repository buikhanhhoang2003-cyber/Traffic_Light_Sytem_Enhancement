module clk_div #(
    parameter CLK_FREQ = 50_000_000
)(
    input  logic clk,
    input  logic rst_n,
    output logic tick_1hz,
    output logic tick_2hz
);
    // ── 1Hz ──────────────────────────────────────────────────────────────────
    logic [25:0] cnt_1hz;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_1hz  <= 0;
            tick_1hz <= 0;
        end else begin
            if (cnt_1hz == CLK_FREQ - 1) begin
                cnt_1hz  <= 0;
                tick_1hz <= 1;
            end else begin
                cnt_1hz  <= cnt_1hz + 1;
                tick_1hz <= 0;
            end
        end
    end

    // ── 2Hz ──────────────────────────────────────────────────────────────────
    logic [24:0] cnt_2hz;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_2hz  <= 0;
            tick_2hz <= 0;
        end else begin
            if (cnt_2hz == (CLK_FREQ/2) - 1) begin
                cnt_2hz  <= 0;
                tick_2hz <= 1;
            end else begin
                cnt_2hz  <= cnt_2hz + 1;
                tick_2hz <= 0;
            end
        end
    end

endmodule
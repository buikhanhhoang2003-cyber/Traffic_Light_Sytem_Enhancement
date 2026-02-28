// =============================================================================
// clk_div.sv — Clock Divider: 50MHz → 1Hz tick pulse
// Also generates a 2Hz tick for blinking-red error state
// =============================================================================
module clk_div #(
    parameter CLK_FREQ = 50_000_000
)(
    input  logic clk,
    input  logic rst_n,         // Active LOW
    output logic tick_1hz,      // Single-cycle pulse every 1 second
    output logic tick_2hz       // Single-cycle pulse every 0.5 second (blink)
);

    localparam HALF_FREQ = CLK_FREQ / 2;   // For 2Hz

    logic [25:0] cnt_1hz;
    logic [24:0] cnt_2hz;

    // ── 1Hz tick ─────────────────────────────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_1hz  <= '0;
            tick_1hz <= 1'b0;
        end else begin
            if (cnt_1hz == CLK_FREQ - 1) begin
                cnt_1hz  <= '0;
                tick_1hz <= 1'b1;
            end else begin
                cnt_1hz  <= cnt_1hz + 1'b1;
                tick_1hz <= 1'b0;
            end
        end
    end

    // ── 2Hz tick (blinking red uses this) ────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_2hz  <= '0;
            tick_2hz <= 1'b0;
        end else begin
            if (cnt_2hz == HALF_FREQ - 1) begin
                cnt_2hz  <= '0;
                tick_2hz <= 1'b1;
            end else begin
                cnt_2hz  <= cnt_2hz + 1'b1;
                tick_2hz <= 1'b0;
            end
        end
    end

endmodule
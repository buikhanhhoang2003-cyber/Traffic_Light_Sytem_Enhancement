// Top-level for RZ-EasyFPGA A2.2
// Cyclone IV EP4CE6E22C8, 50 MHz

module top (
    input  logic       clk,         // PIN_23
    input  logic [3:0] key,         // PIN_91..88, active LOW
    output logic [3:0] led,         // PIN_87..84, active LOW
    output logic [7:0] seg,         // PIN_128,120,124,132,127,125,121,126
    output logic [3:0] digit        // PIN_137,136,135,133
);

    // ── Power-on reset (4-cycle shift register) ───────────────────────
    // Cyclone IV registers initialise to 0; counter counts up to 4 then
    // asserts rst_n high for the rest of operation.
    logic [3:0] por_cnt /* synthesis noprune */;
    logic       rst_n;

    always_ff @(posedge clk) begin
        if (!por_cnt[3]) por_cnt <= por_cnt + 1'b1;
    end
    assign rst_n = por_cnt[3];

    // ── 1 Hz tick ────────────────────────────────────────────────────
    logic tick_1hz;
    clock_divider #(.DIV(50_000_000)) u_clk (
        .clk   (clk),
        .rst_n (rst_n),
        .tick  (tick_1hz)
    );

    // ── Traffic light FSM ────────────────────────────────────────────
    logic       red_sig, green_sig, yellow_sig, blank_sig;
    logic [5:0] countdown;

    traffic_fsm u_fsm (
        .clk       (clk),
        .rst_n     (rst_n),
        .tick_1hz  (tick_1hz),
        .key       (key),
        .red       (red_sig),
        .green     (green_sig),
        .yellow    (yellow_sig),
        .countdown (countdown),
        .blank     (blank_sig)
    );

    // ── 7-segment display ────────────────────────────────────────────
    sevenseg_mux u_mux (
        .clk   (clk),
        .rst_n (rst_n),
        .value (countdown),
        .blank (blank_sig),
        .seg   (seg),
        .digit (digit)
    );

    // ── LED outputs (active LOW: 0 = on) ─────────────────────────────
    // led[0] = RED, led[1] = GREEN, led[2] = YELLOW, led[3] = unused
    assign led[0] = ~red_sig;
    assign led[1] = ~green_sig;
    assign led[2] = ~yellow_sig;
    assign led[3] = 1'b1;    // always off

endmodule
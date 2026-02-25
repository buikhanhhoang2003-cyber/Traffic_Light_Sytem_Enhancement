// Traffic light FSM
//   Auto sequence : RED (30 s) → GREEN (30 s) → YELLOW (5 s) → repeat
//   Key overrides (active LOW, checked every clock):
//     key[0] = KEY1 → force GREEN
//     key[1] = KEY2 → force RED
//     key[2] = KEY3 → force YELLOW
//     key[3] = KEY4 → all OFF  (blank display)
//   Release all keys → returns to AUTO_RED immediately

module traffic_fsm (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tick_1hz,
    input  logic [3:0] key,        // active LOW from board
    output logic       red,
    output logic       green,
    output logic       yellow,
    output logic [5:0] countdown,  // seconds to show on display
    output logic       blank        // 1 = show "--" instead of number
);

    typedef enum logic [2:0] {
        AUTO_RED     = 3'd0,
        AUTO_GREEN   = 3'd1,
        AUTO_YELLOW  = 3'd2,
        FORCE_RED    = 3'd3,
        FORCE_GREEN  = 3'd4,
        FORCE_YELLOW = 3'd5,
        ALL_OFF      = 3'd6
    } state_t;

    state_t   state;
    logic [5:0] timer;

    localparam logic [5:0] T_RED    = 6'd30;
    localparam logic [5:0] T_GREEN  = 6'd30;
    localparam logic [5:0] T_YELLOW = 6'd5;

    // Active-HIGH key signals
    logic k_green, k_red, k_yellow, k_off;
    assign k_green  = ~key[0];
    assign k_red    = ~key[1];
    assign k_yellow = ~key[2];
    assign k_off    = ~key[3];
    assign k_any    = k_green | k_red | k_yellow | k_off;

    // ── State + timer register ────────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= AUTO_RED;
            timer <= T_RED;
        end else begin

            // ── Key override (priority: OFF > YELLOW > RED > GREEN) ──
            if (k_off) begin
                state <= ALL_OFF;
                timer <= '0;

            end else if (k_yellow) begin
                state <= FORCE_YELLOW;
                timer <= '0;

            end else if (k_red) begin
                state <= FORCE_RED;
                timer <= '0;

            end else if (k_green) begin
                state <= FORCE_GREEN;
                timer <= '0;

            end else begin
                // ── Auto mode ───────────────────────────────────────
                unique case (state)

                    AUTO_RED: begin
                        if (tick_1hz) begin
                            if (timer <= 6'd1) begin
                                state <= AUTO_GREEN;
                                timer <= T_GREEN;
                            end else
                                timer <= timer - 1'b1;
                        end
                    end

                    AUTO_GREEN: begin
                        if (tick_1hz) begin
                            if (timer <= 6'd1) begin
                                state <= AUTO_YELLOW;
                                timer <= T_YELLOW;
                            end else
                                timer <= timer - 1'b1;
                        end
                    end

                    AUTO_YELLOW: begin
                        if (tick_1hz) begin
                            if (timer <= 6'd1) begin
                                state <= AUTO_RED;
                                timer <= T_RED;
                            end else
                                timer <= timer - 1'b1;
                        end
                    end

                    default: begin
                        // Returning from any forced state → restart auto RED
                        state <= AUTO_RED;
                        timer <= T_RED;
                    end

                endcase
            end
        end
    end

    // ── Output logic ─────────────────────────────────────────────────
    always_comb begin
        // defaults
        red       = 1'b0;
        green     = 1'b0;
        yellow    = 1'b0;
        blank     = 1'b0;
        countdown = timer;

        case (state)
            AUTO_RED,     FORCE_RED:    red    = 1'b1;
            AUTO_GREEN,   FORCE_GREEN:  green  = 1'b1;
            AUTO_YELLOW,  FORCE_YELLOW: yellow = 1'b1;
            ALL_OFF:                    blank  = 1'b1;
            default: ;
        endcase

			if (state == FORCE_RED || state == FORCE_GREEN || state == FORCE_YELLOW)
				countdown = 6'd0;
    end

endmodule
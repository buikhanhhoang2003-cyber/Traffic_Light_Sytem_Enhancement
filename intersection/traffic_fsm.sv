// =============================================================================
// traffic_fsm.sv
// 8-state FSM per updated state table:
//   S0: A_STRAIGHT   — Axis A straight green + pedestrian
//   S1: A_S_YELLOW   — Axis A straight yellow
//   S2: A_LEFT       — Axis A left green
//   S3: A_L_YELLOW   — Axis A left yellow
//   S4: B_STRAIGHT   — Axis B straight green + pedestrian
//   S5: B_S_YELLOW   — Axis B straight yellow
//   S6: B_LEFT       — Axis B left green
//   S7: B_L_YELLOW   — Axis B left yellow
//   ALL_RED          — Inter-phase all-red buffer (shared)
//   BLINK_RED        — Fault state
// =============================================================================
module traffic_fsm #(
    parameter A_STR_TIME  = 4,   // S0: A straight + ped
    parameter A_SYEL_TIME = 3,   // S1: A straight yellow
    parameter A_LFT_TIME  = 4,   // S2: A left green
    parameter A_LYEL_TIME = 3,   // S3: A left yellow
    parameter B_STR_TIME  = 4,   // S4: B straight + ped
    parameter B_SYEL_TIME = 3,   // S5: B straight yellow
    parameter B_LFT_TIME  = 4,   // S6: B left green
    parameter B_LYEL_TIME = 3,   // S7: B left yellow
    parameter ALLRED_TIME = 2    // All-red buffer between phases
)(
    input  logic clk,
    input  logic rst_n,
    input  logic tick_1hz,
    input  logic tick_2hz,
    input  logic system_fault,

    // Axis A = North/South
    output logic a_str_green,
    output logic a_str_yellow,
    output logic a_str_red,

    output logic a_left_green,
    output logic a_left_yellow,
    output logic a_left_red,

    output logic a_ped_walk,

    // Axis B = East/West
    output logic b_str_green,
    output logic b_str_yellow,
    output logic b_str_red,

    output logic b_left_green,
    output logic b_left_yellow,
    output logic b_left_red,

    output logic b_ped_walk
);

    // =========================================================================
    // STATE ENCODING
    // =========================================================================
    typedef enum logic [3:0] {
        FAIL_SAFE   = 4'd0,
        A_STRAIGHT  = 4'd1,   // S0
        A_S_YELLOW  = 4'd2,   // S1
        ALLRED_1    = 4'd3,   // after S1
        A_LEFT      = 4'd4,   // S2
        A_L_YELLOW  = 4'd5,   // S3
        ALLRED_2    = 4'd6,   // after S3
        B_STRAIGHT  = 4'd7,   // S4
        B_S_YELLOW  = 4'd8,   // S5
        ALLRED_3    = 4'd9,   // after S5
        B_LEFT      = 4'd10,  // S6
        B_L_YELLOW  = 4'd11,  // S7
        ALLRED_4    = 4'd12,  // after S7 → back to S0
        BLINK_RED   = 4'd13   // Fault
    } state_t;

    state_t state;

    // =========================================================================
    // DURATION LOOKUP
    // =========================================================================
    logic [3:0] dur;
    always_comb begin
        case (state)
            A_STRAIGHT : dur = A_STR_TIME [3:0];
            A_S_YELLOW : dur = A_SYEL_TIME[3:0];
            ALLRED_1   : dur = ALLRED_TIME [3:0];
            A_LEFT     : dur = A_LFT_TIME [3:0];
            A_L_YELLOW : dur = A_LYEL_TIME[3:0];
            ALLRED_2   : dur = ALLRED_TIME [3:0];
            B_STRAIGHT : dur = B_STR_TIME [3:0];
            B_S_YELLOW : dur = B_SYEL_TIME[3:0];
            ALLRED_3   : dur = ALLRED_TIME [3:0];
            B_LEFT     : dur = B_LFT_TIME [3:0];
            B_L_YELLOW : dur = B_LYEL_TIME[3:0];
            ALLRED_4   : dur = ALLRED_TIME [3:0];
            default    : dur = 4'd1;
        endcase
    end

    // =========================================================================
    // FAULT LATCH
    // =========================================================================
    logic fault_lat;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) fault_lat <= 0;
        else if (system_fault) fault_lat <= 1;
    end

    // =========================================================================
    // BLINK TOGGLE (2Hz for BLINK_RED)
    // =========================================================================
    logic blink;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)        blink <= 0;
        else if (tick_2hz) blink <= ~blink;
    end

    // =========================================================================
    // TIMER + FSM
    // =========================================================================
    logic [3:0] sec_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= FAIL_SAFE;
            sec_cnt <= 0;
        end

        else if (fault_lat) begin
            state   <= BLINK_RED;
            sec_cnt <= 0;
        end

        else if (tick_1hz) begin
            if (sec_cnt + 1 >= dur) begin
                sec_cnt <= 0;
                case (state)
                    FAIL_SAFE  : state <= A_STRAIGHT;
                    A_STRAIGHT : state <= A_S_YELLOW;
                    A_S_YELLOW : state <= ALLRED_1;
                    ALLRED_1   : state <= A_LEFT;
                    A_LEFT     : state <= A_L_YELLOW;
                    A_L_YELLOW : state <= ALLRED_2;
                    ALLRED_2   : state <= B_STRAIGHT;
                    B_STRAIGHT : state <= B_S_YELLOW;
                    B_S_YELLOW : state <= ALLRED_3;
                    ALLRED_3   : state <= B_LEFT;
                    B_LEFT     : state <= B_L_YELLOW;
                    B_L_YELLOW : state <= ALLRED_4;
                    ALLRED_4   : state <= A_STRAIGHT;  // Loop
                    BLINK_RED  : state <= BLINK_RED;   // Stuck until reset
                    default    : state <= FAIL_SAFE;
                endcase
            end else begin
                sec_cnt <= sec_cnt + 1;
            end
        end
    end

    // =========================================================================
    // OUTPUT LOGIC
    // =========================================================================
    always_comb begin
        // Default: all red
        a_str_green  = 0; a_str_yellow  = 0; a_str_red  = 1;
        a_left_green = 0; a_left_yellow = 0; a_left_red = 1;
        a_ped_walk   = 0;
        b_str_green  = 0; b_str_yellow  = 0; b_str_red  = 1;
        b_left_green = 0; b_left_yellow = 0; b_left_red = 1;
        b_ped_walk   = 0;

        case (state)
            // ── S0: A Straight + Pedestrian ───────────────────────────────────
            A_STRAIGHT: begin
                a_str_green = 1; a_str_red = 0;
                a_ped_walk  = 1;
            end

            // ── S1: A Straight Yellow ─────────────────────────────────────────
            A_S_YELLOW: begin
                a_str_yellow = 1; a_str_red = 0;
            end

            // ── ALL_RED_1 ─────────────────────────────────────────────────────
            ALLRED_1: begin end

            // ── S2: A Left Green ──────────────────────────────────────────────
            A_LEFT: begin
                a_left_green = 1; a_left_red = 0;
            end

            // ── S3: A Left Yellow ─────────────────────────────────────────────
            A_L_YELLOW: begin
                a_left_yellow = 1; a_left_red = 0;
            end

            // ── ALL_RED_2 ─────────────────────────────────────────────────────
            ALLRED_2: begin end

            // ── S4: B Straight + Pedestrian ───────────────────────────────────
            B_STRAIGHT: begin
                b_str_green = 1; b_str_red = 0;
                b_ped_walk  = 1;
            end

            // ── S5: B Straight Yellow ─────────────────────────────────────────
            B_S_YELLOW: begin
                b_str_yellow = 1; b_str_red = 0;
            end

            // ── ALL_RED_3 ─────────────────────────────────────────────────────
            ALLRED_3: begin end

            // ── S6: B Left Green ──────────────────────────────────────────────
            B_LEFT: begin
                b_left_green = 1; b_left_red = 0;
            end

            // ── S7: B Left Yellow ─────────────────────────────────────────────
            B_L_YELLOW: begin
                b_left_yellow = 1; b_left_red = 0;
            end

            // ── ALL_RED_4 ─────────────────────────────────────────────────────
            ALLRED_4: begin end

            // ── BLINK_RED: Fault ──────────────────────────────────────────────
            BLINK_RED: begin
                a_str_red  = blink;
                a_left_red = blink;
                b_str_red  = blink;
                b_left_red = blink;
            end

            // ── FAIL_SAFE / Default ───────────────────────────────────────────
            default: begin end

        endcase
    end

endmodule
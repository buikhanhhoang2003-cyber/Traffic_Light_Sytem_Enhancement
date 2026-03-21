// =============================================================================
// traffic_fsm.sv — Main Traffic Light FSM
//
// States:
//   FAIL_SAFE        : All-Red. Default on reset.
//   NS_GREEN         : N/S Straight + Left Green. Pedestrian first 4s.
//   NS_YELLOW        : N/S Straight + Left Yellow. E/W still Red.
//   ALL_RED_A        : 2-second All-Red clearance buffer (NS→EW transition).
//   EW_GREEN         : E/W Straight + Left Green. Pedestrian first 4s.
//   EW_YELLOW        : E/W Straight + Left Yellow. N/S still Red.
//   ALL_RED_B        : 2-second All-Red clearance buffer (EW→NS transition).
//   EMERGENCY_YELLOW : Forces current green to yellow immediately.
//   EMERGENCY_RED    : All-Red during emergency clearance (2s).
//   EMERGENCY_GREEN  : Emergency vehicle green (N/S priority).
//   BLINK_RED        : Fault state — all outputs blink red.
//
// Transition Summary:
//   FAIL_SAFE → NS_GREEN (on rst_n=1)
//   NS_GREEN  → NS_YELLOW (timer done OR gap-out)
//   NS_YELLOW → ALL_RED_A
//   ALL_RED_A → EW_GREEN
//   EW_GREEN  → EW_YELLOW (timer done OR gap-out)
//   EW_YELLOW → ALL_RED_B
//   ALL_RED_B → NS_GREEN
//
//   Any state + emergency_trigger → EMERGENCY_YELLOW
//   EMERGENCY_YELLOW (5s) → EMERGENCY_RED (2s) → EMERGENCY_GREEN
//   EMERGENCY_GREEN: holds while emergency_trigger=1, then → ALL_RED_A
//
//   system_fault → BLINK_RED (latched until reset)
// =============================================================================
module traffic_fsm #(
    parameter GREEN_TIME  = 9,   // seconds
    parameter YELLOW_TIME = 5,   // seconds
    parameter PED_TIME    = 4,   // seconds (sub-phase of green)
    parameter GAPOUT_TIME = 3,   // seconds (early green termination)
    parameter ALLRED_TIME = 2,   // seconds (clearance buffer)
    parameter EMERG_TIME  = 2    // seconds (emergency all-red)
)(
    input  logic clk,
    input  logic rst_n,             // Active LOW reset
    input  logic tick_1hz,          // 1Hz pulse from clk_div
    input  logic tick_2hz,          // 2Hz pulse for blink
    input  logic ns_sensor,         // HIGH = vehicle present (N/S)
    input  logic ew_sensor,         // HIGH = vehicle present (E/W)
    input  logic emergency_trigger, // HIGH = emergency vehicle
    input  logic system_fault,      // HIGH = conflict detected (from monitor)

    // ── N/S outputs ──────────────────────────────────────────────────────────
    output logic ns_str_green,  ns_str_yellow,  ns_str_red,
    output logic ns_left_green, ns_left_yellow, ns_left_red,
    output logic ns_ped_walk,

    // ── E/W outputs ──────────────────────────────────────────────────────────
    output logic ew_str_green,  ew_str_yellow,  ew_str_red,
    output logic ew_left_green, ew_left_yellow, ew_left_red,
    output logic ew_ped_walk
);

    // ── State Encoding ────────────────────────────────────────────────────────
    typedef enum logic [3:0] {
        FAIL_SAFE        = 4'd0,
        NS_GREEN         = 4'd1,
        NS_YELLOW        = 4'd2,
        ALL_RED_A        = 4'd3,
        EW_GREEN         = 4'd4,
        EW_YELLOW        = 4'd5,
        ALL_RED_B        = 4'd6,
        EMERGENCY_YELLOW = 4'd7,
        EMERGENCY_RED    = 4'd8,
        EMERGENCY_GREEN  = 4'd9,
        BLINK_RED        = 4'd10
    } state_t;

    state_t current_state, next_state;

    // ── Timer ─────────────────────────────────────────────────────────────────
    logic [3:0] timer;
    logic       timer_done;
    logic [3:0] phase_duration;

    // Duration per state
    always_comb begin
        case (current_state)
            NS_GREEN         : phase_duration = GREEN_TIME[3:0];
            NS_YELLOW        : phase_duration = YELLOW_TIME[3:0];
            ALL_RED_A        : phase_duration = ALLRED_TIME[3:0];
            EW_GREEN         : phase_duration = GREEN_TIME[3:0];
            EW_YELLOW        : phase_duration = YELLOW_TIME[3:0];
            ALL_RED_B        : phase_duration = ALLRED_TIME[3:0];
            EMERGENCY_YELLOW : phase_duration = YELLOW_TIME[3:0];
            EMERGENCY_RED    : phase_duration = EMERG_TIME[3:0];
            EMERGENCY_GREEN  : phase_duration = GREEN_TIME[3:0];
            default          : phase_duration = 4'd1;
        endcase
    end

    assign timer_done = (timer >= phase_duration);

    // Timer register — resets on state change
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            timer <= 4'd0;
        else if (current_state != next_state)
            timer <= 4'd0;           // Reset on any state transition
        else if (tick_1hz && !timer_done)
            timer <= timer + 1'b1;
    end

    // ── Gap-Out Logic ─────────────────────────────────────────────────────────
    // If sensor goes LOW during green AND timer >= GAPOUT_TIME → terminate early
    logic ns_gapout, ew_gapout;
    assign ns_gapout = (current_state == NS_GREEN) &&
                       (!ns_sensor) &&
                       (timer >= GAPOUT_TIME[3:0]);
    assign ew_gapout = (current_state == EW_GREEN) &&
                       (!ew_sensor) &&
                       (timer >= GAPOUT_TIME[3:0]);

    // ── Blink Toggle (for BLINK_RED state) ───────────────────────────────────
    logic blink_tog;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            blink_tog <= 1'b0;
        else if (tick_2hz)
            blink_tog <= ~blink_tog;
    end

    // ── FSM State Register ────────────────────────────────────────────────────
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= FAIL_SAFE;
        else
            current_state <= next_state;
    end

    // ── FSM Next-State Logic ──────────────────────────────────────────────────
    always_comb begin
        next_state = current_state; // Default: hold

        // FAULT overrides everything (except already in BLINK_RED)
        if (system_fault && current_state != BLINK_RED)
            next_state = BLINK_RED;

        // EMERGENCY overrides normal flow (not fault)
        else if (emergency_trigger &&
                 current_state != EMERGENCY_YELLOW &&
                 current_state != EMERGENCY_RED    &&
                 current_state != EMERGENCY_GREEN  &&
                 current_state != BLINK_RED)
            next_state = EMERGENCY_YELLOW;

        else begin
            case (current_state)
                FAIL_SAFE:
                    next_state = NS_GREEN;

                NS_GREEN:
                    if (timer_done && tick_1hz) next_state = NS_YELLOW;
                    else if (ns_gapout)         next_state = NS_YELLOW;

                NS_YELLOW:
                    if (timer_done && tick_1hz) next_state = ALL_RED_A;

                ALL_RED_A:
                    if (timer_done && tick_1hz) next_state = EW_GREEN;

                EW_GREEN:
                    if (timer_done && tick_1hz) next_state = EW_YELLOW;
                    else if (ew_gapout)         next_state = EW_YELLOW;

                EW_YELLOW:
                    if (timer_done && tick_1hz) next_state = ALL_RED_B;

                ALL_RED_B:
                    if (timer_done && tick_1hz) next_state = NS_GREEN;

                // ── Emergency Sequence ────────────────────────────────────────
                // Force yellow → all-red → emergency green (N/S priority)
                EMERGENCY_YELLOW:
                    if (timer_done && tick_1hz) next_state = EMERGENCY_RED;

                EMERGENCY_RED:
                    if (timer_done && tick_1hz) next_state = EMERGENCY_GREEN;

                EMERGENCY_GREEN:
                    // Hold emergency green while trigger is still high
                    if (!emergency_trigger)     next_state = ALL_RED_A;

                // ── Fault State ───────────────────────────────────────────────
                // Latched — only reset can clear this
                BLINK_RED:
                    next_state = BLINK_RED;

                default:
                    next_state = FAIL_SAFE;
            endcase
        end
    end

    // ── Output Logic ──────────────────────────────────────────────────────────
    // Pedestrian walk = active during first PED_TIME seconds of green phase
    logic ns_ped_active, ew_ped_active;
    assign ns_ped_active = (current_state == NS_GREEN) && (timer < PED_TIME[3:0]);
    assign ew_ped_active = (current_state == EW_GREEN) && (timer < PED_TIME[3:0]);

    // N/S direction enable signals
    logic ns_is_green, ns_is_yellow, ns_is_red;
    assign ns_is_green  = (current_state == NS_GREEN) ||
                          (current_state == EMERGENCY_GREEN);
    assign ns_is_yellow = (current_state == NS_YELLOW) ||
                          (current_state == EMERGENCY_YELLOW);
    assign ns_is_red    = ~(ns_is_green | ns_is_yellow);

    // E/W direction enable signals
    logic ew_is_green, ew_is_yellow, ew_is_red;
    assign ew_is_green  = (current_state == EW_GREEN);
    assign ew_is_yellow = (current_state == EW_YELLOW);
    assign ew_is_red    = ~(ew_is_green | ew_is_yellow);

    // ── Normal signal outputs ─────────────────────────────────────────────────
    always_comb begin
        // Defaults — all red, no walk
        ns_str_green  = 1'b0; ns_str_yellow  = 1'b0; ns_str_red  = 1'b1;
        ns_left_green = 1'b0; ns_left_yellow = 1'b0; ns_left_red = 1'b1;
        ns_ped_walk   = 1'b0;
        ew_str_green  = 1'b0; ew_str_yellow  = 1'b0; ew_str_red  = 1'b1;
        ew_left_green = 1'b0; ew_left_yellow = 1'b0; ew_left_red = 1'b1;
        ew_ped_walk   = 1'b0;

        case (current_state)
            // ── Normal N/S Green ─────────────────────────────────────────────
            NS_GREEN: begin
                ns_str_green  = 1'b1; ns_str_red  = 1'b0;
                ns_left_green = 1'b1; ns_left_red = 1'b0;
                ns_ped_walk   = ns_ped_active;
                ew_str_red    = 1'b1;
                ew_left_red   = 1'b1;
            end

            // ── Normal N/S Yellow ────────────────────────────────────────────
            NS_YELLOW: begin
                ns_str_yellow  = 1'b1; ns_str_red  = 1'b0;
                ns_left_yellow = 1'b1; ns_left_red = 1'b0;
                ew_str_red     = 1'b1;
                ew_left_red    = 1'b1;
            end

            // ── All-Red Buffer A ─────────────────────────────────────────────
            ALL_RED_A: begin
                // Everything red — defaults handle this
            end

            // ── Normal E/W Green ─────────────────────────────────────────────
            EW_GREEN: begin
                ew_str_green  = 1'b1; ew_str_red  = 1'b0;
                ew_left_green = 1'b1; ew_left_red = 1'b0;
                ew_ped_walk   = ew_ped_active;
                ns_str_red    = 1'b1;
                ns_left_red   = 1'b1;
            end

            // ── Normal E/W Yellow ────────────────────────────────────────────
            EW_YELLOW: begin
                ew_str_yellow  = 1'b1; ew_str_red  = 1'b0;
                ew_left_yellow = 1'b1; ew_left_red = 1'b0;
                ns_str_red     = 1'b1;
                ns_left_red    = 1'b1;
            end

            // ── All-Red Buffer B ─────────────────────────────────────────────
            ALL_RED_B: begin
                // Everything red — defaults handle this
            end

            // ── Emergency Yellow (current green → yellow) ────────────────────
            EMERGENCY_YELLOW: begin
                // Both directions → yellow (safest transition)
                ns_str_yellow  = 1'b1; ns_str_red  = 1'b0;
                ns_left_yellow = 1'b1; ns_left_red = 1'b0;
                ew_str_yellow  = 1'b1; ew_str_red  = 1'b0;
                ew_left_yellow = 1'b1; ew_left_red = 1'b0;
            end

            // ── Emergency All-Red ─────────────────────────────────────────────
            EMERGENCY_RED: begin
                // Everything red — defaults handle this
            end

            // ── Emergency Green (N/S priority) ───────────────────────────────
            EMERGENCY_GREEN: begin
                ns_str_green  = 1'b1; ns_str_red  = 1'b0;
                ns_left_green = 1'b1; ns_left_red = 1'b0;
                ew_str_red    = 1'b1;
                ew_left_red   = 1'b1;
            end

            // ── Blink Red (Fault State) ───────────────────────────────────────
            // All outputs blink red in sync with 2Hz toggle
            BLINK_RED: begin
                ns_str_red    = blink_tog;
                ns_left_red   = blink_tog;
                ew_str_red    = blink_tog;
                ew_left_red   = blink_tog;
            end

            // ── Fail Safe / Default ───────────────────────────────────────────
            default: begin
                // All red — defaults handle this
            end
        endcase
    end

endmodule
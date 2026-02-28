// =============================================================================
// traffic_fsm.sv — FIXED VERSION
// =============================================================================
module traffic_fsm #(
    parameter GREEN_TIME  = 9,
    parameter YELLOW_TIME = 5,
    parameter PED_TIME    = 4,
    parameter GAPOUT_TIME = 3,
    parameter ALLRED_TIME = 2,
    parameter EMERG_TIME  = 2
)(
    input  logic clk,
    input  logic rst_n,
    input  logic tick_1hz,
    input  logic tick_2hz,
    input  logic ns_sensor,
    input  logic ew_sensor,
    input  logic emergency_trigger,
    input  logic system_fault,

    output logic ns_str_green,  ns_str_yellow,  ns_str_red,
    output logic ns_left_green, ns_left_yellow, ns_left_red,
    output logic ns_ped_walk,
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

    // ── FIX 1: Latched fault register ────────────────────────────────────────
    // Once fault is detected, latch it so BLINK_RED cannot escape
    // Only rst_n=0 can clear this latch
    logic fault_latched;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            fault_latched <= 1'b0;
        else if (system_fault)
            fault_latched <= 1'b1;
        // Once set, never clears until reset
    end

    // ── Timer ─────────────────────────────────────────────────────────────────
    logic [3:0] timer;
    logic       timer_done;
    logic [3:0] phase_duration;

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

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            timer <= 4'd0;
        else if (current_state != next_state)
            timer <= 4'd0;
        else if (tick_1hz && !timer_done)
            timer <= timer + 1'b1;
    end

    // ── Gap-Out ───────────────────────────────────────────────────────────────
    logic ns_gapout, ew_gapout;
    assign ns_gapout = (current_state == NS_GREEN) &&
                       (!ns_sensor) &&
                       (timer >= GAPOUT_TIME[3:0]);
    assign ew_gapout = (current_state == EW_GREEN) &&
                       (!ew_sensor) &&
                       (timer >= GAPOUT_TIME[3:0]);

    // ── Blink Toggle ──────────────────────────────────────────────────────────
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

    // ── FIX 2: FSM Next-State Logic ───────────────────────────────────────────
    always_comb begin
        next_state = current_state;

        // fault_latched overrides everything — only reset clears it
        if (fault_latched)
            next_state = BLINK_RED;

        // Emergency overrides normal flow
        else if (emergency_trigger &&
                 current_state != EMERGENCY_YELLOW &&
                 current_state != EMERGENCY_RED    &&
                 current_state != EMERGENCY_GREEN  &&
                 current_state != BLINK_RED)
            next_state = EMERGENCY_YELLOW;

        else begin
            case (current_state)

                // FIX: Wait here until rst_n is HIGH
                // This prevents instant FAIL_SAFE → NS_GREEN loop
                FAIL_SAFE:
                    if (rst_n) next_state = NS_GREEN;

                NS_GREEN:
                    if (ns_gapout)
                        next_state = NS_YELLOW;
                    else if (timer_done && tick_1hz)
                        next_state = NS_YELLOW;

                NS_YELLOW:
                    if (timer_done && tick_1hz) next_state = ALL_RED_A;

                ALL_RED_A:
                    if (timer_done && tick_1hz) next_state = EW_GREEN;

                EW_GREEN:
                    if (ew_gapout)
                        next_state = EW_YELLOW;
                    else if (timer_done && tick_1hz)
                        next_state = EW_YELLOW;

                EW_YELLOW:
                    if (timer_done && tick_1hz) next_state = ALL_RED_B;

                ALL_RED_B:
                    if (timer_done && tick_1hz) next_state = NS_GREEN;

                EMERGENCY_YELLOW:
                    if (timer_done && tick_1hz) next_state = EMERGENCY_RED;

                EMERGENCY_RED:
                    if (timer_done && tick_1hz) next_state = EMERGENCY_GREEN;

                EMERGENCY_GREEN:
                    if (!emergency_trigger) next_state = ALL_RED_A;

                // FIX: BLINK_RED is now truly latched via fault_latched
                // This state is held by the fault_latched check above
                // so no explicit hold needed here
                BLINK_RED:
                    next_state = BLINK_RED;

                default:
                    next_state = FAIL_SAFE;

            endcase
        end
    end

    // ── Output Logic ──────────────────────────────────────────────────────────
    logic ns_ped_active, ew_ped_active;
    assign ns_ped_active = (current_state == NS_GREEN) && (timer < PED_TIME[3:0]);
    assign ew_ped_active = (current_state == EW_GREEN) && (timer < PED_TIME[3:0]);

    always_comb begin
        // Safe defaults — everything red
        ns_str_green  = 1'b0; ns_str_yellow  = 1'b0; ns_str_red  = 1'b1;
        ns_left_green = 1'b0; ns_left_yellow = 1'b0; ns_left_red = 1'b1;
        ns_ped_walk   = 1'b0;
        ew_str_green  = 1'b0; ew_str_yellow  = 1'b0; ew_str_red  = 1'b1;
        ew_left_green = 1'b0; ew_left_yellow = 1'b0; ew_left_red = 1'b1;
        ew_ped_walk   = 1'b0;

        case (current_state)
            NS_GREEN: begin
                ns_str_green  = 1'b1; ns_str_red  = 1'b0;
                ns_left_green = 1'b1; ns_left_red = 1'b0;
                ns_ped_walk   = ns_ped_active;
            end

            NS_YELLOW: begin
                ns_str_yellow  = 1'b1; ns_str_red  = 1'b0;
                ns_left_yellow = 1'b1; ns_left_red = 1'b0;
            end

            ALL_RED_A: begin
                // All red — defaults handle this
            end

            EW_GREEN: begin
                ew_str_green  = 1'b1; ew_str_red  = 1'b0;
                ew_left_green = 1'b1; ew_left_red = 1'b0;
                ew_ped_walk   = ew_ped_active;
            end

            EW_YELLOW: begin
                ew_str_yellow  = 1'b1; ew_str_red  = 1'b0;
                ew_left_yellow = 1'b1; ew_left_red = 1'b0;
            end

            ALL_RED_B: begin
                // All red — defaults handle this
            end

            EMERGENCY_YELLOW: begin
                ns_str_yellow  = 1'b1; ns_str_red  = 1'b0;
                ns_left_yellow = 1'b1; ns_left_red = 1'b0;
                ew_str_yellow  = 1'b1; ew_str_red  = 1'b0;
                ew_left_yellow = 1'b1; ew_left_red = 1'b0;
            end

            EMERGENCY_RED: begin
                // All red — defaults handle this
            end

            EMERGENCY_GREEN: begin
                ns_str_green  = 1'b1; ns_str_red  = 1'b0;
                ns_left_green = 1'b1; ns_left_red = 1'b0;
            end

            BLINK_RED: begin
                ns_str_red  = blink_tog;
                ns_left_red = blink_tog;
                ew_str_red  = blink_tog;
                ew_left_red = blink_tog;
            end

            default: begin
                // All red — defaults handle this
            end
        endcase
    end

endmodule
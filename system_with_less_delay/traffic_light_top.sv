// =============================================================================
// traffic_light_top.sv — Top-Level Pin Wrapper
// Target  : EP4CE6E22C8 (Cyclone IV E, PQFP144)
// Clock   : PIN_23 @ 50MHz
// Reset   : PIN_24 (Active LOW)
// =============================================================================
module traffic_light_top (
    input  logic clk,       // PIN_23
    input  logic rst_n,     // PIN_24  (active LOW)

    // ── Emergency & Sensor inputs (assign to spare pins as needed) ────────────
    input  logic ns_sensor,          // Vehicle detector — N/S loop
    input  logic ew_sensor,          // Vehicle detector — E/W loop
    input  logic emergency_trigger,  // Emergency vehicle preemption

    // ── North Straight ────────────────────────────────────────────────────────
    output logic led_N_G,  led_N_Y,  led_N_R,

    // ── East Straight ─────────────────────────────────────────────────────────
    output logic led_E_G,  led_E_Y,  led_E_R,

    // ── South Straight ────────────────────────────────────────────────────────
    output logic led_S_G,  led_S_Y,  led_S_R,

    // ── West Straight ─────────────────────────────────────────────────────────
    output logic led_W_G,  led_W_Y,  led_W_R,

    // ── North Left Turn ───────────────────────────────────────────────────────
    output logic led_NL_G, led_NL_Y, led_NL_R,

    // ── South Left Turn ───────────────────────────────────────────────────────
    output logic led_SL_G, led_SL_Y, led_SL_R,

    // ── East Left Turn ────────────────────────────────────────────────────────
    output logic led_EL_G, led_EL_Y, led_EL_R,

    // ── West Left Turn ────────────────────────────────────────────────────────
    output logic led_WL_G, led_WL_Y, led_WL_R,

    // ── System Fault LED (assign to a spare output pin) ───────────────────────
    output logic system_fault_led
);

    // ── Internal Wires ────────────────────────────────────────────────────────
    logic tick_1hz, tick_2hz;
    logic system_fault;

    // FSM raw outputs (before fan-out to N/S/E/W separately)
    logic ns_str_green,  ns_str_yellow,  ns_str_red;
    logic ns_left_green, ns_left_yellow, ns_left_red;
    logic ns_ped_walk;

    logic ew_str_green,  ew_str_yellow,  ew_str_red;
    logic ew_left_green, ew_left_yellow, ew_left_red;
    logic ew_ped_walk;

    // ── Clock Divider ─────────────────────────────────────────────────────────
    clk_div #(
        .CLK_FREQ(50_000_000)
    ) u_clk_div (
        .clk      (clk),
        .rst_n    (rst_n),
        .tick_1hz (tick_1hz),
        .tick_2hz (tick_2hz)
    );

    // ── Conflict Monitor ──────────────────────────────────────────────────────
    conflict_monitor u_monitor (
        .ns_str_green  (ns_str_green),
        .ew_str_green  (ew_str_green),
        .ns_left_green (ns_left_green),
        .ew_left_green (ew_left_green),
        .ns_ped        (ns_ped_walk),
        .ew_ped        (ew_ped_walk),
        .system_fault  (system_fault)
    );

    // ── Main FSM ──────────────────────────────────────────────────────────────
    traffic_fsm #(
        .GREEN_TIME  (9),
        .YELLOW_TIME (5),
        .PED_TIME    (4),
        .GAPOUT_TIME (3),
        .ALLRED_TIME (2),
        .EMERG_TIME  (2)
    ) u_fsm (
        .clk              (clk),
        .rst_n            (rst_n),
        .tick_1hz         (tick_1hz),
        .tick_2hz         (tick_2hz),
        .ns_sensor        (ns_sensor),
        .ew_sensor        (ew_sensor),
        .emergency_trigger(emergency_trigger),
        .system_fault     (system_fault),

        .ns_str_green     (ns_str_green),
        .ns_str_yellow    (ns_str_yellow),
        .ns_str_red       (ns_str_red),
        .ns_left_green    (ns_left_green),
        .ns_left_yellow   (ns_left_yellow),
        .ns_left_red      (ns_left_red),
        .ns_ped_walk      (ns_ped_walk),

        .ew_str_green     (ew_str_green),
        .ew_str_yellow    (ew_str_yellow),
        .ew_str_red       (ew_str_red),
        .ew_left_green    (ew_left_green),
        .ew_left_yellow   (ew_left_yellow),
        .ew_left_red      (ew_left_red),
        .ew_ped_walk      (ew_ped_walk)
    );

    // ── Fan-Out: FSM signals → Individual named LED outputs ───────────────────
    // North and South share N/S FSM ring
    // East and West share E/W FSM ring

    // North Straight
    assign led_N_G = ns_str_green;
    assign led_N_Y = ns_str_yellow;
    assign led_N_R = ns_str_red;

    // South Straight
    assign led_S_G = ns_str_green;
    assign led_S_Y = ns_str_yellow;
    assign led_S_R = ns_str_red;

    // East Straight
    assign led_E_G = ew_str_green;
    assign led_E_Y = ew_str_yellow;
    assign led_E_R = ew_str_red;

    // West Straight
    assign led_W_G = ew_str_green;
    assign led_W_Y = ew_str_yellow;
    assign led_W_R = ew_str_red;

    // North Left
    assign led_NL_G = ns_left_green;
    assign led_NL_Y = ns_left_yellow;
    assign led_NL_R = ns_left_red;

    // South Left
    assign led_SL_G = ns_left_green;
    assign led_SL_Y = ns_left_yellow;
    assign led_SL_R = ns_left_red;

    // East Left
    assign led_EL_G = ew_left_green;
    assign led_EL_Y = ew_left_yellow;
    assign led_EL_R = ew_left_red;

    // West Left
    assign led_WL_G = ew_left_green;
    assign led_WL_Y = ew_left_yellow;
    assign led_WL_R = ew_left_red;

    // System Fault LED
    assign system_fault_led = system_fault;

endmodule
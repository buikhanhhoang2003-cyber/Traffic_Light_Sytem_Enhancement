// =============================================================================
// traffic_light_top.sv
// Updated for 8-state FSM (active left turns on both axes)
// Axis A = North/South | Axis B = East/West
// =============================================================================
module traffic_light_top (
    input  logic clk,
    input  logic rst_n,

    // North Straight: PIN_28, PIN_31, PIN_33
    output logic led_N_G,
    output logic led_N_Y,
    output logic led_N_R,

    // South Straight: PIN_44, PIN_49, PIN_51
    output logic led_S_G,
    output logic led_S_Y,
    output logic led_S_R,

    // East Straight: PIN_55, PIN_59, PIN_64
    output logic led_E_G,
    output logic led_E_Y,
    output logic led_E_R,

    // West Straight: PIN_68, PIN_70, PIN_72
    output logic led_W_G,
    output logic led_W_Y,
    output logic led_W_R,

    // North Left: PIN_30, PIN_32, PIN_34
    output logic led_NL_G,
    output logic led_NL_Y,
    output logic led_NL_R,

    // South Left: PIN_46, PIN_50, PIN_52
    output logic led_SL_G,
    output logic led_SL_Y,
    output logic led_SL_R,

    // East Left: PIN_58, PIN_65, PIN_60
    output logic led_EL_G,
    output logic led_EL_Y,
    output logic led_EL_R,

    // West Left: PIN_69, PIN_71, PIN_73
    output logic led_WL_G,
    output logic led_WL_Y,
    output logic led_WL_R,

    // Pedestrian: PIN_84, PIN_85, PIN_86, PIN_87
    output logic ped_N,
    output logic ped_S,
    output logic ped_E,
    output logic ped_W,

    // Fault LED: PIN_144
    output logic system_fault_led
);

    // Internal wires
    logic tick_1hz, tick_2hz;
    logic system_fault;

    // Axis A (N/S)
    logic a_str_green,  a_str_yellow,  a_str_red;
    logic a_left_green, a_left_yellow, a_left_red;
    logic a_ped_walk;

    // Axis B (E/W)
    logic b_str_green,  b_str_yellow,  b_str_red;
    logic b_left_green, b_left_yellow, b_left_red;
    logic b_ped_walk;

    // Clock Divider
    clk_div #(
        .CLK_FREQ(50_000_000)
    ) u_clk_div (
        .clk     (clk),
        .rst_n   (rst_n),
        .tick_1hz(tick_1hz),
        .tick_2hz(tick_2hz)
    );

    // Conflict Monitor
    conflict_monitor u_monitor (
        .a_str_green (a_str_green),
        .a_left_green(a_left_green),
        .a_ped_walk  (a_ped_walk),
        .b_str_green (b_str_green),
        .b_left_green(b_left_green),
        .b_ped_walk  (b_ped_walk),
        .system_fault(system_fault)
    );

    // FSM
    traffic_fsm #(
        .A_STR_TIME (4),
        .A_SYEL_TIME(3),
        .A_LFT_TIME (4),
        .A_LYEL_TIME(3),
        .B_STR_TIME (4),
        .B_SYEL_TIME(3),
        .B_LFT_TIME (4),
        .B_LYEL_TIME(3),
        .ALLRED_TIME(2)
    ) u_fsm (
        .clk          (clk),
        .rst_n        (rst_n),
        .tick_1hz     (tick_1hz),
        .tick_2hz     (tick_2hz),
        .system_fault (system_fault),

        .a_str_green  (a_str_green),
        .a_str_yellow (a_str_yellow),
        .a_str_red    (a_str_red),
        .a_left_green (a_left_green),
        .a_left_yellow(a_left_yellow),
        .a_left_red   (a_left_red),
        .a_ped_walk   (a_ped_walk),

        .b_str_green  (b_str_green),
        .b_str_yellow (b_str_yellow),
        .b_str_red    (b_str_red),
        .b_left_green (b_left_green),
        .b_left_yellow(b_left_yellow),
        .b_left_red   (b_left_red),
        .b_ped_walk   (b_ped_walk)
    );

    // Fan-out: FSM signals -> LED pins

    // North Straight
    assign led_N_G = a_str_green;
    assign led_N_Y = a_str_yellow;
    assign led_N_R = a_str_red;

    // South Straight
    assign led_S_G = a_str_green;
    assign led_S_Y = a_str_yellow;
    assign led_S_R = a_str_red;

    // East Straight
    assign led_E_G = b_str_green;
    assign led_E_Y = b_str_yellow;
    assign led_E_R = b_str_red;

    // West Straight
    assign led_W_G = b_str_green;
    assign led_W_Y = b_str_yellow;
    assign led_W_R = b_str_red;

    // North Left
    assign led_NL_G = a_left_green;
    assign led_NL_Y = a_left_yellow;
    assign led_NL_R = a_left_red;

    // South Left
    assign led_SL_G = a_left_green;
    assign led_SL_Y = a_left_yellow;
    assign led_SL_R = a_left_red;

    // East Left
    assign led_EL_G = b_left_green;
    assign led_EL_Y = b_left_yellow;
    assign led_EL_R = b_left_red;

    // West Left
    assign led_WL_G = b_left_green;
    assign led_WL_Y = b_left_yellow;
    assign led_WL_R = b_left_red;

    // Pedestrian LEDs (active-low)
    assign ped_N = a_str_green;
    assign ped_S = a_str_green;
    assign ped_E = b_str_green;
    assign ped_W = b_str_green;

    // System Fault LED
    assign system_fault_led = system_fault;

endmodule
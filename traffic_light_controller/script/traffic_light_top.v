// =============================================================================
// traffic_light_top.v
// 4-Way Dual-Ring Traffic Light Controller
// Axis A = North/South | Axis B = East/West
// =============================================================================
module traffic_light_top (
    input  wire clk,
    input  wire rst_n,

    // North Straight: PIN_28, PIN_31, PIN_33
    output wire led_N_G,
    output wire led_N_Y,
    output wire led_N_R,

    // South Straight: PIN_44, PIN_49, PIN_51
    output wire led_S_G,
    output wire led_S_Y,
    output wire led_S_R,

    // East Straight: PIN_55, PIN_59, PIN_64
    output wire led_E_G,
    output wire led_E_Y,
    output wire led_E_R,

    // West Straight: PIN_68, PIN_70, PIN_72
    output wire led_W_G,
    output wire led_W_Y,
    output wire led_W_R,

    // North Left: PIN_30, PIN_32, PIN_34
    output wire led_NL_G,
    output wire led_NL_Y,
    output wire led_NL_R,

    // South Left: PIN_46, PIN_50, PIN_52
    output wire led_SL_G,
    output wire led_SL_Y,
    output wire led_SL_R,

    // East Left: PIN_58, PIN_65, PIN_60
    output wire led_EL_G,
    output wire led_EL_Y,
    output wire led_EL_R,

    // West Left: PIN_69, PIN_71, PIN_73
    output wire led_WL_G,
    output wire led_WL_Y,
    output wire led_WL_R,

    // Pedestrian: PIN_84, PIN_85, PIN_86, PIN_87
    output wire ped_N,
    output wire ped_S,
    output wire ped_E,
    output wire ped_W,

    // Fault LED: PIN_144
    output wire system_fault_led
);

    // Internal wires
    wire tick_1hz, tick_2hz;
    wire system_fault;

    // Axis A (N/S)
    wire a_str_green,  a_str_yellow,  a_str_red;
    wire a_left_green, a_left_yellow, a_left_red;
    wire a_ped_walk;

    // Axis B (E/W)
    wire b_str_green,  b_str_yellow,  b_str_red;
    wire b_left_green, b_left_yellow, b_left_red;
    wire b_ped_walk;

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

    // ── Fan-out: FSM signals -> LED pins ─────────────────────────────────────

    // North / South Straight (share Axis A straight)
    assign led_N_G = a_str_green;   assign led_N_Y = a_str_yellow;  assign led_N_R = a_str_red;
    assign led_S_G = a_str_green;   assign led_S_Y = a_str_yellow;  assign led_S_R = a_str_red;

    // East / West Straight (share Axis B straight)
    assign led_E_G = b_str_green;   assign led_E_Y = b_str_yellow;  assign led_E_R = b_str_red;
    assign led_W_G = b_str_green;   assign led_W_Y = b_str_yellow;  assign led_W_R = b_str_red;

    // North / South Left (share Axis A left)
    assign led_NL_G = a_left_green; assign led_NL_Y = a_left_yellow; assign led_NL_R = a_left_red;
    assign led_SL_G = a_left_green; assign led_SL_Y = a_left_yellow; assign led_SL_R = a_left_red;

    // East / West Left (share Axis B left)
    assign led_EL_G = b_left_green; assign led_EL_Y = b_left_yellow; assign led_EL_R = b_left_red;
    assign led_WL_G = b_left_green; assign led_WL_Y = b_left_yellow; assign led_WL_R = b_left_red;

    // Pedestrian LEDs
    assign ped_N = a_ped_walk;
    assign ped_S = a_ped_walk;
    assign ped_E = b_ped_walk;
    assign ped_W = b_ped_walk;

    // System Fault LED
    assign system_fault_led = system_fault;

endmodule
// Traffic Light System Interface Module
// Integrates all subsystems for a complete traffic light

module traffic_system_interface #(
    parameter CLK_FREQ = 50_000_000,    // 50 MHz clock
    parameter RED_DURATION = 30,        // Red light duration (seconds)
    parameter GREEN_DURATION = 25,      // Green light duration (seconds)
    parameter YELLOW_DURATION = 5       // Yellow light duration (seconds)
) (
    input clk,
    input rst_n,
    input pedestrian_request,
    input enable,
    
    // Traffic light outputs
    output red_light,
    output yellow_light,
    output green_light,
    
    // 7-segment display outputs
    output [6:0] seg_a,    // Segment A (top)
    output [6:0] seg_b,    // Segment B (upper right)
    output [1:0] digit_sel,
    
    // Status outputs
    output [1:0] current_state,
    output [7:0] remaining_time
);

    // Internal signals
    wire [6:0] seg_ones_internal;
    wire [6:0] seg_tens_internal;
    wire [7:0] state_display;
    
    // Instantiate traffic light controller
    traffic_light_controller #(
        .RED_DURATION(RED_DURATION),
        .GREEN_DURATION(GREEN_DURATION),
        .YELLOW_DURATION(YELLOW_DURATION)
    ) traffic_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .pedestrian_request(pedestrian_request),
        .red(red_light),
        .yellow(yellow_light),
        .green(green_light),
        .seven_seg_ones(seg_ones_internal),
        .seven_seg_tens(seg_tens_internal),
        .current_state(state_display)
    );

    // Instantiate 7-segment driver with multiplexing
    seven_segment_driver #(
        .REFRESH_RATE(1000)
    ) seg_driver (
        .clk(clk),
        .rst_n(rst_n),
        .seg_ones(seg_ones_internal),
        .seg_tens(seg_tens_internal),
        .mode(2'b00),  // Common cathode
        .segments(seg_a),
        .digit_sel(digit_sel)
    );

    // Output assignments
    assign seg_b = seg_a;  // For dual 7-segment display
    assign current_state = state_display[1:0];
    assign remaining_time = state_display;

endmodule

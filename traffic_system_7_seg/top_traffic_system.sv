// Top-Level Traffic Light System Module
// Main instantiation point for the complete traffic light system

module top_traffic_system #(
    parameter CLK_FREQ = 50_000_000,
    parameter RED_DUR = 30,
    parameter GREEN_DUR = 25,
    parameter YELLOW_DUR = 5
) (
    // Clock and Reset
    input clk,
    input rst_n,
    
    // Input Controls
    input [1:0] mode,               // 00: Normal, 01: Manual, 10: Emergency
    input pedestrian_push,          // Pedestrian crossing request
    input [1:0] manual_state_sel,   // Manual state selection
    
    // Traffic Light Outputs (Active High)
    output red,
    output yellow,
    output green,
    
    // 7-Segment Display Outputs
    output [6:0] seg_ones,          // Units digit 7-segment
    output [6:0] seg_tens,          // Tens digit 7-segment
    output [1:0] digit_select,      // Multiplex digit selection
    
    // Pedestrian Signal
    output pedestrian_go,           // Pedestrian crossing allowed
    
    // Status outputs
    output [1:0] traffic_state,     // 00:RED, 01:GREEN, 10:YELLOW
    output system_ready             // System initialization complete
);

    // Internal signals
    wire system_enable;
    wire pedestrian_req_sync;
    wire [7:0] remaining_seconds;
    
    // Synchronize asynchronous inputs
    reg [1:0] ped_sync_ff;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ped_sync_ff <= 2'b00;
        end else begin
            ped_sync_ff <= {ped_sync_ff[0], pedestrian_push};
        end
    end
    assign pedestrian_req_sync = ped_sync_ff[1];

    // System enable logic
    assign system_enable = (mode == 2'b00);  // Enable in normal mode

    // Main traffic light system instantiation
    traffic_light_controller #(
        .RED_DURATION(RED_DUR),
        .GREEN_DURATION(GREEN_DUR),
        .YELLOW_DURATION(YELLOW_DUR)
    ) main_controller (
        .clk(clk),
        .rst_n(rst_n & system_enable),
        .pedestrian_request(pedestrian_req_sync),
        .red(red),
        .yellow(yellow),
        .green(green),
        .seven_seg_ones(seg_ones),
        .seven_seg_tens(seg_tens),
        .current_state(traffic_state)
    );

    // 7-Segment driver for multiplexed display
    seven_segment_driver #(
        .REFRESH_RATE(1000)
    ) seg_mux (
        .clk(clk),
        .rst_n(rst_n),
        .seg_ones(seg_ones),
        .seg_tens(seg_tens),
        .mode(2'b00),
        .segments(),
        .digit_sel(digit_select)
    );

    // Pedestrian crossing logic
    assign pedestrian_go = green & pedestrian_req_sync;

    // System ready signal (indicates initialization complete)
    assign system_ready = 1'b1;  // Always ready in this implementation

endmodule

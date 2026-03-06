// Multi-Lane Traffic Intersection Controller
// Manages traffic lights for a complete 4-way intersection

module multi_lane_intersection #(
    parameter RED_DUR = 30,
    parameter GREEN_DUR = 25,
    parameter YELLOW_DUR = 5
) (
    input clk,
    input rst_n,
    
    // Pedestrian request buttons (4 corners)
    input ped_request_n,
    input ped_request_s,
    input ped_request_e,
    input ped_request_w,
    
    // Traffic volume sensors (North, South, East, West)
    input [7:0] traffic_n,
    input [7:0] traffic_s,
    input [7:0] traffic_e,
    input [7:0] traffic_w,
    
    // North-South Traffic Light Outputs
    output ns_red,
    output ns_yellow,
    output ns_green,
    
    // East-West Traffic Light Outputs
    output ew_red,
    output ew_yellow,
    output ew_green,
    
    // 7-Segment Display Outputs
    output [6:0] seg_ones,
    output [6:0] seg_tens,
    output [1:0] digit_select,
    
    // Pedestrian Walk Signals
    output ped_walk_ns,
    output ped_walk_ew,
    output ped_walk_led,
    
    // Status outputs
    output [7:0] system_status
);

    // State definitions
    localparam NS_GREEN_PHASE = 2'b00;
    localparam NS_YELLOW_PHASE = 2'b01;
    localparam EW_GREEN_PHASE = 2'b10;
    localparam EW_YELLOW_PHASE = 2'b11;

    // Internal signals
    reg [1:0] intersection_state, next_state;
    reg [31:0] phase_counter;
    reg [31:0] phase_duration;
    wire [7:0] remaining_time;
    reg [6:0] seg_ones_val, seg_tens_val;
    wire ped_countdown_ns, ped_countdown_ew;

    // North-South Phase Controller
    traffic_light_controller #(
        .RED_DURATION(RED_DUR),
        .GREEN_DURATION(GREEN_DUR),
        .YELLOW_DURATION(YELLOW_DUR)
    ) ns_controller (
        .clk(clk),
        .rst_n(rst_n),
        .pedestrian_request(ped_request_n | ped_request_s),
        .red(ns_red),
        .yellow(ns_yellow),
        .green(ns_green),
        .seven_seg_ones(seg_ones_val),
        .seven_seg_tens(seg_tens_val),
        .current_state()
    );

    // East-West Phase Controller
    traffic_light_controller #(
        .RED_DURATION(RED_DUR),
        .GREEN_DURATION(GREEN_DUR),
        .YELLOW_DURATION(YELLOW_DUR)
    ) ew_controller (
        .clk(clk),
        .rst_n(rst_n),
        .pedestrian_request(ped_request_e | ped_request_w),
        .red(ew_red),
        .yellow(ew_yellow),
        .green(ew_green),
        .seven_seg_ones(),
        .seven_seg_tens(),
        .current_state()
    );

    // 7-Segment Driver
    seven_segment_driver #(
        .REFRESH_RATE(1000)
    ) seg_driver (
        .clk(clk),
        .rst_n(rst_n),
        .seg_ones(seg_ones_val),
        .seg_tens(seg_tens_val),
        .mode(2'b00),
        .segments(seg_ones),
        .digit_sel(digit_select)
    );

    // Pedestrian Crossing Controller
    pedestrian_crossing_controller ped_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .pedestrian_request_north(ped_request_n),
        .pedestrian_request_south(ped_request_s),
        .pedestrian_request_east(ped_request_e),
        .pedestrian_request_west(ped_request_w),
        .ns_traffic_state({1'b0, ns_green}),
        .ew_traffic_state({1'b0, ew_green}),
        .pedestrian_walk_ns(ped_walk_ns),
        .pedestrian_walk_ew(ped_walk_ew),
        .walk_signal_led(ped_walk_led),
        .pedestrian_countdown()
    );

    // Duplicate seven_seg_tens for output
    assign seg_tens = seg_ones;

    // System status encoding
    assign system_status = {
        ped_walk_led,
        ns_yellow, ns_green, ns_red,
        ew_yellow, ew_green, ew_red,
        intersection_state[0]
    };

endmodule

// Emergency Vehicle Override Controller
module emergency_override #(
    parameter CLK_FREQ = 50_000_000
) (
    input clk,
    input rst_n,
    input emergency_signal,
    input [1:0] emergency_direction,  // 00: NS, 01: EW, 10: Both
    
    // Traffic light inputs
    input ns_red,
    input ns_green,
    input ew_red,
    input ew_green,
    
    // Traffic light outputs with override
    output reg ns_red_out,
    output reg ns_green_out,
    output reg ew_red_out,
    output reg ew_green_out,
    
    // Status output
    output reg emergency_active
);

    reg [31:0] emergency_countdown;
    localparam EMERGENCY_DURATION = 30;  // 30 seconds

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            emergency_active <= 1'b0;
            emergency_countdown <= 0;
            ns_red_out <= ns_red;
            ns_green_out <= ns_green;
            ew_red_out <= ew_red;
            ew_green_out <= ew_green;
        end else begin
            if (emergency_signal) begin
                emergency_active <= 1'b1;
                emergency_countdown <= EMERGENCY_DURATION * CLK_FREQ;
                
                case (emergency_direction)
                    2'b00: begin  // NS priority
                        ns_red_out <= 1'b0;
                        ns_green_out <= 1'b1;
                        ew_red_out <= 1'b1;
                        ew_green_out <= 1'b0;
                    end
                    2'b01: begin  // EW priority
                        ns_red_out <= 1'b1;
                        ns_green_out <= 1'b0;
                        ew_red_out <= 1'b0;
                        ew_green_out <= 1'b1;
                    end
                    2'b10: begin  // Both green (all-way red first for safety)
                        ns_red_out <= 1'b0;
                        ns_green_out <= 1'b1;
                        ew_red_out <= 1'b0;
                        ew_green_out <= 1'b1;
                    end
                endcase
            end else if (emergency_countdown > 0) begin
                emergency_countdown <= emergency_countdown - 1;
            end else begin
                emergency_active <= 1'b0;
                ns_red_out <= ns_red;
                ns_green_out <= ns_green;
                ew_red_out <= ew_red;
                ew_green_out <= ew_green;
            end
        end
    end

endmodule

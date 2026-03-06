// Complete System Integration Example
// Shows how to integrate all modules together for a full traffic light system

module complete_traffic_system_example (
    // Clock and Reset
    input clk_100mhz,
    input rst_n,
    
    // Mode Control (from DIP switches)
    input [1:0] mode,
    
    // Pedestrian Request Buttons
    input pedestrian_north,
    input pedestrian_south,
    input pedestrian_east,
    input pedestrian_west,
    
    // Emergency Signal (for ambulance/fire truck)
    input emergency_vehicle,
    input [1:0] emergency_direction,
    
    // Traffic Sensors (optional - for adaptive control)
    input [7:0] traffic_sensor_ns,
    input [7:0] traffic_sensor_ew,
    
    // ==================== OUTPUTS ====================
    
    // North-South Traffic Lights
    output red_ns,
    output yellow_ns,
    output green_ns,
    
    // East-West Traffic Lights
    output red_ew,
    output yellow_ew,
    output green_ew,
    
    // 7-Segment Display Outputs (Traffic Light Countdown)
    output [6:0] seg_tens_display,
    output [6:0] seg_ones_display,
    output [1:0] digit_select,
    
    // Traffic Counter Display Outputs (Vehicle Count)
    output [6:0] counter_seg_thousands,
    output [6:0] counter_seg_hundreds,
    output [6:0] counter_seg_tens,
    output [6:0] counter_seg_ones,
    output [3:0] counter_digit_select,
    
    // Traffic Sensor Inputs
    input ns_vehicle_sensor,
    input ew_vehicle_sensor,
    input display_traffic_count,  // Switch to display vehicle counts
    
    // Pedestrian Walk Signals
    output pedestrian_walk_ns,
    output pedestrian_walk_ew,
    output pedestrian_walk_sign,
    
    // Status Indicators
    output system_ready,
    output [7:0] system_status,
    output [7:0] counter_status
);

    // ==================== INTERNAL SIGNALS ====================
    
    // Debounced inputs
    wire ped_n_clean, ped_s_clean, ped_e_clean, ped_w_clean;
    wire emergency_clean;
    
    // Edge detected signals
    wire ped_n_edge, ped_s_edge, ped_e_edge, ped_w_edge;
    wire emergency_edge;
    
    // Traffic light controller outputs
    wire ns_red_ctrl, ns_yellow_ctrl, ns_green_ctrl;
    wire ew_red_ctrl, ew_yellow_ctrl, ew_green_ctrl;
    wire [6:0] seg_ones_ctrl, seg_tens_ctrl;
    
    // Emergency override outputs
    wire ns_red_override, ns_yellow_override, ns_green_override;
    wire ew_red_override, ew_yellow_override, ew_green_override;
    wire emergency_active;
    
    // Pedestrian controller outputs
    wire ped_walk_ns_ctrl, ped_walk_ew_ctrl;
    wire ped_sign_ctrl;
    
    // Adaptive timing values
    wire [7:0] adj_red_dur, adj_green_dur, adj_yellow_dur;
    
    // ==================== CLOCK GENERATION ====================
    // Create 1MHz clock for timing
    wire clk_1mhz;
    freq_divider #(
        .DIVISOR(100),  // 100MHz / 100 = 1MHz
        .WIDTH(7)
    ) clk_divider (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .enable(1'b1),
        .clk_out(clk_1mhz)
    );
    
    // ==================== INPUT CONDITIONING ====================
    // Debounce all mechanical inputs (buttons)
    button_debouncer #(
        .DEBOUNCE_TIME(20),
        .CLK_FREQ(100_000_000)
    ) deb_ped_n (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .button_in(pedestrian_north),
        .button_out(ped_n_clean)
    );
    
    button_debouncer deb_ped_s (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .button_in(pedestrian_south),
        .button_out(ped_s_clean)
    );
    
    button_debouncer deb_ped_e (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .button_in(pedestrian_east),
        .button_out(ped_e_clean)
    );
    
    button_debouncer deb_ped_w (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .button_in(pedestrian_west),
        .button_out(ped_w_clean)
    );
    
    button_debouncer deb_emergency (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .button_in(emergency_vehicle),
        .button_out(emergency_clean)
    );
    
    // ==================== EDGE DETECTION ====================
    // Detect rising edges on button presses
    edge_detector_rising detect_ped_n (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .signal_in(ped_n_clean),
        .edge_detected(ped_n_edge)
    );
    
    edge_detector_rising detect_ped_s (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .signal_in(ped_s_clean),
        .edge_detected(ped_s_edge)
    );
    
    edge_detector_rising detect_ped_e (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .signal_in(ped_e_clean),
        .edge_detected(ped_e_edge)
    );
    
    edge_detector_rising detect_ped_w (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .signal_in(ped_w_clean),
        .edge_detected(ped_w_edge)
    );
    
    edge_detector_rising detect_emergency (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .signal_in(emergency_clean),
        .edge_detected(emergency_edge)
    );
    
    // ==================== ADAPTIVE TRAFFIC CONTROLLER ====================
    // Adjusts timing based on traffic volume
    adaptive_traffic_controller #(
        .BASE_RED_DUR(30),
        .BASE_GREEN_DUR(25),
        .BASE_YELLOW_DUR(5)
    ) adaptive_ctrl (
        .clk(clk_1mhz),
        .rst_n(rst_n),
        .traffic_volume((traffic_sensor_ns + traffic_sensor_ew) >> 1),
        .mode(mode),
        .adjusted_red_dur(adj_red_dur),
        .adjusted_green_dur(adj_green_dur),
        .adjusted_yellow_dur(adj_yellow_dur)
    );
    
    // ==================== PRIMARY TRAFFIC CONTROLLER ====================
    // Main traffic light FSM
    traffic_light_controller #(
        .RED_DURATION(30),
        .GREEN_DURATION(25),
        .YELLOW_DURATION(5)
    ) main_traffic_ctrl (
        .clk(clk_1mhz),
        .rst_n(rst_n & (mode == 2'b00)),  // Reset if not in normal mode
        .pedestrian_request(ped_n_edge | ped_s_edge),
        .red(ns_red_ctrl),
        .yellow(ns_yellow_ctrl),
        .green(ns_green_ctrl),
        .seven_seg_ones(seg_ones_ctrl),
        .seven_seg_tens(seg_tens_ctrl),
        .current_state()
    );
    
    // Pedestrian Crossing Controller
    pedestrian_crossing_controller ped_cross_ctrl (
        .clk(clk_1mhz),
        .rst_n(rst_n),
        .pedestrian_request_north(ped_n_edge),
        .pedestrian_request_south(ped_s_edge),
        .pedestrian_request_east(ped_e_edge),
        .pedestrian_request_west(ped_w_edge),
        .ns_traffic_state({1'b0, ns_green_ctrl}),
        .ew_traffic_state({1'b0, green_ew}),
        .pedestrian_walk_ns(ped_walk_ns_ctrl),
        .pedestrian_walk_ew(ped_walk_ew_ctrl),
        .walk_signal_led(ped_sign_ctrl),
        .pedestrian_countdown()
    );

    // ==================== TRAFFIC COUNTER CONTROL ====================
    // Dual-direction traffic counter with vehicle detection
    dual_direction_counter #(
        .MAX_COUNT(9999),
        .CLK_FREQ(1_000_000)
    ) traffic_counter_ctrl (
        .clk(clk_1mhz),
        .rst_n(rst_n),
        .ns_vehicle_sensor(ns_vehicle_sensor),
        .ns_counter_mode(2'b00),  // Always count in normal mode
        .ew_vehicle_sensor(ew_vehicle_sensor),
        .ew_counter_mode(2'b00),  // Always count in normal mode
        .display_select(display_traffic_count),  // Switch between NS/EW display
        .ns_count(),
        .ew_count(),
        .seg_thousands(counter_seg_thousands),
        .seg_hundreds(counter_seg_hundreds),
        .seg_tens(counter_seg_tens),
        .seg_ones(counter_seg_ones),
        .digit_select(counter_digit_select),
        .status(counter_status)
    );
    
    // ==================== EMERGENCY OVERRIDE ====================
    emergency_override #(
        .CLK_FREQ(1_000_000)  // 1MHz
    ) emergency_ctrl (
        .clk(clk_1mhz),
        .rst_n(rst_n),
        .emergency_signal(emergency_edge),
        .emergency_direction(emergency_direction),
        .ns_red(ns_red_ctrl),
        .ns_green(ns_green_ctrl),
        .ew_red(1'b1),  // EW is always red during emergency
        .ew_green(1'b0),
        .ns_red_out(ns_red_override),
        .ns_green_out(ns_green_override),
        .ew_red_out(ew_red_override),
        .ew_green_out(ew_green_override),
        .emergency_active(emergency_active)
    );
    
    // ==================== MULTIPLEXER - SELECT NORMAL OR OVERRIDE ====================
    assign red_ns = emergency_active ? ns_red_override : ns_red_ctrl;
    assign yellow_ns = ns_yellow_ctrl;  // Yellow from main controller
    assign green_ns = emergency_active ? ns_green_override : ns_green_ctrl;
    
    assign red_ew = emergency_active ? ew_red_override : ~(ped_walk_ew_ctrl | ped_sign_ctrl) ? 1'b1 : 1'b0;
    assign yellow_ew = 1'b0;  // Simplified - not used in this example
    assign green_ew = emergency_active ? ew_green_override : 1'b0;
    
    // ==================== 7-SEGMENT DISPLAY ====================
    seven_segment_driver #(
        .REFRESH_RATE(1000)
    ) seg_driver (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .seg_ones(seg_ones_ctrl),
        .seg_tens(seg_tens_ctrl),
        .mode(2'b00),  // Common cathode
        .segments(seg_ones_display),
        .digit_sel(digit_select)
    );
    
    assign seg_tens_display = seg_ones_display;  // Both same for demo
    
    // ==================== PEDESTRIAN SIGNALS ====================
    assign pedestrian_walk_ns = emergency_active ? 1'b0 : ped_walk_ns_ctrl;
    assign pedestrian_walk_ew = emergency_active ? 1'b0 : ped_walk_ew_ctrl;
    assign pedestrian_walk_sign = emergency_active ? 1'b0 : ped_sign_ctrl;
    
    // ==================== STATUS OUTPUTS ====================
    assign system_ready = 1'b1;  // Always ready in this implementation
    
    // Status byte composition
    // Bit 7: Emergency active
    // Bit 6: Pedestrian crossing active
    // Bit 5: Traffic sensor NS busy
    // Bit 4: Traffic sensor EW busy
    // Bit 3-2: Mode [1:0]
    // Bit 1-0: Traffic state [1:0]
    assign system_status = {
        emergency_active,
        (pedestrian_walk_ns | pedestrian_walk_ew),
        (traffic_sensor_ns > 128),
        (traffic_sensor_ew > 128),
        mode[1:0],
        ns_green_ctrl, ns_red_ctrl
    };

endmodule

// ==================== SIMULATION INSTANTIATION EXAMPLE ====================

/*
// Example: How to instantiate the complete system
module top_sim;
    
    // Signals
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg [1:0] mode = 2'b00;
    
    wire red_ns, yellow_ns, green_ns;
    wire red_ew, yellow_ew, green_ew;
    wire [6:0] seg_tens, seg_ones;
    
    // DUT instantiation
    complete_traffic_system_example dut (
        .clk_100mhz(clk),
        .rst_n(rst_n),
        .mode(mode),
        .pedestrian_north(1'b0),
        .pedestrian_south(1'b0),
        .pedestrian_east(1'b0),
        .pedestrian_west(1'b0),
        .emergency_vehicle(1'b0),
        .emergency_direction(2'b00),
        .traffic_sensor_ns(8'd128),
        .traffic_sensor_ew(8'd100),
        .red_ns(red_ns),
        .yellow_ns(yellow_ns),
        .green_ns(green_ns),
        .red_ew(red_ew),
        .yellow_ew(yellow_ew),
        .green_ew(green_ew),
        .seg_tens_display(seg_tens),
        .seg_ones_display(seg_ones),
        .digit_select(),
        .pedestrian_walk_ns(),
        .pedestrian_walk_ew(),
        .pedestrian_walk_sign(),
        .system_ready(),
        .system_status()
    );
    
    // Clock generation
    always #5 clk = ~clk;  // 100 MHz clock
    
    // Test stimulus
    initial begin
        rst_n = 1'b0;
        #20 rst_n = 1'b1;
        
        // Run simulation for 100 seconds
        #(100 * 1e9);
        $finish;
    end
    
    // Monitoring
    initial begin
        $dumpfile("traffic_light_sim.vcd");
        $dumpvars(0, top_sim);
        $monitor("Time=%0t NS:%b,%b,%b EW:%b,%b,%b SEG:%b,%b",
                 $time, red_ns, yellow_ns, green_ns,
                 red_ew, yellow_ew, green_ew, seg_tens, seg_ones);
    end
    
endmodule
*/

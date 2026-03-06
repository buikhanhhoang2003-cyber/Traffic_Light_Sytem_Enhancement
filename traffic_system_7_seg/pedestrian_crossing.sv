// Pedestrian Crossing Control Module
// Manages pedestrian crossings with priority and safety features

module pedestrian_crossing_controller (
    input clk,
    input rst_n,
    input pedestrian_request_north,
    input pedestrian_request_south,
    input pedestrian_request_east,
    input pedestrian_request_west,
    
    // Traffic light states (from main controller)
    input [1:0] ns_traffic_state,   // North-South traffic state
    input [1:0] ew_traffic_state,   // East-West traffic state
    
    // Pedestrian crossing signals
    output reg pedestrian_walk_ns,  // North-South pedestrian walk
    output reg pedestrian_walk_ew,  // East-West pedestrian walk
    output reg walk_signal_led,     // White walk signal LED (common)
    output reg [7:0] pedestrian_countdown
);

    // State definitions for traffic lights
    localparam RED_STATE = 2'b00;
    localparam GREEN_STATE = 2'b01;
    localparam YELLOW_STATE = 2'b10;

    // Pedestrian states
    localparam PED_IDLE = 2'b00;
    localparam PED_REQUESTING = 2'b01;
    localparam PED_WALKING = 2'b10;
    localparam PED_DONT_WALK = 2'b11;

    reg [1:0] ped_state_ns, ped_state_ew;
    reg [7:0] ped_countdown_ns, ped_countdown_ew;
    reg [7:0] walk_duration;
    reg ns_active, ew_active;

    // Pedestrian North-South Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ped_state_ns <= PED_IDLE;
            ped_countdown_ns <= 0;
            pedestrian_walk_ns <= 1'b0;
        end else begin
            case (ped_state_ns)
                PED_IDLE: begin
                    pedestrian_walk_ns <= 1'b0;
                    if (pedestrian_request_north || pedestrian_request_south) begin
                        ped_state_ns <= PED_REQUESTING;
                    end
                end

                PED_REQUESTING: begin
                    // Wait for North-South green light
                    if (ns_traffic_state == GREEN_STATE) begin
                        ped_state_ns <= PED_WALKING;
                        pedestrian_walk_ns <= 1'b1;
                        ped_countdown_ns <= 8'd20;  // 20 seconds walk time
                    end
                end

                PED_WALKING: begin
                    pedestrian_walk_ns <= 1'b1;
                    if (ped_countdown_ns > 0) begin
                        ped_countdown_ns <= ped_countdown_ns - 1;
                    end else begin
                        ped_state_ns <= PED_DONT_WALK;
                        pedestrian_walk_ns <= 1'b0;
                    end
                end

                PED_DONT_WALK: begin
                    pedestrian_walk_ns <= 1'b0;
                    if (ns_traffic_state == RED_STATE) begin
                        ped_state_ns <= PED_IDLE;
                    end
                end
            endcase
        end
    end

    // Pedestrian East-West Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ped_state_ew <= PED_IDLE;
            ped_countdown_ew <= 0;
            pedestrian_walk_ew <= 1'b0;
        end else begin
            case (ped_state_ew)
                PED_IDLE: begin
                    pedestrian_walk_ew <= 1'b0;
                    if (pedestrian_request_east || pedestrian_request_west) begin
                        ped_state_ew <= PED_REQUESTING;
                    end
                end

                PED_REQUESTING: begin
                    // Wait for East-West green light
                    if (ew_traffic_state == GREEN_STATE) begin
                        ped_state_ew <= PED_WALKING;
                        pedestrian_walk_ew <= 1'b1;
                        ped_countdown_ew <= 8'd20;  // 20 seconds walk time
                    end
                end

                PED_WALKING: begin
                    pedestrian_walk_ew <= 1'b1;
                    if (ped_countdown_ew > 0) begin
                        ped_countdown_ew <= ped_countdown_ew - 1;
                    end else begin
                        ped_state_ew <= PED_DONT_WALK;
                        pedestrian_walk_ew <= 1'b0;
                    end
                end

                PED_DONT_WALK: begin
                    pedestrian_walk_ew <= 1'b0;
                    if (ew_traffic_state == RED_STATE) begin
                        ped_state_ew <= PED_IDLE;
                    end
                end
            endcase
        end
    end

    // Combined pedestrian countdown display
    always @(*) begin
        if (pedestrian_walk_ns || ped_state_ns == PED_WALKING) begin
            pedestrian_countdown = ped_countdown_ns;
            walk_signal_led = 1'b1;
        end else if (pedestrian_walk_ew || ped_state_ew == PED_WALKING) begin
            pedestrian_countdown = ped_countdown_ew;
            walk_signal_led = 1'b1;
        end else begin
            pedestrian_countdown = 8'h00;
            walk_signal_led = 1'b0;
        end
    end

endmodule

// Adaptive Traffic Light Controller
// Adjusts timing based on traffic volume

module adaptive_traffic_controller #(
    parameter BASE_RED_DUR = 30,
    parameter BASE_GREEN_DUR = 25,
    parameter BASE_YELLOW_DUR = 5
) (
    input clk,
    input rst_n,
    input [7:0] traffic_volume,     // 0-255 indicating traffic density
    input [1:0] mode,               // 00: Normal, 01: Heavy, 10: Light
    
    output reg [7:0] adjusted_red_dur,
    output reg [7:0] adjusted_green_dur,
    output reg [7:0] adjusted_yellow_dur
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adjusted_red_dur <= BASE_RED_DUR;
            adjusted_green_dur <= BASE_GREEN_DUR;
            adjusted_yellow_dur <= BASE_YELLOW_DUR;
        end else begin
            case (mode)
                2'b00: begin  // Normal mode
                    adjusted_red_dur <= BASE_RED_DUR;
                    adjusted_green_dur <= BASE_GREEN_DUR;
                    adjusted_yellow_dur <= BASE_YELLOW_DUR;
                end
                2'b01: begin  // Heavy traffic
                    adjusted_red_dur <= BASE_RED_DUR + 10;
                    adjusted_green_dur <= BASE_GREEN_DUR + 15;
                    adjusted_yellow_dur <= BASE_YELLOW_DUR;
                end
                2'b10: begin  // Light traffic
                    adjusted_red_dur <= BASE_RED_DUR - 5;
                    adjusted_green_dur <= BASE_GREEN_DUR - 5;
                    adjusted_yellow_dur <= BASE_YELLOW_DUR;
                end
                default: begin
                    adjusted_red_dur <= BASE_RED_DUR;
                    adjusted_green_dur <= BASE_GREEN_DUR;
                    adjusted_yellow_dur <= BASE_YELLOW_DUR;
                end
            endcase
        end
    end

endmodule

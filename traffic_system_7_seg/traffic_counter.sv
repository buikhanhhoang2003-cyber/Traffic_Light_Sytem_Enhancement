// Traffic Counter and Display Module
// Counts vehicles passing through the intersection and displays the count

module traffic_counter #(
    parameter MAX_COUNT = 9999,      // Maximum vehicles to count (4-digit display)
    parameter CLK_FREQ = 50_000_000, // 50 MHz clock
    parameter DEBOUNCE_TIME = 20     // 20ms debounce for sensor input
) (
    input clk,
    input rst_n,
    input vehicle_sensor,            // Sensor pulse for vehicle detection
    input [1:0] counter_mode,        // 00: Normal, 01: Reset, 10: Pause, 11: Display hold
    
    output reg [15:0] vehicle_count, // Current vehicle count (0-9999)
    output reg [6:0] seg_thousands,  // Thousands digit 7-segment
    output reg [6:0] seg_hundreds,   // Hundreds digit 7-segment
    output reg [6:0] seg_tens,       // Tens digit 7-segment
    output reg [6:0] seg_ones,       // Ones digit 7-segment
    output reg [3:0] digit_select,   // Multiplex digit selection (for 4-digit display)
    output overflow,                 // Flag when count exceeds MAX_COUNT
    output active                    // Flag indicating counter is active
);

    // Internal signals
    reg sensor_debounced;
    reg sensor_prev;
    wire sensor_pulse;
    reg [31:0] debounce_counter;
    reg [1:0] counter_state;
    reg [15:0] display_count;
    reg counting_enabled;
    
    localparam DEBOUNCE_CYCLES = (DEBOUNCE_TIME * CLK_FREQ) / 1_000_000;
    localparam COUNTER_WIDTH = $clog2(DEBOUNCE_CYCLES);
    
    // ==================== SENSOR DEBOUNCING ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_counter <= 0;
            sensor_debounced <= 1'b0;
        end else begin
            if (vehicle_sensor != sensor_debounced) begin
                if (debounce_counter >= DEBOUNCE_CYCLES - 1) begin
                    sensor_debounced <= vehicle_sensor;
                    debounce_counter <= 0;
                end else begin
                    debounce_counter <= debounce_counter + 1;
                end
            end else begin
                debounce_counter <= 0;
            end
        end
    end
    
    // ==================== EDGE DETECTION ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sensor_prev <= 1'b0;
        end else begin
            sensor_prev <= sensor_debounced;
        end
    end
    
    assign sensor_pulse = sensor_debounced & ~sensor_prev;  // Rising edge
    
    // ==================== COUNTER MODE CONTROL ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_state <= 2'b00;
            counting_enabled <= 1'b1;
        end else begin
            counter_state <= counter_mode;
            
            case (counter_mode)
                2'b00: counting_enabled <= 1'b1;      // Normal - counting active
                2'b01: counting_enabled <= 1'b0;      // Reset mode (handled separately)
                2'b10: counting_enabled <= 1'b0;      // Pause - stop counting
                2'b11: counting_enabled <= 1'b1;      // Display hold - continue counting
            endcase
        end
    end
    
    // ==================== VEHICLE COUNTING ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vehicle_count <= 16'd0;
        end else if (counter_mode == 2'b01) begin
            // Reset mode
            vehicle_count <= 16'd0;
        end else if (sensor_pulse && counting_enabled) begin
            // Count vehicle on sensor pulse
            if (vehicle_count < MAX_COUNT) begin
                vehicle_count <= vehicle_count + 1;
            end
        end
    end
    
    // ==================== 7-SEGMENT DISPLAY ENCODING ====================
    function [6:0] encode_segment(input [3:0] digit);
        case (digit)
            4'h0: encode_segment = 7'b1111110;
            4'h1: encode_segment = 7'b0110000;
            4'h2: encode_segment = 7'b1101101;
            4'h3: encode_segment = 7'b1111001;
            4'h4: encode_segment = 7'b0110011;
            4'h5: encode_segment = 7'b1011011;
            4'h6: encode_segment = 7'b1011111;
            4'h7: encode_segment = 7'b1110000;
            4'h8: encode_segment = 7'b1111111;
            4'h9: encode_segment = 7'b1111011;
            default: encode_segment = 7'b0000000;
        endcase
    endfunction
    
    // ==================== SEGMENT DISPLAY UPDATE ====================
    always @(*) begin
        seg_ones = encode_segment(vehicle_count % 10);
        seg_tens = encode_segment((vehicle_count / 10) % 10);
        seg_hundreds = encode_segment((vehicle_count / 100) % 10);
        seg_thousands = encode_segment((vehicle_count / 1000) % 10);
    end
    
    // ==================== MULTIPLEXED DIGIT SELECTION ====================
    reg [31:0] mux_counter;
    localparam MUX_PERIOD = CLK_FREQ / 4000;  // 4kHz total refresh (1kHz per digit)
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_counter <= 0;
            digit_select <= 4'b0001;
        end else begin
            if (mux_counter >= (MUX_PERIOD - 1)) begin
                mux_counter <= 0;
                digit_select <= {digit_select[2:0], digit_select[3]};  // Rotate
            end else begin
                mux_counter <= mux_counter + 1;
            end
        end
    end
    
    // ==================== STATUS OUTPUTS ====================
    assign overflow = (vehicle_count >= MAX_COUNT);
    assign active = counting_enabled;

endmodule

// ==================== TRAFFIC COUNTER DISPLAY DRIVER ====================
module traffic_counter_display #(
    parameter REFRESH_RATE = 1000  // Refresh rate per digit in Hz
) (
    input clk,
    input rst_n,
    input [6:0] seg_thousands,
    input [6:0] seg_hundreds,
    input [6:0] seg_tens,
    input [6:0] seg_ones,
    input [3:0] digit_select_in,
    
    output reg [6:0] segments_out,   // Output to 7-segment display
    output reg [3:0] digit_sel_out   // Output digit selection
);

    always @(*) begin
        digit_sel_out = digit_select_in;
        
        case (digit_select_in)
            4'b0001: segments_out = seg_ones;
            4'b0010: segments_out = seg_tens;
            4'b0100: segments_out = seg_hundreds;
            4'b1000: segments_out = seg_thousands;
            default: segments_out = 7'b0000000;
        endcase
    end

endmodule

// ==================== DUAL-DIRECTION TRAFFIC COUNTER ====================
module dual_direction_counter #(
    parameter MAX_COUNT = 9999,
    parameter CLK_FREQ = 50_000_000
) (
    input clk,
    input rst_n,
    
    // NS Direction (North-South)
    input ns_vehicle_sensor,
    input [1:0] ns_counter_mode,
    
    // EW Direction (East-West)
    input ew_vehicle_sensor,
    input [1:0] ew_counter_mode,
    
    // Display control
    input display_select,  // 0: NS direction, 1: EW direction
    
    // Outputs
    output [15:0] ns_count,
    output [15:0] ew_count,
    output [6:0] seg_thousands,
    output [6:0] seg_hundreds,
    output [6:0] seg_tens,
    output [6:0] seg_ones,
    output [3:0] digit_select,
    output [7:0] status  // bit[7:4] EW status, bit[3:0] NS status
);

    // Internal counter instances
    wire [15:0] ns_count_val;
    wire [15:0] ew_count_val;
    wire ns_overflow, ew_overflow;
    wire ns_active, ew_active;
    
    wire [6:0] ns_seg_thousands, ns_seg_hundreds, ns_seg_tens, ns_seg_ones;
    wire [6:0] ew_seg_thousands, ew_seg_hundreds, ew_seg_tens, ew_seg_ones;
    wire [3:0] ns_mux_sel, ew_mux_sel;

    // NS counter
    traffic_counter #(
        .MAX_COUNT(MAX_COUNT),
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_TIME(20)
    ) ns_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .vehicle_sensor(ns_vehicle_sensor),
        .counter_mode(ns_counter_mode),
        .vehicle_count(ns_count_val),
        .seg_thousands(ns_seg_thousands),
        .seg_hundreds(ns_seg_hundreds),
        .seg_tens(ns_seg_tens),
        .seg_ones(ns_seg_ones),
        .digit_select(ns_mux_sel),
        .overflow(ns_overflow),
        .active(ns_active)
    );

    // EW counter
    traffic_counter #(
        .MAX_COUNT(MAX_COUNT),
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_TIME(20)
    ) ew_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .vehicle_sensor(ew_vehicle_sensor),
        .counter_mode(ew_counter_mode),
        .vehicle_count(ew_count_val),
        .seg_thousands(ew_seg_thousands),
        .seg_hundreds(ew_seg_hundreds),
        .seg_tens(ew_seg_tens),
        .seg_ones(ew_seg_ones),
        .digit_select(ew_mux_sel),
        .overflow(ew_overflow),
        .active(ew_active)
    );

    // ==================== DISPLAY MULTIPLEXING ====================
    always @(*) begin
        if (display_select) begin
            // Display EW direction
            seg_thousands = ew_seg_thousands;
            seg_hundreds = ew_seg_hundreds;
            seg_tens = ew_seg_tens;
            seg_ones = ew_seg_ones;
            digit_select = ew_mux_sel;
        end else begin
            // Display NS direction
            seg_thousands = ns_seg_thousands;
            seg_hundreds = ns_seg_hundreds;
            seg_tens = ns_seg_tens;
            seg_ones = ns_seg_ones;
            digit_select = ns_mux_sel;
        end
    end

    // ==================== COUNT OUTPUTS ====================
    assign ns_count = ns_count_val;
    assign ew_count = ew_count_val;

    // ==================== STATUS BYTE ====================
    // NSstatus: [3]=active, [2]=overflow, [1:0]=reserved
    // EW status: [7]=active, [6]=overflow, [5:4]=reserved
    assign status = {
        ew_active, ew_overflow, 2'b00,
        ns_active, ns_overflow, 2'b00
    };

endmodule

// ==================== SMART TRAFFIC COUNTER WITH AVERAGING ====================
module smart_traffic_counter #(
    parameter MAX_COUNT = 9999,
    parameter HISTORY_DEPTH = 4,  // Keep last 4 counts for averaging
    parameter CLK_FREQ = 50_000_000,
    parameter SAMPLE_WINDOW = 3600  // 1 hour sample window in seconds
) (
    input clk,
    input rst_n,
    input vehicle_sensor,
    input [1:0] counter_mode,
    
    // Current and statistical outputs
    output reg [15:0] current_count,
    output reg [15:0] average_count,
    output reg [15:0] peak_count,
    output reg [15:0] min_count,
    
    // Display outputs
    output [6:0] seg_thousands,
    output [6:0] seg_hundreds,
    output [6:0] seg_tens,
    output [6:0] seg_ones,
    output [3:0] digit_select,
    
    // Statistics
    output reg [7:0] traffic_density,  // 0-255 (light to heavy)
    output overflow
);

    // Use base traffic counter
    traffic_counter #(
        .MAX_COUNT(MAX_COUNT),
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_TIME(20)
    ) base_counter (
        .clk(clk),
        .rst_n(rst_n),
        .vehicle_sensor(vehicle_sensor),
        .counter_mode(counter_mode),
        .vehicle_count(current_count),
        .seg_thousands(seg_thousands),
        .seg_hundreds(seg_hundreds),
        .seg_tens(seg_tens),
        .seg_ones(seg_ones),
        .digit_select(digit_select),
        .overflow(overflow),
        .active()
    );

    // History buffer for averaging
    reg [15:0] history [0:HISTORY_DEPTH-1];
    reg [7:0] history_index;
    reg [31:0] sample_timer;
    localparam SAMPLE_CYCLES = SAMPLE_WINDOW * CLK_FREQ;
    
    // ==================== HISTORY MANAGEMENT ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            history_index <= 0;
            sample_timer <= 0;
            peak_count <= 0;
            min_count <= 16'hFFFF;
            average_count <= 0;
            traffic_density <= 0;
        end else begin
            // Sample every SAMPLE_WINDOW seconds
            if (sample_timer >= SAMPLE_CYCLES) begin
                sample_timer <= 0;
                
                // Store current count in history
                history[history_index] <= current_count;
                
                // Update peak and minimum
                if (current_count > peak_count) begin
                    peak_count <= current_count;
                end
                if (current_count < min_count) begin
                    min_count <= current_count;
                end
                
                // Calculate average
                average_count <= (history[0] + history[1] + history[2] + history[3] + current_count) / 5;
                
                // Calculate traffic density (0-255)
                // Map peak count to density scale
                if (peak_count > 255) begin
                    traffic_density <= 8'hFF;  // Heavy
                end else begin
                    traffic_density <= peak_count[7:0];
                end
                
                // Advance history index
                history_index <= (history_index + 1) % HISTORY_DEPTH;
            end else begin
                sample_timer <= sample_timer + 1;
            end
        end
    end

endmodule

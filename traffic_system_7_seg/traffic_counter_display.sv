// Traffic Counter Display Module
// Comprehensive display driver for traffic counting and statistics

module traffic_counter_display_driver #(
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

// ==================== FOUR-DIGIT DISPLAY FORMATTER ====================
module four_digit_display_formatter (
    input clk,
    input rst_n,
    input [15:0] count_value,        // 0-9999
    
    output [6:0] seg_thousands,
    output [6:0] seg_hundreds,
    output [6:0] seg_tens,
    output [6:0] seg_ones,
    output [3:0] digit_select,
    output [7:0] overflow_flags      // Overflow indicator for each digit
);

    // 7-Segment encoding function
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

    // Extract digits
    wire [3:0] digit_ones = count_value % 10;
    wire [3:0] digit_tens = (count_value / 10) % 10;
    wire [3:0] digit_hundreds = (count_value / 100) % 10;
    wire [3:0] digit_thousands = (count_value / 1000) % 10;

    // Encode segments
    assign seg_ones = encode_segment(digit_ones);
    assign seg_tens = encode_segment(digit_tens);
    assign seg_hundreds = encode_segment(digit_hundreds);
    assign seg_thousands = encode_segment(digit_thousands);

    // Multiplexed digit selection
    reg [31:0] mux_counter;
    localparam MUX_PERIOD = 12500;  // For 50MHz clock, ~4kHz refresh (1kHz per digit)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_counter <= 0;
        end else begin
            if (mux_counter >= (MUX_PERIOD - 1)) begin
                mux_counter <= 0;
            end else begin
                mux_counter <= mux_counter + 1;
            end
        end
    end

    // Assign digit select based on counter
    reg [3:0] digit_select_reg;
    always @(*) begin
        case (mux_counter[13:12])  // Use 2 bits to select among 4 digits
            2'b00: digit_select_reg = 4'b0001;  // Ones
            2'b01: digit_select_reg = 4'b0010;  // Tens
            2'b10: digit_select_reg = 4'b0100;  // Hundreds
            2'b11: digit_select_reg = 4'b1000;  // Thousands
            default: digit_select_reg = 4'b0000;
        endcase
    end

    assign digit_select = digit_select_reg;

    // Overflow flags for each digit
    assign overflow_flags = {
        4'b0000,  // Reserved
        (digit_thousands != 0 && count_value > 9999),
        (digit_hundreds != 0 && count_value > 999),
        (digit_tens != 0 && count_value > 99),
        (digit_ones != 0)
    };

endmodule

// ==================== TRAFFIC DENSITY DISPLAY ====================
module traffic_density_display (
    input clk,
    input rst_n,
    input [7:0] traffic_density,     // 0-255 (light to heavy)
    
    output [6:0] seg_left,           // Left 7-segment (tens)
    output [6:0] seg_right,          // Right 7-segment (ones)
    output [1:0] digit_select,
    output density_light,            // Density indicator: light
    output density_normal,           // Density indicator: normal
    output density_heavy             // Density indicator: heavy
);

    // 7-Segment encoding
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

    // Convert density to percentage (0-100%)
    wire [7:0] density_percentage = (traffic_density * 100) / 256;
    wire [3:0] tens_digit = (density_percentage / 10) % 10;
    wire [3:0] ones_digit = density_percentage % 10;

    assign seg_left = encode_segment(tens_digit);
    assign seg_right = encode_segment(ones_digit);

    // Multiplexed digit selection
    reg [31:0] mux_counter;
    reg digit_toggle;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_counter <= 0;
            digit_toggle <= 1'b0;
        end else begin
            if (mux_counter >= 12500 - 1) begin  // ~2kHz refresh
                mux_counter <= 0;
                digit_toggle <= ~digit_toggle;
            end else begin
                mux_counter <= mux_counter + 1;
            end
        end
    end

    assign digit_select = digit_toggle ? 2'b01 : 2'b10;

    // Traffic density classification
    assign density_light = (traffic_density < 85);      // < 33% = light
    assign density_normal = (traffic_density >= 85) && (traffic_density < 170);  // 33-67% = normal
    assign density_heavy = (traffic_density >= 170);    // > 67% = heavy

endmodule

// ==================== DIRECTIONAL COUNTER DISPLAY SELECTOR ====================
module directional_counter_display (
    input clk,
    input rst_n,
    
    // NS (North-South) Counter Inputs
    input [15:0] ns_count,
    input ns_overflow,
    input ns_active,
    
    // EW (East-West) Counter Inputs
    input [15:0] ew_count,
    input ew_overflow,
    input ew_active,
    
    // Display Selection Control
    input [1:0] display_mode,        // 00: NS, 01: EW, 10: Both (alternate), 11: Hold
    input direction_switch,          // Manual switch to alternate direction
    
    // Display Outputs (4-digit display)
    output [6:0] seg_thousands,
    output [6:0] seg_hundreds,
    output [6:0] seg_tens,
    output [6:0] seg_ones,
    output [3:0] digit_select,
    
    // Status Outputs
    output [3:0] direction_indicator,  // Which direction is displayed: 0001=NS, 0010=EW
    output overflow_status,
    output counter_active,
    output [7:0] display_status
);

    reg [15:0] selected_count;
    reg selected_overflow;
    reg selected_active;
    reg [1:0] display_direction;
    reg [31:0] alternate_timer;
    localparam ALTERNATE_PERIOD = 50_000_000;  // 1 second at 50MHz

    // ==================== DISPLAY MODE LOGIC ====================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_direction <= 2'b00;  // Start with NS
            alternate_timer <= 0;
        end else begin
            case (display_mode)
                2'b00: begin  // Always show NS
                    display_direction <= 2'b00;
                    alternate_timer <= 0;
                end
                2'b01: begin  // Always show EW
                    display_direction <= 2'b01;
                    alternate_timer <= 0;
                end
                2'b10: begin  // Alternate every second
                    if (alternate_timer >= ALTERNATE_PERIOD) begin
                        alternate_timer <= 0;
                        display_direction <= ~display_direction[0];
                    end else begin
                        alternate_timer <= alternate_timer + 1;
                    end
                end
                2'b11: begin  // Hold current (manual control via switch)
                    if (direction_switch) begin
                        display_direction <= ~display_direction[0];
                    end
                    alternate_timer <= 0;
                end
            endcase
        end
    end

    // ==================== SELECT ACTIVE DIRECTION ====================
    always @(*) begin
        if (display_direction[0]) begin
            selected_count = ew_count;
            selected_overflow = ew_overflow;
            selected_active = ew_active;
        end else begin
            selected_count = ns_count;
            selected_overflow = ns_overflow;
            selected_active = ns_active;
        end
    end

    // ==================== DISPLAY FORMATTING ====================
    four_digit_display_formatter formatter (
        .clk(clk),
        .rst_n(rst_n),
        .count_value(selected_count),
        .seg_thousands(seg_thousands),
        .seg_hundreds(seg_hundreds),
        .seg_tens(seg_tens),
        .seg_ones(seg_ones),
        .digit_select(digit_select),
        .overflow_flags()
    );

    // ==================== STATUS OUTPUTS ====================
    assign direction_indicator = display_direction[0] ? 4'b0010 : 4'b0001;
    assign overflow_status = selected_overflow;
    assign counter_active = selected_active;
    assign display_status = {
        selected_active,
        selected_overflow,
        display_direction[0],
        display_mode[1:0],
        2'b00
    };

endmodule

// ==================== STATISTICS DISPLAY FORMATTER ====================
module statistics_display_formatter (
    input clk,
    input rst_n,
    
    // Statistics Inputs
    input [15:0] current_count,
    input [15:0] average_count,
    input [15:0] peak_count,
    input [15:0] min_count,
    
    // Display Selection
    input [2:0] stat_select,  // 000: current, 001: average, 010: peak, 011: min, 100: range
    
    // Display Outputs
    output [6:0] seg_thousands,
    output [6:0] seg_hundreds,
    output [6:0] seg_tens,
    output [6:0] seg_ones,
    output [3:0] digit_select,
    
    // Status
    output [7:0] stat_mode_indicator
);

    reg [15:0] display_value;
    
    // Select which statistic to display
    always @(*) begin
        case (stat_select)
            3'b000: display_value = current_count;                    // Current
            3'b001: display_value = average_count;                    // Average
            3'b010: display_value = peak_count;                       // Peak
            3'b011: display_value = min_count;                        // Minimum
            3'b100: display_value = peak_count - min_count;           // Range
            default: display_value = 16'd0;
        endcase
    end

    // Format and display
    four_digit_display_formatter formatter (
        .clk(clk),
        .rst_n(rst_n),
        .count_value(display_value),
        .seg_thousands(seg_thousands),
        .seg_hundreds(seg_hundreds),
        .seg_tens(seg_tens),
        .seg_ones(seg_ones),
        .digit_select(digit_select),
        .overflow_flags()
    );

    // Status indicator showing which statistic is displayed
    reg [7:0] stat_indicator;
    always @(*) begin
        case (stat_select)
            3'b000: stat_indicator = 8'hC0;  // Current (11000000)
            3'b001: stat_indicator = 8'hA0;  // Average (10100000)
            3'b010: stat_indicator = 8'h90;  // Peak    (10010000)
            3'b011: stat_indicator = 8'h88;  // Min     (10001000)
            3'b100: stat_indicator = 8'h84;  // Range   (10000100)
            default: stat_indicator = 8'h00;
        endcase
    end

    assign stat_mode_indicator = stat_indicator;

endmodule

// ==================== LCD/OLED CHARACTER DISPLAY SUPPORT ====================
module traffic_counter_lcd_display #(
    parameter DISPLAY_WIDTH = 16,  // 16 character display
    parameter DISPLAY_HEIGHT = 2   // 2 line display
) (
    input clk,
    input rst_n,
    
    // Counter Data
    input [15:0] ns_count,
    input [15:0] ew_count,
    input [7:0] ns_density,
    input [7:0] ew_density,
    
    // Display Mode
    input [1:0] display_mode,  // 00: Standard, 01: Detailed, 10: Statistics
    
    // Character Display Outputs (conceptual - interface definition)
    output reg [7:0] char_line1 [0:DISPLAY_WIDTH-1],
    output reg [7:0] char_line2 [0:DISPLAY_WIDTH-1],
    output reg display_update  // Flag when display should be updated
);

    reg [31:0] update_counter;
    localparam UPDATE_PERIOD = 50_000_000;  // Update every 1 second at 50MHz

    // Format strings for display
    reg [7:0] format_buffer [0:31];
    integer i, print_index;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            update_counter <= 0;
            display_update <= 1'b0;
        end else begin
            update_counter <= update_counter + 1;
            
            if (update_counter >= UPDATE_PERIOD) begin
                update_counter <= 0;
                display_update <= 1'b1;
                
                // Format display based on mode
                case (display_mode)
                    2'b00: begin  // Standard - Show NS and EW counts
                        // Line 1: "NS:0000 EW:0000"
                        char_line1[0] = "N";
                        char_line1[1] = "S";
                        char_line1[2] = ":";
                        // Format NS count...
                        
                        // Line 2: "Density H/N/L"
                        char_line2[0] = "D";
                        char_line2[1] = "e";
                        char_line2[2] = "n";
                        char_line2[3] = "s";
                        char_line2[4] = " ";
                    end
                    
                    2'b01: begin  // Detailed - Show density percentages
                        // More detailed information
                    end
                    
                    2'b10: begin  // Statistics
                        // Show peak, average, etc.
                    end
                endcase
            end else begin
                display_update <= 1'b0;
            end
        end
    end

endmodule

// ==================== LED BAR GRAPH DISPLAY ====================
module led_bar_graph_display (
    input clk,
    input rst_n,
    input [7:0] traffic_density,     // 0-255 (normalized traffic level)
    
    output reg [7:0] led_bar,        // 8-bit LED bar output (0-8 LEDs)
    output reg density_light,
    output reg density_normal,
    output reg density_heavy,
    output reg density_critical       // Warn when close to capacity
);

    // Convert 0-255 range to 8-level LED bar
    wire [2:0] bar_level = traffic_density[7:5];  // Use top 3 bits
    wire [7:0] led_values [0:8] = '{
        8'b00000000,  // 0 LEDs
        8'b00000001,  // 1 LED
        8'b00000011,  // 2 LEDs
        8'b00000111,  // 3 LEDs
        8'b00001111,  // 4 LEDs
        8'b00011111,  // 5 LEDs
        8'b00111111,  // 6 LEDs
        8'b01111111,  // 7 LEDs
        8'b11111111   // 8 LEDs (full)
    };

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_bar <= 8'b00000000;
            density_light <= 1'b0;
            density_normal <= 1'b0;
            density_heavy <= 1'b0;
            density_critical <= 1'b0;
        end else begin
            led_bar <= led_values[bar_level];
            
            // Classify density
            if (traffic_density < 64) begin           // < 25%
                density_light <= 1'b1;
                density_normal <= 1'b0;
                density_heavy <= 1'b0;
                density_critical <= 1'b0;
            end else if (traffic_density < 128) begin // 25-50%
                density_light <= 1'b0;
                density_normal <= 1'b1;
                density_heavy <= 1'b0;
                density_critical <= 1'b0;
            end else if (traffic_density < 192) begin // 50-75%
                density_light <= 1'b0;
                density_normal <= 1'b0;
                density_heavy <= 1'b1;
                density_critical <= 1'b0;
            end else begin                             // > 75%
                density_light <= 1'b0;
                density_normal <= 1'b0;
                density_heavy <= 1'b0;
                density_critical <= 1'b1;
            end
        end
    end

endmodule

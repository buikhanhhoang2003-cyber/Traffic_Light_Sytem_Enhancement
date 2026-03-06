// Traffic Light Controller - Main FSM Module
// States: RED, GREEN, YELLOW
// Includes 7-segment display countdown

module traffic_light_controller #(
    parameter RED_DURATION = 30,      // Red light duration in seconds
    parameter GREEN_DURATION = 25,    // Green light duration in seconds  
    parameter YELLOW_DURATION = 5     // Yellow light duration in seconds
) (
    input clk,
    input rst_n,
    input pedestrian_request,
    
    output reg red,
    output reg yellow,
    output reg green,
    output reg [6:0] seven_seg_ones,  // 7-segment for ones place
    output reg [6:0] seven_seg_tens,  // 7-segment for tens place
    output reg [7:0] current_state    // Current state output (00=RED, 01=GREEN, 10=YELLOW)
);

    // State definitions
    localparam RED_STATE = 2'b00;
    localparam GREEN_STATE = 2'b01;
    localparam YELLOW_STATE = 2'b10;

    reg [1:0] state, next_state;
    reg [31:0] counter;
    reg [31:0] state_duration;
    reg [7:0] remaining_seconds;
    
    // State machine control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RED_STATE;
            counter <= 0;
        end else begin
            state <= next_state;
            counter <= counter + 1;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            RED_STATE: begin
                if (counter >= (state_duration * 1_000_000 - 1)) begin
                    next_state = GREEN_STATE;
                end
            end
            GREEN_STATE: begin
                if (counter >= (state_duration * 1_000_000 - 1)) begin
                    next_state = YELLOW_STATE;
                end
            end
            YELLOW_STATE: begin
                if (counter >= (state_duration * 1_000_000 - 1)) begin
                    next_state = RED_STATE;
                end
            end
        endcase
    end

    // State duration and light control
    always @(*) begin
        red = 1'b0;
        yellow = 1'b0;
        green = 1'b0;
        
        case (state)
            RED_STATE: begin
                red = 1'b1;
                state_duration = RED_DURATION;
            end
            GREEN_STATE: begin
                green = 1'b1;
                state_duration = GREEN_DURATION;
            end
            YELLOW_STATE: begin
                yellow = 1'b1;
                state_duration = YELLOW_DURATION;
            end
        endcase
    end

    // Calculate remaining seconds for display
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            remaining_seconds <= 0;
        end else begin
            // Calculate remaining time
            remaining_seconds <= state_duration - (counter / 1_000_000);
        end
    end

    // 7-segment decoder logic
    always @(*) begin
        seven_seg_ones = decode_segment(remaining_seconds % 10);
        seven_seg_tens = decode_segment(remaining_seconds / 10);
        current_state = {6'b0, state};
    end

    // Function to decode 7-segment display
    function [6:0] decode_segment(input [3:0] num);
        case (num)
            4'h0: decode_segment = 7'b1111110; // 0
            4'h1: decode_segment = 7'b0110000; // 1
            4'h2: decode_segment = 7'b1101101; // 2
            4'h3: decode_segment = 7'b1111001; // 3
            4'h4: decode_segment = 7'b0110011; // 4
            4'h5: decode_segment = 7'b1011011; // 5
            4'h6: decode_segment = 7'b1011111; // 6
            4'h7: decode_segment = 7'b1110000; // 7
            4'h8: decode_segment = 7'b1111111; // 8
            4'h9: decode_segment = 7'b1111011; // 9
            default: decode_segment = 7'b0000000;
        endcase
    endfunction

endmodule

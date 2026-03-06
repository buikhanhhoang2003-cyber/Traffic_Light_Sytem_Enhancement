// 7-Segment Display Decoder Module
// Converts 4-bit digit to 7-segment display codes

module seven_segment_decoder (
    input [3:0] digit,
    input [1:0] mode,           // 00: common cathode, 01: common anode
    output reg [6:0] segments   // a,b,c,d,e,f,g
);

    always @(*) begin
        case (digit)
            4'h0: segments = 7'b1111110;
            4'h1: segments = 7'b0110000;
            4'h2: segments = 7'b1101101;
            4'h3: segments = 7'b1111001;
            4'h4: segments = 7'b0110011;
            4'h5: segments = 7'b1011011;
            4'h6: segments = 7'b1011111;
            4'h7: segments = 7'b1110000;
            4'h8: segments = 7'b1111111;
            4'h9: segments = 7'b1111011;
            4'hA: segments = 7'b1110111; // A
            4'hB: segments = 7'b0011111; // b
            4'hC: segments = 7'b1001110; // C
            4'hD: segments = 7'b0111101; // d
            4'hE: segments = 7'b1001111; // E
            4'hF: segments = 7'b1000111; // F
            default: segments = 7'b0000000;
        endcase

        // Invert if common anode
        if (mode[0]) begin
            segments = ~segments;
        end
    end

endmodule

// Enhanced 7-Segment Display Driver with Multiplexing Support
module seven_segment_driver #(
    parameter REFRESH_RATE = 1000  // Refresh rate in Hz
) (
    input clk,
    input rst_n,
    input [6:0] seg_ones,   // 7-segment code for ones digit
    input [6:0] seg_tens,   // 7-segment code for tens digit
    input [1:0] mode,       // Display mode (common cathode/anode)
    
    output reg [6:0] segments,   // Output to 7-segment display
    output reg [1:0] digit_sel   // Output to digit selector
);

    reg [31:0] refresh_counter;
    reg digit_toggle;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_counter <= 0;
            digit_toggle <= 1'b0;
        end else begin
            if (refresh_counter >= (50_000_000 / REFRESH_RATE - 1)) begin  // Assuming 50MHz clock
                refresh_counter <= 0;
                digit_toggle <= ~digit_toggle;
            end else begin
                refresh_counter <= refresh_counter + 1;
            end
        end
    end

    always @(*) begin
        if (digit_toggle) begin
            segments = seg_ones;
            digit_sel = 2'b01;  // Select ones digit
        end else begin
            segments = seg_tens;
            digit_sel = 2'b10;  // Select tens digit
        end
    end

endmodule

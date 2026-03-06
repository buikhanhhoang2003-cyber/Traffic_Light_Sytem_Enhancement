// Counter Module for Traffic Light Timing
// Provides precise timing for traffic light state transitions

module counter #(
    parameter WIDTH = 32,
    parameter MAX_COUNT = 32'd1_000_000  // Count to 1M (1 second at 1MHz)
) (
    input clk,
    input rst_n,
    input enable,
    input load,
    input [WIDTH-1:0] load_value,
    
    output reg [WIDTH-1:0] count,
    output overflow,
    output reg [3:0] second_pulse
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            second_pulse <= 1'b0;
        end else if (load) begin
            count <= load_value;
            second_pulse <= 1'b0;
        end else if (enable) begin
            if (count >= MAX_COUNT) begin
                count <= 0;
                second_pulse <= ~second_pulse;  // Toggle on second boundary
            end else begin
                count <= count + 1;
            end
        end
    end

    assign overflow = (count >= MAX_COUNT);

endmodule

// Frequency Divider Module for Clock Generation
module freq_divider #(
    parameter DIVISOR = 1_000_000,  // Divide input clock to get 1 Hz from 1MHz
    parameter WIDTH = 20
) (
    input clk,
    input rst_n,
    input enable,
    
    output reg clk_out
);

    reg [WIDTH-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else if (enable) begin
            if (counter >= (DIVISOR / 2 - 1)) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule

// PWM Controller for LED Brightness Control
module pwm_controller #(
    parameter WIDTH = 8,
    parameter PERIOD = 256
) (
    input clk,
    input rst_n,
    input enable,
    input [WIDTH-1:0] duty_cycle,  // 0-255 for 0-100%
    
    output reg pwm_out
);

    reg [WIDTH-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            pwm_out <= 1'b0;
        end else if (enable) begin
            if (counter >= (PERIOD - 1)) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
            end
            pwm_out <= (counter < duty_cycle);
        end
    end

endmodule

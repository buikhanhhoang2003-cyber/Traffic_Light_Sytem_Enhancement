// Utility Modules for Traffic Light System
// Includes debouncer, edge detector, and synchronizers

// Button Debouncer Module
module button_debouncer #(
    parameter DEBOUNCE_TIME = 20,  // 20ms debounce time
    parameter CLK_FREQ = 50_000_000
) (
    input clk,
    input rst_n,
    input button_in,
    output reg button_out
);

    localparam DEBOUNCE_CYCLES = (DEBOUNCE_TIME * CLK_FREQ) / 1_000_000;
    localparam COUNTER_WIDTH = $clog2(DEBOUNCE_CYCLES);

    reg button_sync;
    reg [COUNTER_WIDTH-1:0] debounce_counter;
    reg debounce_flag;

    // Synchronize input
    reg button_ff;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_ff <= 1'b0;
            button_sync <= 1'b0;
        end else begin
            button_ff <= button_in;
            button_sync <= button_ff;
        end
    end

    // Debouncing logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_counter <= 0;
            button_out <= 1'b0;
            debounce_flag <= 1'b0;
        end else begin
            if (button_sync != button_out) begin
                if (debounce_counter >= DEBOUNCE_CYCLES - 1) begin
                    button_out <= button_sync;
                    debounce_counter <= 0;
                    debounce_flag <= 1'b1;
                end else begin
                    debounce_counter <= debounce_counter + 1;
                    debounce_flag <= 1'b0;
                end
            end else begin
                debounce_counter <= 0;
                debounce_flag <= 1'b0;
            end
        end
    end

endmodule

// Edge Detector Module (Rising Edge)
module edge_detector_rising (
    input clk,
    input rst_n,
    input signal_in,
    output edge_detected
);

    reg signal_delay;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_delay <= 1'b0;
        end else begin
            signal_delay <= signal_in;
        end
    end

    assign edge_detected = signal_in & ~signal_delay;

endmodule

// Edge Detector Module (Falling Edge)
module edge_detector_falling (
    input clk,
    input rst_n,
    input signal_in,
    output edge_detected
);

    reg signal_delay;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_delay <= 1'b0;
        end else begin
            signal_delay <= signal_in;
        end
    end

    assign edge_detected = ~signal_in & signal_delay;

endmodule

// Synchronizer for asynchronous signals
module synchronizer #(
    parameter STAGES = 2
) (
    input clk,
    input rst_n,
    input async_in,
    output sync_out
);

    reg [STAGES-1:0] sync_chain;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_chain <= 0;
        end else begin
            sync_chain <= {sync_chain[STAGES-2:0], async_in};
        end
    end

    assign sync_out = sync_chain[STAGES-1];

endmodule

// Pulse Generator - Generates single clock pulse from edge
module pulse_generator #(
    parameter PULSE_WIDTH = 1
) (
    input clk,
    input rst_n,
    input trigger,
    output reg pulse_out
);

    reg [15:0] pulse_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_counter <= 0;
            pulse_out <= 1'b0;
        end else begin
            if (trigger) begin
                pulse_counter <= PULSE_WIDTH;
                pulse_out <= 1'b1;
            end else if (pulse_counter > 0) begin
                pulse_counter <= pulse_counter - 1;
                pulse_out <= 1'b1;
            end else begin
                pulse_out <= 1'b0;
            end
        end
    end

endmodule

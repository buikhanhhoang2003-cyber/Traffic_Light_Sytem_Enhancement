// Testbench for Traffic Light System
// Simulates the traffic light controller and verifies correct operation

`timescale 1ns / 1ps

module tb_traffic_system;

    // Parameters
    localparam CLK_PERIOD = 20;  // 50 MHz clock
    localparam RED_DUR = 3;      // Reduce duration for simulation (3 seconds)
    localparam GREEN_DUR = 2;
    localparam YELLOW_DUR = 1;

    // Testbench signals
    reg clk;
    reg rst_n;
    reg [1:0] mode;
    reg pedestrian_push;
    reg [1:0] manual_state_sel;

    wire red;
    wire yellow;
    wire green;
    wire [6:0] seg_ones;
    wire [6:0] seg_tens;
    wire [1:0] digit_select;
    wire pedestrian_go;
    wire [1:0] traffic_state;
    wire system_ready;

    // Instantiate DUT (Device Under Test)
    top_traffic_system #(.CLK_FREQ(50_000_000), .RED_DUR(RED_DUR), .GREEN_DUR(GREEN_DUR),.YELLOW_DUR(YELLOW_DUR)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .mode(mode),
        .pedestrian_push(pedestrian_push),
        .manual_state_sel(manual_state_sel),
        .red(red),
        .yellow(yellow),
        .green(green),
        .seg_ones(seg_ones),
        .seg_tens(seg_tens),
        .digit_select(digit_select),
        .pedestrian_go(pedestrian_go),
        .traffic_state(traffic_state),
        .system_ready(system_ready)
    );

    // Clock generation
    always begin
        clk = 1'b0;
        #(CLK_PERIOD/2);
        clk = 1'b1;
        #(CLK_PERIOD/2);
    end

    // Test scenarios
    initial begin
        // Initialize signals
        rst_n = 1'b0;
        mode = 2'b00;
        pedestrian_push = 1'b0;
        manual_state_sel = 2'b00;

        // Reset the system
        #(CLK_PERIOD * 10);
        rst_n = 1'b1;

        // Test 1: Normal operation - verify RED state
        $display("Test 1: Normal Operation - RED State");
        wait_for_state(2'b00, 2);  // Wait for RED state
        verify_state(2'b00, "RED");

        // Test 2: Transition to GREEN
        $display("Test 2: Waiting for GREEN transition...");
        wait_for_state(2'b01, 10);  // Wait for GREEN state
        verify_state(2'b01, "GREEN");

        // Test 3: Test pedestrian request
        $display("Test 3: Testing pedestrian request during GREEN");
        pedestrian_push = 1'b1;
        #(CLK_PERIOD * 50);
        pedestrian_push = 1'b0;

        // Test 4: Transition to YELLOW
        $display("Test 4: Waiting for YELLOW transition...");
        wait_for_state(2'b10, 5);  // Wait for YELLOW state
        verify_state(2'b10, "YELLOW");

        // Test 5: Transition back to RED
        $display("Test 5: Waiting for RED transition...");
        wait_for_state(2'b00, 2);
        verify_state(2'b00, "RED");

        $display("All tests completed!");
        $finish;
    end

    // Helper task: Wait for specific state
    task wait_for_state(input [1:0] state, input [31:0] timeout_cycles);
        reg [31:0] cycle_count = 0;
        begin
            while ((traffic_state != state) && (cycle_count < timeout_cycles * 1_000_000)) begin
                #CLK_PERIOD;
                cycle_count = cycle_count + 1;
            end
            if (cycle_count >= timeout_cycles * 1_000_000) begin
                $display("ERROR: Timeout waiting for state %b", state);
            end
        end
    endtask

    // Helper task: Verify current state
    task verify_state(input [1:0] expected_state, input string state_name);
        if (traffic_state == expected_state) begin
            $display("PASS: State is %s (expected %b, got %b)", state_name, expected_state, traffic_state);
        end else begin
            $display("FAIL: State mismatch - expected %s (%b), got %b", state_name, expected_state, traffic_state);
        end
    endtask

    // Monitor output values
    always @(posedge clk) begin
        if (rst_n) begin
            $display("[Time: %t] State: %b | RED: %b | GREEN: %b | YELLOW: %b | SEG: {%b, %b} | PED_GO: %b",
                     $time, traffic_state, red, green, yellow, seg_tens, seg_ones, pedestrian_go);
        end
    end

endmodule

// =============================================================================
// traffic_fsm.v
// 8-state FSM:
//   S0: A_STRAIGHT  — Axis A straight green + pedestrian
//   S1: A_S_YELLOW  — Axis A straight yellow
//   S2: A_LEFT      — Axis A left green
//   S3: A_L_YELLOW  — Axis A left yellow
//   S4: B_STRAIGHT  — Axis B straight green + pedestrian
//   S5: B_S_YELLOW  — Axis B straight yellow
//   S6: B_LEFT      — Axis B left green
//   S7: B_L_YELLOW  — Axis B left yellow
//   ALL_RED x4      — Inter-phase all-red buffers
//   BLINK_RED       — Fault state
// =============================================================================
module traffic_fsm #(
    parameter A_STR_TIME  = 4,
    parameter A_SYEL_TIME = 3,
    parameter A_LFT_TIME  = 4,
    parameter A_LYEL_TIME = 3,
    parameter B_STR_TIME  = 4,
    parameter B_SYEL_TIME = 3,
    parameter B_LFT_TIME  = 4,
    parameter B_LYEL_TIME = 3,
    parameter ALLRED_TIME = 2
)(
    input  wire clk,
    input  wire rst_n,
    input  wire tick_1hz,
    input  wire tick_2hz,
    input  wire system_fault,

    // Axis A = North/South
    output reg  a_str_green,
    output reg  a_str_yellow,
    output reg  a_str_red,
    output reg  a_left_green,
    output reg  a_left_yellow,
    output reg  a_left_red,
    output reg  a_ped_walk,

    // Axis B = East/West
    output reg  b_str_green,
    output reg  b_str_yellow,
    output reg  b_str_red,
    output reg  b_left_green,
    output reg  b_left_yellow,
    output reg  b_left_red,
    output reg  b_ped_walk
);

    // =========================================================================
    // STATE ENCODING (replaces typedef enum)
    // =========================================================================
    localparam [3:0]
        FAIL_SAFE  = 4'd0,
        A_STRAIGHT = 4'd1,
        A_S_YELLOW = 4'd2,
        ALLRED_1   = 4'd3,
        A_LEFT     = 4'd4,
        A_L_YELLOW = 4'd5,
        ALLRED_2   = 4'd6,
        B_STRAIGHT = 4'd7,
        B_S_YELLOW = 4'd8,
        ALLRED_3   = 4'd9,
        B_LEFT     = 4'd10,
        B_L_YELLOW = 4'd11,
        ALLRED_4   = 4'd12,
        BLINK_RED  = 4'd13;

    reg [3:0] state;

    // =========================================================================
    // DURATION LOOKUP
    // =========================================================================
    reg [3:0] dur;
    always @(*) begin
        case (state)
            A_STRAIGHT : dur = A_STR_TIME [3:0];
            A_S_YELLOW : dur = A_SYEL_TIME[3:0];
            ALLRED_1   : dur = ALLRED_TIME [3:0];
            A_LEFT     : dur = A_LFT_TIME [3:0];
            A_L_YELLOW : dur = A_LYEL_TIME[3:0];
            ALLRED_2   : dur = ALLRED_TIME [3:0];
            B_STRAIGHT : dur = B_STR_TIME [3:0];
            B_S_YELLOW : dur = B_SYEL_TIME[3:0];
            ALLRED_3   : dur = ALLRED_TIME [3:0];
            B_LEFT     : dur = B_LFT_TIME [3:0];
            B_L_YELLOW : dur = B_LYEL_TIME[3:0];
            ALLRED_4   : dur = ALLRED_TIME [3:0];
            default    : dur = 4'd1;
        endcase
    end

    // =========================================================================
    // FAULT LATCH
    // =========================================================================
    reg fault_lat;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) fault_lat <= 1'b0;
        else if (system_fault) fault_lat <= 1'b1;
    end

    // =========================================================================
    // BLINK TOGGLE (2Hz for BLINK_RED)
    // =========================================================================
    reg blink;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)        blink <= 1'b0;
        else if (tick_2hz) blink <= ~blink;
    end

    // =========================================================================
    // TIMER + FSM
    // =========================================================================
    reg [3:0] sec_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= FAIL_SAFE;
            sec_cnt <= 4'd0;
        end
        else if (fault_lat) begin
            state   <= BLINK_RED;
            sec_cnt <= 4'd0;
        end
        else if (tick_1hz) begin
            if (sec_cnt + 1 >= dur) begin
                sec_cnt <= 4'd0;
                case (state)
                    FAIL_SAFE  : state <= A_STRAIGHT;
                    A_STRAIGHT : state <= A_S_YELLOW;
                    A_S_YELLOW : state <= ALLRED_1;
                    ALLRED_1   : state <= A_LEFT;
                    A_LEFT     : state <= A_L_YELLOW;
                    A_L_YELLOW : state <= ALLRED_2;
                    ALLRED_2   : state <= B_STRAIGHT;
                    B_STRAIGHT : state <= B_S_YELLOW;
                    B_S_YELLOW : state <= ALLRED_3;
                    ALLRED_3   : state <= B_LEFT;
                    B_LEFT     : state <= B_L_YELLOW;
                    B_L_YELLOW : state <= ALLRED_4;
                    ALLRED_4   : state <= A_STRAIGHT;
                    BLINK_RED  : state <= BLINK_RED;
                    default    : state <= FAIL_SAFE;
                endcase
            end else begin
                sec_cnt <= sec_cnt + 1;
            end
        end
    end

    // =========================================================================
    // OUTPUT LOGIC
    // =========================================================================
    always @(*) begin
        // Default: all red
        a_str_green  = 1'b0; a_str_yellow  = 1'b0; a_str_red  = 1'b1;
        a_left_green = 1'b0; a_left_yellow = 1'b0; a_left_red = 1'b1;
        a_ped_walk   = 1'b0;
        b_str_green  = 1'b0; b_str_yellow  = 1'b0; b_str_red  = 1'b1;
        b_left_green = 1'b0; b_left_yellow = 1'b0; b_left_red = 1'b1;
        b_ped_walk   = 1'b0;

        case (state)
            A_STRAIGHT: begin
                a_str_green = 1'b1; a_str_red = 1'b0;
                a_ped_walk  = 1'b1;
            end
            A_S_YELLOW: begin
                a_str_yellow = 1'b1; a_str_red = 1'b0;
            end
            ALLRED_1: begin end
            A_LEFT: begin
                a_left_green = 1'b1; a_left_red = 1'b0;
            end
            A_L_YELLOW: begin
                a_left_yellow = 1'b1; a_left_red = 1'b0;
            end
            ALLRED_2: begin end
            B_STRAIGHT: begin
                b_str_green = 1'b1; b_str_red = 1'b0;
                b_ped_walk  = 1'b1;
            end
            B_S_YELLOW: begin
                b_str_yellow = 1'b1; b_str_red = 1'b0;
            end
            ALLRED_3: begin end
            B_LEFT: begin
                b_left_green = 1'b1; b_left_red = 1'b0;
            end
            B_L_YELLOW: begin
                b_left_yellow = 1'b1; b_left_red = 1'b0;
            end
            ALLRED_4: begin end
            BLINK_RED: begin
                a_str_red  = blink;
                a_left_red = blink;
                b_str_red  = blink;
                b_left_red = blink;
            end
            default: begin end
        endcase
    end

endmodule
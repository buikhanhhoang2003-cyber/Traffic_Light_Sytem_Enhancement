// System Configuration and Constants File

package traffic_light_pkg;

    // ==================== STATE DEFINITIONS ====================
    typedef enum logic [1:0] {
        RED_STATE    = 2'b00,
        GREEN_STATE  = 2'b01,
        YELLOW_STATE = 2'b10,
        RESERVED     = 2'b11
    } traffic_state_t;

    typedef enum logic [1:0] {
        NS_GREEN = 2'b00,      // North-South green
        EW_GREEN = 2'b01,      // East-West green
        TRANSITION = 2'b10,    // Yellow transition
        RESERVED_STATE = 2'b11
    } intersection_phase_t;

    typedef enum logic [1:0] {
        NORMAL_MODE = 2'b00,
        MANUAL_MODE = 2'b01,
        EMERGENCY_MODE = 2'b10
    } operation_mode_t;

    // ==================== TIMING CONSTANTS ====================
    localparam int RED_DURATION_DEFAULT = 30;      // seconds
    localparam int GREEN_DURATION_DEFAULT = 25;    // seconds
    localparam int YELLOW_DURATION_DEFAULT = 5;    // seconds
    localparam int PEDESTRIAN_WALK_TIME = 20;      // seconds
    localparam int EMERGENCY_PRIORITY_TIME = 30;   // seconds

    // ==================== CLOCK CONFIGURATION ====================
    localparam int CLK_FREQ_HZ = 50_000_000;       // 50 MHz
    localparam int CLK_PERIOD_NS = 20;             // 20 ns
    
    // Prescaler values
    localparam int MICROSECOND_CYCLES = CLK_FREQ_HZ / 1_000_000;
    localparam int MILLISECOND_CYCLES = CLK_FREQ_HZ / 1_000;
    localparam int SECOND_CYCLES = CLK_FREQ_HZ;

    // ==================== DEBOUNCE SETTINGS ====================
    localparam int DEBOUNCE_TIME_MS = 20;
    localparam int DEBOUNCE_CYCLES = (DEBOUNCE_TIME_MS * MILLISECOND_CYCLES);

    // ==================== PWM SETTINGS ====================
    localparam int PWM_PERIOD = 256;
    localparam int PWM_WIDTH = 8;

    // ==================== 7-SEGMENT DISPLAY ====================
    localparam int SEGMENT_REFRESH_HZ = 1000;
    localparam logic [6:0] SEG_CODES[0:15] = '{
        7'b1111110,  // 0
        7'b0110000,  // 1
        7'b1101101,  // 2
        7'b1111001,  // 3
        7'b0110011,  // 4
        7'b1011011,  // 5
        7'b1011111,  // 6
        7'b1110000,  // 7
        7'b1111111,  // 8
        7'b1111011,  // 9
        7'b1110111,  // A
        7'b0011111,  // b
        7'b1001110,  // C
        7'b0111101,  // d
        7'b1001111,  // E
        7'b1000111   // F
    };
    
    // Segment bit mapping: {g, f, e, d, c, b, a}
    localparam int SEGMENT_A = 0;
    localparam int SEGMENT_B = 1;
    localparam int SEGMENT_C = 2;
    localparam int SEGMENT_D = 3;
    localparam int SEGMENT_E = 4;
    localparam int SEGMENT_F = 5;
    localparam int SEGMENT_G = 6;

    // ==================== PEDESTRIAN CROSSING ====================
    typedef enum logic [1:0] {
        PED_IDLE = 2'b00,
        PED_REQUESTING = 2'b01,
        PED_WALKING = 2'b10,
        PED_DONT_WALK = 2'b11
    } pedestrian_state_t;

    localparam int PED_WALK_DURATION = 20;     // seconds
    localparam int PED_FLASH_DURATION = 5;     // seconds

    // ==================== EMERGENCY PRIORITIES ====================
    typedef enum logic [1:0] {
        NS_PRIORITY = 2'b00,   // North-South has priority
        EW_PRIORITY = 2'b01,   // East-West has priority
        ALL_GO = 2'b10         // Both directions (risky - for special cases)
    } emergency_priority_t;

    // ==================== SENSOR THRESHOLDS ====================
    localparam int TRAFFIC_HEAVY_THRESHOLD = 200;    // > 200 = heavy
    localparam int TRAFFIC_LIGHT_THRESHOLD = 50;     // < 50 = light
    localparam int TRAFFIC_NORMAL_THRESHOLD = 100;   // 50-200 = normal

    // ==================== ERROR CODES ====================
    typedef enum logic [3:0] {
        NO_ERROR = 4'h0,
        CLK_ERROR = 4'h1,
        SENSOR_ERROR = 4'h2,
        DISPLAY_ERROR = 4'h3,
        LIGHT_ERROR = 4'h4,
        PEDESTRIAN_ERROR = 4'h5,
        CONFIGURATION_ERROR = 4'h6
    } error_code_t;

endpackage : traffic_light_pkg

// Implementation file with macros
`ifndef TRAFFIC_LIGHT_MACROS_SV
`define TRAFFIC_LIGHT_MACROS_SV

// Useful macros for implementation
`define SECONDS_TO_CYCLES(s) ((s) * traffic_light_pkg::SECOND_CYCLES)
`define MS_TO_CYCLES(ms) ((ms) * traffic_light_pkg::MILLISECOND_CYCLES)
`define US_TO_CYCLES(us) ((us) * traffic_light_pkg::MICROSECOND_CYCLES)

// Clock enables
`define CLK_DIV_2(cnt) (cnt[0])
`define CLK_DIV_4(cnt) (cnt[1:0] == 2'b00)
`define CLK_DIV_8(cnt) (cnt[2:0] == 3'b000)

// Assertions
`define ASSERT_STATE_VALID(state) \
    assert ((state == traffic_light_pkg::RED_STATE) || \
            (state == traffic_light_pkg::GREEN_STATE) || \
            (state == traffic_light_pkg::YELLOW_STATE)) \
        else $error("Invalid traffic state");

`define ASSERT_TIMING_VALID(dur) \
    assert ((dur > 0) && (dur < 300)) \
        else $error("Timing duration out of valid range");

`endif // TRAFFIC_LIGHT_MACROS_SV

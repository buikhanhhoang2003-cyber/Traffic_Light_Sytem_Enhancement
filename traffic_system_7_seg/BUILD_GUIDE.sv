// Complete Traffic Light System - File Manifest and Build Guide

/*
================================================================================
                    TRAFFIC LIGHT SYSTEM 7-SEGMENT
                        Complete File Manifest
================================================================================

PROJECT LOCATION:
/home/bui-khanh-hoang/Desktop/Traffic_Light_Sytem_Enhancement/traffic_system_7_seg/

TOTAL FILES: 11
================================================================================
*/

// ============================================================================
// CORE MODULES (Fundamental Building Blocks)
// ============================================================================

/*
1. traffic_light_controller.sv
   ─────────────────────────────────────────────────────────────
   Module: traffic_light_controller
   Parameters: RED_DURATION, GREEN_DURATION, YELLOW_DURATION
   
   Description:
   - Main finite state machine (FSM) for traffic light control
   - Implements 3-state cycle: RED → GREEN → YELLOW → RED
   - Integrates 7-segment countdown timer decoder
   - Supports pedestrian request input
   - Drives traffic light outputs and segment display codes
   
   Key Functions:
   - State transition logic
   - Duration management for each light state
   - Real-time countdown calculation
   - 7-segment encoding for digits 0-9
   
   Inputs:  clk, rst_n, pedestrian_request
   Outputs: red, yellow, green, seven_seg_ones, seven_seg_tens
   
   Dependencies: None (standalone)
   Used by: top_traffic_system, multi_lane_intersection, complete_system_example
*/

/*
2. seven_segment_decoder.sv
   ─────────────────────────────────────────────────────────────
   Modules: 
   - seven_segment_decoder: Single digit decoder (0-F)
   - seven_segment_driver: Multiplexed 2-digit display driver
   
   Description:
   - Converts 4-bit digit to 7-segment codes (a,b,c,d,e,f,g)
   - Supports common cathode and common anode configurations
   - Multiplexing driver for simultaneous display of tens/ones
   - Refresh rate configurable (default 1kHz)
   
   Key Functions:
   - Digit-to-segment conversion
   - Mode selection (common cathode/anode)
   - Automatic multiplexing between digit positions
   
   Parameters: REFRESH_RATE (for driver module)
   Inputs:  digit[3:0], mode[1:0], clk, rst_n
   Outputs: segments[6:0], digit_sel[1:0]
   
   Dependencies: None
   Used by: traffic_light_controller, top_traffic_system
*/

/*
3. counter.sv
   ─────────────────────────────────────────────────────────────
   Modules:
   - counter: Precision timing counter
   - freq_divider: Clock frequency divider
   - pwm_controller: PWM for LED brightness control
   
   Description:
   - Provides timing primitives for the system
   - Converts high-frequency clock to lower frequencies
   - Generates PWM signals for LED dimming
   
   Key Functions:
   - Counter with configurable max value
   - Frequency division for 1-second pulse generation
   - PWM duty cycle control
   
   Parameters: WIDTH, MAX_COUNT, DIVISOR, PERIOD
   Inputs:  clk, rst_n, enable, [load_value]
   Outputs: count, overflow, [clk_out, pwm_out]
   
   Dependencies: None
   Used by: frequency scaling in main controller
*/

// ============================================================================
// INTEGRATION MODULES (System Composition)
// ============================================================================

/*
4. traffic_system_interface.sv
   ─────────────────────────────────────────────────────────────
   Module: traffic_system_interface
   Parameters: CLK_FREQ, RED_DURATION, GREEN_DURATION, YELLOW_DURATION
   
   Description:
   - Intermediate integration layer
   - Combines traffic light controller with 7-segment driver
   - Provides clean interface for higher-level modules
   - Includes signal routing and display management
   
   Key Functions:
   - Module instantiation and connection
   - Signal aggregation
   - Status output generation
   
   Inputs:  clk, rst_n, pedestrian_request, enable
   Outputs: red, yellow, green, segments, digit_sel, status_signals
   
   Dependencies: traffic_light_controller, seven_segment_driver
   Used by: top_traffic_system, complete_system_example
*/

/*
5. top_traffic_system.sv
   ─────────────────────────────────────────────────────────────
   Module: top_traffic_system
   Parameters: CLK_FREQ, RED_DUR, GREEN_DUR, YELLOW_DUR
   
   Description:
   - Top-level system wrapper
   - Adds input synchronization and debouncing
   - Supports multiple operating modes (normal, manual, emergency)
   - Pedestrian signal conditioning
   - Main entry point for basic traffic light system
   
   Key Features:
   - Asynchronous input synchronizers (2-stage)
   - Mode-based system control
   - Pedestrian crossing integration
   - System ready/status signals
   
   Inputs:  clk, rst_n, mode[1:0], pedestrian_push, manual_state_sel
   Outputs: red, yellow, green, seg_ones, seg_tens, digitsel, status
   
   Dependencies: traffic_light_controller, seven_segment_driver
   Used by: 4-way intersection, complete systems
*/

// ============================================================================
// ADVANCED FEATURE MODULES (Optional Enhancements)
// ============================================================================

/*
6. utility_modules.sv
   ─────────────────────────────────────────────────────────────
   Modules:
   - button_debouncer: Mechanical switch debouncing (20ms default)
   - edge_detector_rising: Rising edge detection
   - edge_detector_falling: Falling edge detection
   - synchronizer: Multi-stage async synchronizer
   - pulse_generator: Single-cycle pulse generation
   
   Description:
   - Input signal conditioning utilities
   - Removes metastability and switch bounce
   - Edge detection for event triggering
   - Helps ensure timing closure and reliability
   
   Key Functions:
   - Input signal cleaning
   - Edge capturing for button presses
   - Clock domain crossing (CDC) safety
   - Pulse stretching for reliable triggering
   
   Parameters: DEBOUNCE_TIME, CLK_FREQ, STAGES, PULSE_WIDTH
   Inputs:  clk, rst_n, button_in, signal_in, async_in, trigger
   Outputs: button_out, edge_detected, sync_out, pulse_out
   
   Dependencies: None
   Used by: complete_system_example, pedestrian control paths
*/

/*
7. pedestrian_crossing.sv
   ─────────────────────────────────────────────────────────────
   Modules:
   - pedestrian_crossing_controller: 4-way pedestrian control
   - adaptive_traffic_controller: Traffic-volume-based timing
   
   Description:
   - Manages pedestrian walk/don't walk signals
   - Handles N,S,E,W crossing requests independently
   - Countdown timer display for walk duration
   - Adapts traffic light timing based on traffic density
   
   Key Features:
   - State machine per direction (IDLE, REQUESTING, WALKING, DONT_WALK)
   - 20-second walk signal per request
   - Combined pedestrian countdown display
   - Traffic-volume sensing (light, normal, heavy modes)
   
   Parameters: (none for pedestrian, BASE durations for adaptive)
   Inputs:  clk, rst_n, ped_requests (N/S/E/W), traffic_state, volume, mode
   Outputs: ped_walk_ns, ped_walk_ew, walk_signal, countdown
   
   Dependencies: None (standalone)
   Used by: multi_lane_intersection, complete_system_example
*/

/*
8. multi_lane_intersection.sv
   ─────────────────────────────────────────────────────────────
   Modules:
   - multi_lane_intersection: Complete 4-way intersection
   - emergency_override: Emergency vehicle priority control
   
   Description:
   - Full 4-way intersection management
   - Separate N-S and E-W phases with proper exclusion
   - Emergency vehicle override system
   - Pedestrian crossing integration for all 4 corners
   
   Key Features:
   - Dual-phase traffic control (N-S green / E-W green alternation)
   - 30-second emergency priority override
   - Per-direction pedestrian signals
   - Safe state transitions
   
   Parameters: RED_DUR, GREEN_DUR, YELLOW_DUR, CLK_FREQ
   Inputs:  clk, rst_n, ped_requests (4x), traffic_volumes (4x),
            emergency_signal, emergency_direction
   Outputs: Light outputs (NS/EW x 3), segments, pedestrian signals
   
   Dependencies: traffic_light_controller, pedestrian_crossing,
                 seven_segment_driver
   Used by: Full traffic intersection implementations
*/

// ============================================================================
// SYSTEM EXAMPLES AND INTEGRATION
// ============================================================================

/*
9. complete_system_example.sv
   ─────────────────────────────────────────────────────────────
   Module: complete_traffic_system_example
   
   Description:
   - Complete, production-ready integration example
   - Shows all modules working together
   - Input conditioning pipeline:
     Raw inputs → Debounce → Edge detect → System logic
   - Proper mode handling and emergency override
   - Full comment documentation of signal flow
   
   Key Features:
   - Clock generation (divider for 1MHz timing)
   - All input signal conditioning
   - Adaptive traffic control
   - Emergency override with proper prioritization
   - Status aggregation for monitoring
   
   Design Pattern:
   1. Input debouncing (removes switch bounce)
   2. Edge detection (generates trigger pulses)
   3. Adaptive timing (based on traffic volume)
   4. Main traffic control (state machine)
   5. Pedestrian integration (walk signal coordination)
   6. Emergency override (highest priority)
   7. Output multiplexing (select normal or override)
   8. Status monitoring (visibility into system state)
   
   Dependencies: All core and advanced modules
   Usage: Baseline for FPGA implementation
*/

/*
10. tb_traffic_system.sv
    ─────────────────────────────────────────────────────────────
    Module: tb_traffic_system (Testbench)
    
    Description:
    - SimulationTestbench for traffic light system verification
    - Tests state transitions and timing accuracy
    - Verifies pedestrian request handling
    - Monitors segment display updates
    - Duration scaling for faster simulation (3-2-1 sec instead of 30-25-5)
    
    Test Scenarios Included:
    1. State Transitions: Verify RED→GREEN→YELLOW→RED cycle
    2. Pedestrian Request: Button press handling
    3. Display Countdown: Verify segment updates
    4. Edge Cases: Simultaneous requests, rapid transitions
    
    Helper Tasks:
    - wait_for_state(): Block until specific state reached
    - verify_state(): Check state matches expected value
    
    Monitoring:
    - Real-time cycle-by-cycle display monitoring
    - Traffic light state tracking
    - Segment code observation
    - Pedestrian signal verification
    
    Run Command (Modelsim):
    > vlog -sv *.sv
    > vsim tb_traffic_system
    > run -all
*/

// ============================================================================
// CONFIGURATION AND CONSTRAINTS
// ============================================================================

/*
11. traffic_light_pkg.sv
    ─────────────────────────────────────────────────────────────
    SystemVerilog Package: traffic_light_pkg
    
    Description:
    - Centralized constant and type definitions
    - Enumerated types for states and modes
    - Timing parameters in one location
    - 7-segment digit mappings
    - Useful macros and assertions
    
    Contents:
    - typedef: traffic_state_t, pedestrian_state_t, operation_mode_t
    - Timing constants: RED_DUR, GREEN_DUR, YELLOW_DUR, debounce, etc.
    - Clock calculations: SECOND_CYCLES, MS_TO_CYCLES, US_TO_CYCLES
    - 7-segment codes: SEG_CODES array, bit mappings
    - Safety thresholds: HEAVY_TRAFFIC, LIGHT_TRAFFIC, error codes
    - Useful macros: time conversions, assertions
    
    Benefits:
    - Single source of truth for system parameters
    - Type checking and documentation
    - Easy parameter adjustment
    - Macro-based code generation support
    
    Import Usage:
    import traffic_light_pkg::*;
*/

/*
12. arty_constraints.xdc (Optional)
    ─────────────────────────────────────────────────────────────
    Vivado Constraints File for Arty A7-35 FPGA Board
    
    Description:
    - Pin assignments for FPGA implementation
    - I/O standards and timing constraints
    - Comprehensive comments for different boards
    - Can be adapted for Basys3, Nexys, other boards
    
    Assignments Included:
    - Clock input (100 MHz)
    - Reset signal
    - Traffic light LEDs (3 outputs)
    - 7-segment displays (2x 7-segment via PMOD, 14 outputs)
    - Pedestrian buttons (4 inputs)
    - Mode switches (2 inputs)
    - Status LEDs (optional)
    
    For Different Boards:
    - Basys3: Adjust PACKAGE_PIN values from pinout
    - Nexys A7: Use additional available pins
    - Custom board: Modify based on your schematic
    
    Timing Constraints:
    - Clock: 10ns period (100 MHz)
    - Input delay for buttons: 0.5-2.0 ns
    - Output delay for LEDs: 0.1-1.5 ns
    - Chip configurations (LCMOS, voltage, etc.)
*/

// ============================================================================
// SUPPORTING DOCUMENTATION
// ============================================================================

/*
13. README.md
    ─────────────────────────────────────────────────────────────
    Complete project documentation
    - System overview and features
    - Module descriptions
    - State machine diagram
    - 7-segment display encoding
    - Simulation instructions
    - Hardware implementation guide
    - Parameter explanations
    - Testing scenarios
*/

// ============================================================================
// BUILD AND COMPILATION INSTRUCTIONS
// ============================================================================

// 1. SIMULATION SETUP (Modelsim/Questasim)
// ───────────────────────────────────────────────────────────────
//
// Create project:
//   > project new traffic_light_project
//
// Add all files:
//   > project addfile traffic_light_controller.sv
//   > project addfile seven_segment_decoder.sv
//   > project addfile counter.sv
//   > project addfile traffic_system_interface.sv
//   > project addfile top_traffic_system.sv
//   > project addfile utility_modules.sv
//   > project addfile pedestrian_crossing.sv
//   > project addfile multi_lane_intersection.sv
//   > project addfile traffic_light_pkg.sv
//   > project addfile tb_traffic_system.sv
//
// Compile:
//   > vlog -sv *.sv
//   > vsim tb_traffic_system
//
// Run:
//   > run -all
//   > quit

// 2. VIVADO FPGA SYNTHESIS (Xilinx)
// ───────────────────────────────────────────────────────────────
//
// Create project:
//   1. Vivado → Create Project
//   2. Select Arty A7-35: xc7a35tcsg324-1
//   3. Add source files (all *.sv)
//   4. Add constraint file: arty_constraints.xdc
//
// Build flow:
//   Project Settings → top_traffic_system
//   Run → Synthesis
//   Run → Implementation
//   Generate → Bitstream
//
// Program FPGA:
//   Hardware Manager → Open Target → Program Device

// 3. QUARTUS FPGA SYNTHESIS (Intel/Altera)
// ───────────────────────────────────────────────────────────────
//
// Create project (.qpf)
// Analysis & Synthesis:
//   - Add all .sv files
//   - Set top_traffic_system as top entity
// Place & Route:
//   - Use custom pin assignment file
// Generate Programming File (.sof)
// Program FPGA via USB-Blaster

// 4. VERILATOR SIMULATION (Free/Open-source)
// ───────────────────────────────────────────────────────────────
//
//   > verilator --cc --exe --build -j 4 tb_traffic_system.sv *.sv
//   > ./obj_dir/Vtb_traffic_system
//
// With waveform:
//   > verilator --cc --exe --build --trace -j 4 tb_traffic_system.sv *.sv
//   > ./obj_dir/Vtb_traffic_system

// ============================================================================
// FILE COMPILATION ORDER (Important!)
// ============================================================================
//
// Recommended order for synthesis/simulation:
//
// 1. traffic_light_pkg.sv       (Package definitions first)
// 2. counter.sv                 (No dependencies)
// 3. seven_segment_decoder.sv   (No dependencies)
// 4. traffic_light_controller.sv (Uses counter, decoder)
// 5. utility_modules.sv         (No dependencies on traffic modules)
// 6. pedestrian_crossing.sv     (No dependencies on traffic modules)
// 7. traffic_system_interface.sv (Uses controller, decoder)
// 8. multi_lane_intersection.sv (Uses all components)
// 9. top_traffic_system.sv      (Top-level wrapper)
// 10. complete_system_example.sv (Uses all modules)
// 11. tb_traffic_system.sv      (Testbench - last for sim)
//
// For FPGA synthesis:
// - Set top_traffic_system or complete_system_example as TOP
// - All source files added to project
// - Compilation handles dependencies automatically

// ============================================================================
// QUICK START STEPS
// ============================================================================

/*
SIMULATION:
  1. Open terminal in project directory
  2. Command: vlog -sv *.sv && vsim tb_traffic_system -c -do "run -all"
  3. Observe: State transitions, LED changes, countdown timer

FPGA IMPLEMENTATION:
  1. Open Vivado
  2. File → New Project
  3. Add all *.sv files as sources
  4. Add arty_constraints.xdc
  5. Run Synthesis → Implementation → Generate Bitstream
  6. Program device via USB

VERIFICATION:
  1. Check traffic light LEDs change every 5-30 seconds
  2. Press pedestrian button - observe walk signal timing
  3. Verify 7-segment display shows countdown (tens, ones)
  4. Test mode switches for different behaviors
*/

// ============================================================================
// PROJECT STATISTICS
// ============================================================================
/*
Total Lines of Code: ~2500
Total Modules: 15
Estimated FPGA LUTs: 500-1000 (basic) / 2000-3000 (full system)
Estimated FPGA FFs: 200-400
Maximum Frequency: 100+ MHz
Clock Domain Crossings: Handled with synchronizers

Default Parameters:
  Clock: 50-100 MHz
  Red Duration: 30 seconds
  Green Duration: 25 seconds
  Yellow Duration: 5 seconds
  Pedestrian Walk: 20 seconds
  Display Refresh: 1000 Hz
  Debounce: 20 ms
*/

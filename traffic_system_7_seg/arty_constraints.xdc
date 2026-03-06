// Constraints File for Arty A7-35 FPGA Board
// Pin assignments for traffic light system with 7-segment display

// ==================== CLOCK AND RESET ====================
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { rst_n }];

// ==================== TRAFFIC LIGHTS ====================
// Main traffic light outputs (using RGB LEDs on board)
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { red }];      // LED0_R
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { yellow }];   // LED1_G (yellow = red+green)
set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { green }];    // LED0_G

// ==================== 7-SEGMENT DISPLAY (Common Cathode) ====================
// Assuming 2 7-segment displays using PMOD connectors JA and JB

// Display 1 - Tens digit (PMOD-JA connector)
set_property -dict { PACKAGE_PIN J1    IOSTANDARD LVCMOS33 } [get_ports { seg_tens[0] }];  // JA1 - Segment a
set_property -dict { PACKAGE_PIN L2    IOSTANDARD LVCMOS33 } [get_ports { seg_tens[1] }];  // JA2 - Segment b
set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports { seg_tens[2] }];  // JA3 - Segment c
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { seg_tens[3] }];  // JA4 - Segment d
set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports { seg_tens[4] }];  // JA7 - Segment e
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { seg_tens[5] }];  // JA8 - Segment f
set_property -dict { PACKAGE_PIN G6    IOSTANDARD LVCMOS33 } [get_ports { seg_tens[6] }];  // JA9 - Segment g

// Display 2 - Ones digit (PMOD-JB connector)
set_property -dict { PACKAGE_PIN G4    IOSTANDARD LVCMOS33 } [get_ports { seg_ones[0] }];  // JB1 - Segment a
set_property -dict { PACKAGE_PIN H4    IOSTANDARD LVCMOS33 } [get_ports { seg_ones[1] }];  // JB2 - Segment b
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { seg_ones[2] }];  // JB3 - Segment c
set_property -dict { PACKAGE_PIN H2    IOSTANDARD LVCMOS33 } [get_ports { seg_ones[3] }];  // JB4 - Segment d
set_property -dict { PACKAGE_PIN G3    IOSTANDARD LVCMOS33 } [get_ports { seg_ones[4] }];  // JB7 - Segment e
set_property -dict { PACKAGE_PIN G2    IOSTANDARD LVCMOS33 } [get_ports { seg_ones[5] }];  // JB8 - Segment f
set_property -dict { PACKAGE_PIN F4    IOSTANDARD LVCMOS33 } [get_ports { seg_ones[6] }];  // JB9 - Segment g

// Decimal points (optional)
// set_property -dict { PACKAGE_PIN G5    IOSTANDARD LVCMOS33 } [get_ports { seg_dp_tens }];  // JA10 - DP tens
// set_property -dict { PACKAGE_PIN F3    IOSTANDARD LVCMOS33 } [get_ports { seg_dp_ones }];  // JB10 - DP ones

// ==================== DIGIT SELECT (MULTIPLEXING) ====================
// For common cathode multiplexing (select which digit to display)
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { digit_select[0] }];  // Switch based pin
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { digit_select[1] }];  // Switch based pin

// ==================== PEDESTRIAN BUTTONS (Optional) ====================
// Push buttons on Arty board
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { pedestrian_push }];     // BTN0
// Additional pedestrian buttons can use other buttons
set_property -dict { PACKAGE_PIN C9    IOSTANDARD LVCMOS33 } [get_ports { ped_request_e }];       // BTN1
set_property -dict { PACKAGE_PIN B9    IOSTANDARD LVCMOS33 } [get_ports { ped_request_w }];       // BTN2
set_property -dict { PACKAGE_PIN B10   IOSTANDARD LVCMOS33 } [get_ports { pedestrian_request }];  // BTN3

// ==================== TRAFFIC COUNTER SENSOR INPUTS ====================
// Infrared/inductive sensors for vehicle detection
set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVCMOS33 } [get_ports { ns_vehicle_sensor }];   // PMOD-JD1 (N-S direction)
set_property -dict { PACKAGE_PIN E13   IOSTANDARD LVCMOS33 } [get_ports { ew_vehicle_sensor }];   // PMOD-JD2 (E-W direction)
set_property -dict { PACKAGE_PIN D13   IOSTANDARD LVCMOS33 } [get_ports { display_traffic_count }];  // PMOD-JD3 (display switch)

// ==================== 4-DIGIT TRAFFIC COUNTER DISPLAY (Optional) ====================
// Can use additional PMOD connectors or external display module
// Using PMOD-JC for thousands, hundreds
// Using PMOD-JD remaining pins for tens, ones, and multiplexing

// Counter thousands digit (PMOD-JC1-4)
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_thousands[0] }];  // JC1 - Seg a
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_thousands[1] }];  // JC2 - Seg b
set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_thousands[2] }];  // JC3 - Seg c
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_thousands[3] }];  // JC4 - Seg d

// Counter hundreds digit (PMOD-JC7-10)
set_property -dict { PACKAGE_PIN L13   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_hundreds[0] }];   // JC7 - Seg a
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_hundreds[1] }];   // JC8 - Seg b
set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_hundreds[2] }];   // JC9 - Seg c
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_hundreds[3] }];   // JC10 - Seg d

// Counter tens digit (use remaining pins)
set_property -dict { PACKAGE_PIN B12   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_tens[0] }];       // Seg a
set_property -dict { PACKAGE_PIN B13   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_tens[1] }];       // Seg b
set_property -dict { PACKAGE_PIN A12   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_tens[2] }];       // Seg c
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_tens[3] }];       // Seg d (note: C12 is usually reset, needs adjustment)

// Counter ones digit
set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_ones[0] }];      // Seg a
set_property -dict { PACKAGE_PIN E12   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_ones[1] }];      // Seg b
set_property -dict { PACKAGE_PIN F12   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_ones[2] }];      // Seg c
set_property -dict { PACKAGE_PIN G12   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_ones[3] }];      // Seg d

// Counter remaining segments (e, f, g for each digit can be combined or multiplexed)
set_property -dict { PACKAGE_PIN H12   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_thousands[4] }];  // Seg e
set_property -dict { PACKAGE_PIN H13   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_thousands[5] }];  // Seg f
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_thousands[6] }];  // Seg g

set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_hundreds[4] }];   // Seg e
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_hundreds[5] }];   // Seg f
set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_hundreds[6] }];   // Seg g

set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_tens[4] }];       // Seg e
set_property -dict { PACKAGE_PIN P13   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_tens[5] }];       // Seg f
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_tens[6] }];       // Seg g

set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_ones[4] }];      // Seg e
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_ones[5] }];      // Seg f
set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { counter_seg_ones[6] }];      // Seg g

// Counter digit selection (4 lines for multiplexing)
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { counter_digit_select[0] }];  // Ones
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { counter_digit_select[1] }];  // Tens
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { counter_digit_select[2] }];  // Hundreds
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { counter_digit_select[3] }];  // Thousands

// Note: Adjust pin assignments based on actual board availability
// Alternative: Use external 4-digit 7-segment display module via PMOD connector

// ==================== MODE SELECTION SWITCHES ====================
// DIP switches for mode selection
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { mode[0] }];    // SW0
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { mode[1] }];    // SW1

// ==================== STATUS LEDS ====================
// Additional status indicators
set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports { pedestrian_go }];      // LED2_R
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { system_ready }];       // LED3_B

// ==================== ADDITIONAL IO ====================
// Can be used for traffic sensors, emergency signals, etc.
// Expand PMOD-JC and JD as needed

// ==================== TIMING CONSTRAINTS ====================
// Input delay for asynchronous inputs (buttons)
set_input_delay -clock [get_clocks sys_clk_pin] -min -add_delay 0.500 [get_ports { pedestrian_push }];
set_input_delay -clock [get_clocks sys_clk_pin] -max -add_delay 2.000 [get_ports { pedestrian_push }];

// Output delay for LED signals (no strict requirement, just propagation delay)
set_output_delay -clock [get_clocks sys_clk_pin] -min -add_delay 0.100 [get_ports { red }];
set_output_delay -clock [get_clocks sys_clk_pin] -max -add_delay 1.500 [get_ports { red }];

// ==================== IO STANDARDS ====================
// Configure pull-ups for buttons
set_property PULLUP true [get_ports { pedestrian_push }];
set_property PULLUP true [get_ports { ped_request_e }];
set_property PULLUP true [get_ports { ped_request_w }];
set_property PULLUP true [get_ports { pedestrian_request }];

// ==================== BITSTREAM SETTINGS ====================
set_property CONFIG_VOLTAGE 3.3 [current_design];
set_property CFGBVS VCCO [current_design];
set_property BITSTREAM.GENERAL.COMPRESS true [current_design];

// ==================== POWER MANAGEMENT ====================
set_property SEVERITY {Warning} [get_drc_checks PDRC-153];

// ==================== AREA PLACEMENT ====================
// Suggest placement near clock source for timing critical paths
// Uncomment and modify if timing closure is difficult
// set_property LOC SLICE_X0Y0 [get_cells main_controller]

// Notes:
// 1. This constraints file is for Arty A7-35 board
// 2. Adjust PACKAGE_PIN assignments based on actual board revision
// 3. For different boards, modify accordingly:
//    - Basys3: Use SW0-SW3, BTN0-BTN3, LED0-LED3, etc.
//    - Nexys A7: Use more pins if available
// 4. LVCMOS33 is for 3.3V I/O (check board specifications)
// 5. Drive strength can be adjusted using DRIVE property if needed:
//    set_property DRIVE 12 [get_ports { red }];

// References:
// - Arty A7 Schematic
// - Vivado Design Suite User Guide
// - Board documentation


/ ============================================================================
// Package: common types & helpers
// ============================================================================
package tl_pkg;

  // Operational states 
  typedef enum logic [3:0] {
    S0_A_STRAIGHT = 4'd0,
    S1_A_S_YELLOW = 4'd1,
    S2_A_LEFT     = 4'd2,
    S3_A_L_YELLOW = 4'd3,
    S4_B_STRAIGHT = 4'd4,
    S5_B_S_YELLOW = 4'd5,
    S6_B_LEFT     = 4'd6,
    S7_B_L_YELLOW = 4'd7,
    S8_OVERRIDE   = 4'd8,  // when entering S8 it is yellow
    S9_ALL_RED    = 4'd9   // internal all-red buffer between yellow and next phase
  } state_t;

  // Encoded 12->4 button codes 
  typedef enum logic [3:0] {
    CODE_NONE     = 4'b0000,
    // Axis B : 0001..0110
    CODE_B_PED_1  = 4'b0001, // B-West Ped
    CODE_B_LEFT_1 = 4'b0010, // B-West Left
    CODE_B_TH_1   = 4'b0011, // B-West Straight
    CODE_B_PED_2  = 4'b0100, // B-East Ped
    CODE_B_LEFT_2 = 4'b0101, // B-East Left
    CODE_B_TH_2   = 4'b0110, // B-East Straight
    // Axis A : 0111..1100
    CODE_A_PED_1  = 4'b0111, // A-North Ped
    CODE_A_LEFT_1 = 4'b1000, // A-North Left
    CODE_A_TH_1   = 4'b1001, // A-North Straight
    CODE_A_PED_2  = 4'b1010, // A-South Ped
    CODE_A_LEFT_2 = 4'b1011, // A-South Left
    CODE_A_TH_2   = 4'b1100  // A-South Straight
  } code_t;

  // Helpers to categorize states
  function automatic bit in_green_state(state_t s);
    return (s==S0_A_STRAIGHT || s==S2_A_LEFT || s==S4_B_STRAIGHT || s==S6_B_LEFT);
  endfunction

  function automatic bit in_yellow_state(state_t s);
    return (s==S1_A_S_YELLOW || s==S3_A_L_YELLOW || s==S5_B_S_YELLOW || s==S7_B_L_YELLOW);
  endfunction

endpackage : tl_pkg

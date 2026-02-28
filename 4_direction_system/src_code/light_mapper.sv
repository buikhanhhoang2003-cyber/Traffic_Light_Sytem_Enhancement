module light_mapper(
  input  tl_pkg::state_t s,

  // Axis A (North & South)
  output logic a_straight_r, a_straight_y, a_straight_g,
  output logic a_left_r,     a_left_y,     a_left_g,
  output logic a_p_r,        a_p_g,

  // Axis B (East & West)
  output logic b_straight_r, b_straight_y, b_straight_g,
  output logic b_left_r,     b_left_y,     b_left_g,
  output logic b_p_r,        b_p_g
);
  import tl_pkg::*;

  // Default: all red
  task automatic set_all_red();
    begin
      a_straight_r=1; a_straight_y=0; a_straight_g=0;
      a_left_r    =1; a_left_y    =0; a_left_g    =0;
      a_p_r       =1; a_p_g       =0;

      b_straight_r=1; b_straight_y=0; b_straight_g=0;
      b_left_r    =1; b_left_y    =0; b_left_g    =0;
      b_p_r       =1; b_p_g       =0;
    end
  endtask

  always_comb begin
    set_all_red();

    unique case (s)
      // A-THR green; Ped A green; A-Left red; B all red
      S0_A_STRAIGHT: begin
        a_straight_r=0; a_straight_g=1;
        a_p_r=0;        a_p_g=1;
        a_left_r=1;
      end
      // A-THR yellow
      S1_A_S_YELLOW: begin
        a_straight_r=0; a_straight_y=1;
      end
      // A-LEFT green; Ped A red
      S2_A_LEFT: begin
        a_left_r=0; a_left_g=1;
        a_p_r=1;   a_p_g=0;
      end
      // A-LEFT yellow
      S3_A_L_YELLOW: begin
        a_left_r=0; a_left_y=1;
      end

      // B-THR green; Ped B green; B-Left red
      S4_B_STRAIGHT: begin
        b_straight_r=0; b_straight_g=1;
        b_p_r=0;        b_p_g=1;
        b_left_r=1;
      end
      // B-THR yellow
      S5_B_S_YELLOW: begin
        b_straight_r=0; b_straight_y=1;
      end
      // B-LEFT green; Ped B red
      S6_B_LEFT: begin
        b_left_r=0; b_left_g=1;
        b_p_r=1;   b_p_g=0;
      end
      // B-LEFT yellow
      S7_B_L_YELLOW: begin
        b_left_r=0; b_left_y=1;
      end

      // S8 override hub: show yellow on both straights (per spec)
      S8_OVERRIDE: begin
        a_straight_r=0; a_straight_y=1;
        b_straight_r=0; b_straight_y=1;
      end

      // S9 ALL_RED: 
      S9_ALL_RED: begin end
    endcase
  end

endmodule
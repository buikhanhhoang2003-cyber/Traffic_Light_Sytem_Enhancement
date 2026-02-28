
// ============================================================================
// Top-level: tie everything together
// ============================================================================
module traffic_light_top #(
  parameter int unsigned F_CLK_HZ      = 50_000_000,
  parameter int unsigned T_GREEN_S_THR = 30, #sign through
  parameter int unsigned T_GREEN_S_LT  = 10, #sign turn left 
  parameter int unsigned T_YELLOW_S    = 3,
  parameter int unsigned T_ALLRED_S    = 1,
  parameter int unsigned T_DEBOUNCE_MS = 20
)
(
  input  logic        clk,
  input  logic        rst_n,
  input  logic [11:0] btn_raw,

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

  // Button interface
  logic        jump_req;
  state_t      jump_state;
  logic        accept_jump;

  btn_interface #(
    .F_CLK_HZ(F_CLK_HZ),
    .T_DEBOUNCE_MS(T_DEBOUNCE_MS)
  ) u_btn_if (
    .clk         (clk),
    .rst_n       (rst_n),
    .btn_raw     (btn_raw),
    .accept_jump (accept_jump),
    .jump_req    (jump_req),
    .jump_state  (jump_state)
  );

  // FSM
  state_t cur_state;
  tl_fsm #(
    .F_CLK_HZ      (F_CLK_HZ),
    .T_GREEN_S_THR (T_GREEN_S_THR),
    .T_GREEN_S_LT  (T_GREEN_S_LT),
    .T_YELLOW_S    (T_YELLOW_S),
    .T_ALLRED_S    (T_ALLRED_S)
  ) u_fsm (
    .clk         (clk),
    .rst_n       (rst_n),
    .jump_req    (jump_req),
    .jump_state  (jump_state),
    .accept_jump (accept_jump),
    .cur_state   (cur_state)
  );

  // Light mapping 
  light_mapper u_map (
    .s               (cur_state),

    .a_straight_r    (a_straight_r),
    .a_straight_y    (a_straight_y),
    .a_straight_g    (a_straight_g),
    .a_left_r        (a_left_r),
    .a_left_y        (a_left_y),
    .a_left_g        (a_left_g),
    .a_p_r           (a_p_r),
    .a_p_g           (a_p_g),

    .b_straight_r    (b_straight_r),
    .b_straight_y    (b_straight_y),
    .b_straight_g    (b_straight_g),
    .b_left_r        (b_left_r),
    .b_left_y        (b_left_y),
    .b_left_g        (b_left_g),
    .b_p_r           (b_p_r),
    .b_p_g           (b_p_g)
  );

`ifdef ASSERT_ON
  // Basic mutual exclusion assertions with new names
  property p_no_conflict_straight; @(posedge clk) disable iff (!rst_n)
    !(a_straight_g && b_straight_g);
  endproperty
  assert property(p_no_conflict_straight);

  property p_no_conflict_left; @(posedge clk) disable iff (!rst_n)
    !(a_left_g && b_left_g);
  endproperty
  assert property(p_no_conflict_left);
`endif

endmodule
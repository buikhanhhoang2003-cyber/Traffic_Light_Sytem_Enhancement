
module tl_fsm #(
  parameter int unsigned F_CLK_HZ      = 50_000_000,
  // Phase durations (seconds)
  parameter int unsigned T_GREEN_S_THR = 30, // straight green
  parameter int unsigned T_GREEN_S_LT  = 10, // left-turn green
  parameter int unsigned T_YELLOW_S    = 3,
  parameter int unsigned T_ALLRED_S    = 1
)(
  input  logic         clk,
  input  logic         rst_n,

  // Manual override interface
  input  logic         jump_req,          // from button_if (latched request)
  input  tl_pkg::state_t jump_state,      // target green phase
  output logic         accept_jump,       // pulse to clear request in button_if

  // Current FSM state
  output tl_pkg::state_t cur_state
);
  import tl_pkg::*;

  // Convert seconds to cycles
  localparam longint G_THR_CYC = longint'(F_CLK_HZ) * T_GREEN_S_THR;
  localparam longint G_LT_CYC  = longint'(F_CLK_HZ) * T_GREEN_S_LT;
  localparam longint Y_CYC     = longint'(F_CLK_HZ) * T_YELLOW_S;
  localparam longint AR_CYC    = longint'(F_CLK_HZ) * T_ALLRED_S;

  // State regs
  state_t cur, nxt;
  assign cur_state = cur;

  // Track last YELLOW state to decide the next green after ALL_RED
  state_t last_yellow;

  // Timer
  logic load_tmr;
  logic [63:0] dur_cycles;
  logic t_expired;

  tl_timer u_tmr (
    .clk    (clk),
    .rst_n  (rst_n),
    .load   (load_tmr),
    .cycles (dur_cycles),
    .expired(t_expired)
  );

  // Duration per state (in cycles)
  function automatic longint duration_cycles(state_t s);
    unique case (s)
      S0_A_STRAIGHT, S4_B_STRAIGHT: return G_THR_CYC;
      S2_A_LEFT,     S6_B_LEFT:     return G_LT_CYC;
      S1_A_S_YELLOW, S3_A_L_YELLOW,
      S5_B_S_YELLOW, S7_B_L_YELLOW: return Y_CYC;
      S9_ALL_RED:                   return AR_CYC;
      S8_OVERRIDE:                  return Y_CYC; // "When entering S8 it's yellow"
      default:                      return G_THR_CYC;
    endcase
  endfunction

  // State register + last_yellow tracking
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cur          <= S0_A_STRAIGHT;
      last_yellow  <= S7_B_L_YELLOW; // arbitrary init
    end else begin
      cur <= nxt;
      if (nxt==S1_A_S_YELLOW || nxt==S3_A_L_YELLOW ||
          nxt==S5_B_S_YELLOW || nxt==S7_B_L_YELLOW) begin
        last_yellow <= nxt;
      end
    end
  end

  // Timer control: reload on state change
  logic cur_ne_nxt;
  assign cur_ne_nxt = (nxt != cur);

  always_comb begin
    dur_cycles = duration_cycles(cur);
    load_tmr   = cur_ne_nxt; // reload on every state entry
  end

  // Helper: next green in the normal cycle after ALL_RED, based on last_yellow
  function automatic state_t next_green_after_ar(state_t lastY);
    unique case (lastY)
      S1_A_S_YELLOW: return S2_A_LEFT;     // after A-THR yellow -> A-LEFT green
      S3_A_L_YELLOW: return S4_B_STRAIGHT; // after A-L   yellow -> B-THR green
      S5_B_S_YELLOW: return S6_B_LEFT;     // after B-THR yellow -> B-LEFT green
      S7_B_L_YELLOW: return S0_A_STRAIGHT; // after B-L   yellow -> A-THR green
      default:        return S0_A_STRAIGHT;
    endcase
  endfunction

  // Next-state & accept_jump
  always_comb begin
    nxt         = cur;
    accept_jump = 1'b0;

    unique case (cur)
      // ---- Axis A: Straight cycle ----
      S0_A_STRAIGHT: begin
        if (t_expired) nxt = S1_A_S_YELLOW;
      end
      S1_A_S_YELLOW: begin
        if (t_expired) nxt = S9_ALL_RED;
      end

      // ---- Axis A: Left cycle ----
      S2_A_LEFT: begin
        if (t_expired) nxt = S3_A_L_YELLOW;
      end
      S3_A_L_YELLOW: begin
        if (t_expired) nxt = S9_ALL_RED;
      end

      // ---- Axis B: Straight cycle ----
      S4_B_STRAIGHT: begin
        if (t_expired) nxt = S5_B_S_YELLOW;
      end
      S5_B_S_YELLOW: begin
        if (t_expired) nxt = S9_ALL_RED;
      end

      // ---- Axis B: Left cycle ----
      S6_B_LEFT: begin
        if (t_expired) nxt = S7_B_L_YELLOW;
      end
      S7_B_L_YELLOW: begin
        if (t_expired) nxt = S9_ALL_RED;
      end

      // ---- ALL_RED buffer between phases ----
      S9_ALL_RED: begin
        if (t_expired) begin
          if (jump_req) begin
            // Accept the manual override and proceed to S8 (yellow)
            accept_jump = 1'b1;   // clear the latched button in button_if
            nxt         = S8_OVERRIDE;
          } else begin
            // Continue normal sequence
            nxt = next_green_after_ar(last_yellow);
          end
        end
      end

      // ---- S8: override hub (yellow) before jumping to target green ----
      S8_OVERRIDE: begin
        if (t_expired) begin
          // Enter requested green phase
          unique case (jump_state)
            S0_A_STRAIGHT: nxt = S0_A_STRAIGHT;
            S2_A_LEFT:     nxt = S2_A_LEFT;
            S4_B_STRAIGHT: nxt = S4_B_STRAIGHT;
            S6_B_LEFT:     nxt = S6_B_LEFT;
            default:       nxt = S0_A_STRAIGHT;
          endcase
        end
      end

      default: nxt = S0_A_STRAIGHT;
    endcase

    // Safety preemption behavior:
    // If a jump is requested while in a GREEN state, we still finish the phase
    // via its YELLOW -> ALL_RED (handled naturally by the normal flow above).
    // The actual "accept" happens in ALL_RED, then we go to S8 (yellow), then target green.
  end

endmodule

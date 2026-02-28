
// ============================================================================
// Button Interface: debounce + rising edge + first fome first ferved latch + encoder 12->4 + decoder 4->state
// ============================================================================
module btn_interface #(
  parameter int unsigned F_CLK_HZ      = 50_000_000,
  parameter int unsigned T_DEBOUNCE_MS = 20
)(
  input  logic        clk,
  input  logic        rst_n,
  input  logic [11:0] btn_raw,     

  input  logic        accept_jump, // pulse from FSM when it has accepted the request
  output logic        jump_req,    // 1 when a valid jump request is latched
  output tl_pkg::state_t jump_state // target state for override (green phase)
);

  import tl_pkg::*;

  localparam int unsigned DEBOUNCE_CYC = (F_CLK_HZ / 1000) * T_DEBOUNCE_MS;

  // Debounce + sync for each button
  logic [11:0] btn_db;
  for (genvar i = 0; i < 12; i++) begin : g_db
    debounce_sync #(.CYCLES(DEBOUNCE_CYC)) u_db (
      .clk  (clk),
      .rst_n(rst_n),
      .din  (btn_raw[i]),
      .dout (btn_db[i])
    );
  end

  // Rising edge detection
  logic [11:0] btn_q;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) btn_q <= '0;
    else         btn_q <= btn_db;
  end
  wire [11:0] btn_rise =  btn_db & ~btn_q;


  logic        busy;
  logic [11:0] req_onehot;

  function automatic logic [11:0] pick_first_onehot(input logic [11:0] x);
    for (int k=0;k<12;k++) if (x[k]) return (12'b1 << k);
    return 12'b0;
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      busy       <= 1'b0;
      req_onehot <= '0;
    end else begin
      if (!busy) begin
        if (|btn_rise) begin
          busy       <= 1'b1;                 // lock in the first request
          req_onehot <= pick_first_onehot(btn_rise);
        end
      end else begin
        if (accept_jump) begin                // FSM consumed the request
          busy       <= 1'b0;
          req_onehot <= '0;
        end
      end
    end
  end

  // Priority ENCODER 12->4 
  function automatic code_t enc12_to4 (input logic [11:0] oh);
    unique case (1'b1)
      // Index mapping (can be rewired for board pins):
      // [0] B-W P, [1] B-W L, [2] B-W S, [3] B-E P, [4] B-E L, [5] B-E S,
      // [6] A-S P, [7] A-S L, [8] A-S S, [9] A-N P, [10] A-N L, [11] A-N S
      oh[0]:  return CODE_B_PED_1;
      oh[1]:  return CODE_B_LEFT_1;
      oh[2]:  return CODE_B_TH_1;
      oh[3]:  return CODE_B_PED_2;
      oh[4]:  return CODE_B_LEFT_2;
      oh[5]:  return CODE_B_TH_2;
      oh[6]:  return CODE_A_PED_1;
      oh[7]:  return CODE_A_LEFT_1;
      oh[8]:  return CODE_A_TH_1;
      oh[9]:  return CODE_A_PED_2;
      oh[10]: return CODE_A_LEFT_2;
      oh[11]: return CODE_A_TH_2;
      default:return CODE_NONE;
    endcase
  endfunction

  tl_pkg::code_t enc_code;
  always_comb enc_code = busy ? enc12_to4(req_onehot) : CODE_NONE;

  // DECODER 4->target state + jump_req 
  always_comb begin
    jump_req = (enc_code != CODE_NONE); // asserted if a button is latched (code != 0000)
    unique case (enc_code)
      // Axis B: Ped/Straight -> S4_B_STRAIGHT; Left -> S6_B_LEFT
      CODE_B_PED_1, CODE_B_PED_2,
      CODE_B_TH_1,  CODE_B_TH_2: jump_state = S4_B_STRAIGHT;
      CODE_B_LEFT_1, CODE_B_LEFT_2:       jump_state = S6_B_LEFT;

      // Axis A: Ped/Straight -> S0_A_STRAIGHT; Left -> S2_A_LEFT
      CODE_A_PED_1, CODE_A_PED_2,
      CODE_A_TH_1,  CODE_A_TH_2: jump_state = S0_A_STRAIGHT;
      CODE_A_LEFT_1, CODE_A_LEFT_2:       jump_state = S2_A_LEFT;

      default: jump_state = S8_OVERRIDE; 
    endcase
  end
endmodule

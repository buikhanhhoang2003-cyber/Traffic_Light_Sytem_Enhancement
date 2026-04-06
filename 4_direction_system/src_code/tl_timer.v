// ============================================================================
// Reloadable down-counter timer 
// ============================================================================
module tl_timer(
  input  logic        clk,
  input  logic        rst_n,
  input  logic        load,
  input  logic [63:0] cycles,
  output logic        expired
);
  logic [63:0] cnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)         cnt <= 64'd0;
    else if (load)      cnt <= cycles;
    else if (cnt != 0)  cnt <= cnt - 1;
  end

  assign expired = (cnt == 0);
endmodule


// ============================================================================
// Debounce + 2FF synchronizer 
// ============================================================================
module debounce_sync #(
  parameter int unsigned CYCLES = 1_000_000  // ~20 ms at 50 MHz -> 1,000,000
)(
  input  logic clk, rst_n,
  input  logic din,         // asynchronous, noisy button
  output logic dout         // clean, debounced, clock-domain synchronized
);
  // 2-flop synchronizer
  logic d1, d2;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin d1<=0; d2<=0; end
    else         begin d1<=din; d2<=d1; end
  end

  // Debounce with counter
  logic        stable_state;
  logic [31:0] cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stable_state <= 1'b0;
      cnt          <= '0;
    end else begin
      if (d2 != stable_state) begin
        if (cnt >= CYCLES) begin
          stable_state <= d2;
          cnt          <= '0;
        end else begin
          cnt <= cnt + 1;
        end
      end else begin
        cnt <= '0;
      end
    end
  end
  assign dout = stable_state;
endmodule

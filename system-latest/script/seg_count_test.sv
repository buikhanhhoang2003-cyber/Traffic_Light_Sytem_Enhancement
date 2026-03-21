module seg_count_test (
    input  logic clk,
    input  logic rst_n,

    output logic [3:0] SVNSEG_DIG,
    output logic [7:0] SVNSEG_SEG
);

    // 0.5s counter increment
    localparam CNT_MAX = 25_000_000 - 1;
    // ~1kHz mux refresh (50MHz / 50000)
    localparam MUX_MAX = 50_000 - 1;

    logic [24:0] clk_div;
    logic [15:0] mux_cnt;
    logic [1:0]  dig_sel;

    // 4 separate digit values
    logic [3:0] d1, d2, d3, d4;  // ones, tens, hundreds, thousands
    logic [3:0] cur_digit;

    // Main counter: BCD increment every 0.5s
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 0;
            d1 <= 0; d2 <= 0; d3 <= 0; d4 <= 0;
        end else begin
            if (clk_div == CNT_MAX) begin
                clk_div <= 0;
                // BCD ripple increment
                if (d1 == 9) begin
                    d1 <= 0;
                    if (d2 == 9) begin
                        d2 <= 0;
                        if (d3 == 9) begin
                            d3 <= 0;
                            d4 <= (d4 == 9) ? 0 : d4 + 1;
                        end else d3 <= d3 + 1;
                    end else d2 <= d2 + 1;
                end else d1 <= d1 + 1;
            end else
                clk_div <= clk_div + 1;
        end
    end

    // Mux refresh counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_cnt <= 0;
            dig_sel <= 0;
        end else begin
            if (mux_cnt == MUX_MAX) begin
                mux_cnt <= 0;
                dig_sel <= dig_sel + 1;
            end else
                mux_cnt <= mux_cnt + 1;
        end
    end

    // Digit select and data mux
    always_comb begin
        case (dig_sel)
            2'd0: begin SVNSEG_DIG = 4'b1110; cur_digit = d1; end  // DIG1 ON
            2'd1: begin SVNSEG_DIG = 4'b1101; cur_digit = d2; end  // DIG2 ON
            2'd2: begin SVNSEG_DIG = 4'b1011; cur_digit = d3; end  // DIG3 ON
            2'd3: begin SVNSEG_DIG = 4'b0111; cur_digit = d4; end  // DIG4 ON
            default: begin SVNSEG_DIG = 4'b1111; cur_digit = 4'd0; end
        endcase
    end

    // Same working decoder from your single-digit version
    always_comb begin
        case (cur_digit)
            4'd0: SVNSEG_SEG = 8'b1100_0000;
            4'd1: SVNSEG_SEG = 8'b1111_1001;
            4'd2: SVNSEG_SEG = 8'b1010_0100;
            4'd3: SVNSEG_SEG = 8'b1011_0000;
            4'd4: SVNSEG_SEG = 8'b1001_1001;
            4'd5: SVNSEG_SEG = 8'b1001_0010;
            4'd6: SVNSEG_SEG = 8'b1000_0010;
            4'd7: SVNSEG_SEG = 8'b1111_1000;
            4'd8: SVNSEG_SEG = 8'b1000_0000;
            4'd9: SVNSEG_SEG = 8'b1001_0000;
            default: SVNSEG_SEG = 8'b1111_1111;
        endcase
    end

endmodule
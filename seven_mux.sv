module sevenseg_mux (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [5:0] value,
    input  wire       blank,
    output reg  [7:0] seg,
    output reg  [3:0] digit
);

    // ── 1 kHz refresh counter ─────────────────────────────────────────
    reg [15:0] refresh_cnt;
    reg        sel;   // 0 = tens, 1 = ones

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            refresh_cnt <= 16'd0;
            sel         <= 1'b0;
        end else if (refresh_cnt == 16'd49999) begin
            refresh_cnt <= 16'd0;
            sel         <= ~sel;
        end else begin
            refresh_cnt <= refresh_cnt + 1'b1;
        end
    end

    // ── BCD split ────────────────────────────────────────────────────
    reg [3:0] tens, ones;
    reg [5:0] tmp;

    always @(*) begin
        if (value >= 6'd30) begin
            tens = 4'd3;
            tmp  = value - 6'd30;
            ones = tmp[3:0];
        end else if (value >= 6'd20) begin
            tens = 4'd2;
            tmp  = value - 6'd20;
            ones = tmp[3:0];
        end else if (value >= 6'd10) begin
            tens = 4'd1;
            tmp  = value - 6'd10;
            ones = tmp[3:0];
        end else begin
            tens = 4'd0;
            ones = value[3:0];
            tmp  = 6'd0;
        end
    end

    // ── Segment decode function ───────────────────────────────────────
    // Matches OurFPGA reference exactly
    function [7:0] decode;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0:    decode = 8'hC0;
                4'd1:    decode = 8'hF9;
                4'd2:    decode = 8'hA4;
                4'd3:    decode = 8'hB0;
                4'd4:    decode = 8'h99;
                4'd5:    decode = 8'h92;
                4'd6:    decode = 8'h82;
                4'd7:    decode = 8'hF8;
                4'd8:    decode = 8'h80;
                4'd9:    decode = 8'h90;
                default: decode = 8'hBF; // '-'
            endcase
        end
    endfunction

    // ── Mux: drive seg and digit ──────────────────────────────────────
    // digit is active LOW → 0 = digit ON
    // digit[0] = tens place (PIN_133)
    // digit[1] = ones place (PIN_135)
    // digit[2,3] always OFF (1)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seg   <= 8'hFF;
            digit <= 4'hF;
        end else begin
            if (blank) begin
                seg   <= 8'hBF;      // '--' on both digits
                digit <= 4'b1100;    // both right digits ON (active LOW 0)
            end else begin
                if (sel == 1'b0) begin
                    // tens digit
                    seg   <= decode(tens);
                    digit <= 4'b1110; // digit[0] ON, rest OFF
                end else begin
                    // ones digit
                    seg   <= decode(ones);
                    digit <= 4'b1101; // digit[1] ON, rest OFF
                end
            end
        end
    end

endmodule

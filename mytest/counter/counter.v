module timing (
    input clk_125m,
    input rst,
    output reg clk_en_2m36
);

  reg [5:0] cnt_div_4_2m36;
  always @(posedge clk_125m, rst) begin
    if (rst) begin
      cnt_div_4_2m36 <= 0;
      clk_en_2m36 <= 0;
    end else begin
      cnt_div_4_2m36 <= cnt_div_4_2m36 + 1;
      clk_en_2m36    <= 1'b0;
      if (cnt_div_4_2m36 == 52) begin
        cnt_div_4_2m36 <= 0;
        clk_en_2m36 <= 1'b1;
      end
    end

  end

endmodule

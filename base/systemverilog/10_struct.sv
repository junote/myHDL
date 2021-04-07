module tristate(input logic [3:0] a,
                  input logic en,
                  output tri [3:0] y);

  assign y = en ? a : 4'bz;
  //   assign y = en ? a : 4'bx;

endmodule


module mux2(input logic [3:0] d0, d1,
              input logic s,
              output tri [3:0] y);
  tristate t0(d0, ~s, y);
  tristate t1(d1, s, y);
endmodule


module mux4(input logic [3:0] d0, d1, d2, d3,
              input logic [1:0] s,
              output logic [3:0] y);
  logic [3:0] low, high;
  mux2 lowmux(d0, d1, s[0], low);
  mux2 highmux(d2, d3, s[0], high);
  mux2 finalmux(low, high, s[1], y);
endmodule

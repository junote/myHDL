module tristate (input [3:0] a,
                   input en,
                   output [3:0] y);
  

    assign y = en ? a : 4'bz;

endmodule

module mux2 (input [3:0] d0, d1,
               input s,
               output [3:0] y);
  tristate t0 (d0, ~s, y);
  tristate t1 (d1, s, y);
endmodule


module mux2_8 (input [7:0] d0, d1,
                 input s,
                 output [7:0] y);
  mux2 lsbmux (d0[3:0], d1[3:0], s, y[3:0]);
  mux2 msbmux (d0[7:4], d1[7:4], s, y[7:4]);
endmodule

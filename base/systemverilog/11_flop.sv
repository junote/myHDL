module flop(input logic clk,
              input logic [3:0] d,
              output logic [3:0] q);

  always_ff @(posedge clk)
    q <= d;

endmodule

//Note that <= is used instead of assign inside an always statement.
//always_ff behaves like always but is used exclusively to imply flip-flops and allows tools to produce a warning if anything else is implied.

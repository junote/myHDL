module inv(input logic [3:0] a,
             output logic [3:0] y);
  always_comb
    y = ~a;
endmodule

/*
always_comb reevaluates the statements inside the always statement any time any of the signals on the right hand side
of <= or = in the always statement change. In this case, it is equivalent to always @(a), but is better because 
it avoids mistakes if signals in the always statement are renamed or added.If the code inside the always block is not combinational logic,
SystemVerilog will report a warning. always_comb is equivalent to always @(*), but is preferred in SystemVerilog.
 
*/

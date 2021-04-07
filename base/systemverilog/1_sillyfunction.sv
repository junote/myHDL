module sillyfunction(input logic a,b,c,
                       output logic y);

  assign y = ~a & ~b & ~c |
         a & ~b & ~c |
         a & ~b & c;

endmodule

/*
A SystemVerilog module begins with the module name and a
listing of the inputs and outputs. The assign statement
describes combinational logic. ~ indicates NOT, & indicates
AND, and | indicates OR.
logic signals such as the inputs and outputs are Boolean
variables (0 or 1). They may also have floating and undefined
values.
The logic type was introduced in SystemVerilog. It
supersedes the reg type, which was a perennial source of confusion in Verilog. 
logic should be used everywhere except on
signals with multiple drivers. 
*/

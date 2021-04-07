module sillyfunction(input  a,b,c,
                       output  y);

  assign y = ~a & ~b & ~c |
         a & ~b & ~c |
         a & ~b & c;

endmodule


/*
A Verilog module begins with the module name and a listing
of the inputs and outputs. The assign statement describes
combinational logic. ~ indicates NOT, & indicates AND, and
| indicates OR.
Verilog signals such as the inputs and outputs are
Boolean variables (0 or 1). They may also have floating and
undefined values
*/
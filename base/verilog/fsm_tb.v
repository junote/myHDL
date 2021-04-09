`timescale 1ns/100ps
module fsm_tb;

reg clk,reset,a;
wire y1,y2,y3;
integer i;

patternMoore dut1(clk,reset,a,y1);
// PatternMoore dut2(a,y2,clk,reset);
// PatternMealy dut3(a,y3,clk,reset);

initial begin
    clk = 0;
    reset = 1;
    a = 0;
end

always #10 clk = ~clk;

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0,fsm_tb);
end

initial begin
    #100;
    reset = 0;
    #7;
    for(i = 0; i < 1000; i = i + 1) begin
        a = $urandom%2;
        #10;
    end
    $finish;
end
    
endmodule
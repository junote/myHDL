module counter_tb;
    reg clk_in;
    reg rst;
    wire clk_out;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0,counter_tb);
    end

    initial begin 
        clk_in = 0;
        rst = 1;
        #8 rst = 0;
        #10000 $finish;
    end

    always #8 clk_in <= ~clk_in;

    timing timing_u(clk_in,rst, clk_out);



endmodule




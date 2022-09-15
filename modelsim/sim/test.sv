
module tb_test;



reg           clk_25m;

reg           clk_125m;

reg           rst;





initial begin

	clk_25m=1'b0;clk_125m=1'b0;rst =1'b1;

	#1000ns

	rst =1'b0;

	end

	

 always @*

  clk_25m <= #20ns ~clk_25m;

  

  always @*

  clk_125m <= #4ns ~clk_125m;	

	

assign a= 8'h10>>2; 	

assign b= 8'h10<<2; 	



		

 





	

endmodule

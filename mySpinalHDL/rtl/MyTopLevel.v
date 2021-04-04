// Generator : SpinalHDL v1.4.3    git head : adf552d8f500e7419fff395b7049228e4bc5de26
// Component : MyTopLevel
// Git hash  : 4dad2dfd195a06a5f1b6a3c871f1f0c62fc81eed



module MyTopLevel (
  input               io_cond0,
  input               io_cond1,
  output              io_flag,
  output     [7:0]    io_state,
  input               clk,
  input               reset
);
  reg        [7:0]    counter;

  assign io_state = counter;
  assign io_flag = ((counter == 8'h0) || io_cond1);
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      counter <= 8'h0;
    end else begin
      if(io_cond0)begin
        counter <= (counter + 8'h01);
      end
    end
  end


endmodule

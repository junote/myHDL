module wdg_tb;


bit                         rst                             ;
bit                         clk                             ;
bit                         clk_10hz_fp                     ;

bit                        enable_cold_boot                     ;
bit                        enable_warm_boot                     ;

bit         					wdg_en;
bit                        en_wdg_kick;
bit                        en_wdg_now;

bit                         zynq_power_cycle_en             ;
bit                         warm_reset_out                  ;
bit                         zynq_wdog_timeout               ;




    initial begin 
        #0 rst = 1;
        #0 enable_cold_boot = 0;
        #0 enable_warm_boot = 0;  
        // #0 wdg_en = 0;
        #0 en_wdg_kick = 0;
        #0 en_wdg_now = 0;
        #50 rst = 0;  
        // #0 wdg_en = 0;
        // #0 en_wdg_kick = 0; 
        // #100 enable_cold_boot = 1;
        // #120 enable_cold_boot = 0;
        // #200 enable_warm_boot = 1;
        // #220 enable_warm_boot = 0;
        #300 wdg_en = 1;
        // #320 en_wdg_kick = 1;
        // #340 en_wdg_kick = 0;
        #10000 $finish;
    end

    always #4 clk <= ~clk;
    always #50 clk_10hz_fp  <= ~clk_10hz_fp;
    
   

    wdg u_wdg(.*);

endmodule

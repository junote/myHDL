module wdg 
     (
        input   bit                         rst                             ,
        input   bit                         clk                             ,
        input   bit                         clk_10hz_fp                     ,
        
        input   bit                        enable_cold_boot                     ,
        input   bit                        enable_warm_boot                     ,

        input   bit         					wdg_en,
         input   bit                        en_wdg_kick,
         input   bit                        en_wdg_now,



        output  bit                         zynq_power_cycle_en             ,
        output                              warm_reset_out                  ,
        output  bit                         zynq_wdog_timeout               

    );


    bit [15:0]                              pwrcyc_wait_timer;
    bit [1:0]                               pwrcyc_en_d;
    bit [3:0]                               pwrcyc_cnt4_1hz;
    bit                                     pwrcyc_1hz_fp;

    bit [15:0]                              warmrst_wait_timer;
    bit [1:0]                               warmrst_en_d;
    bit [3:0]                               warmrst_cnt4_1hz;
    bit                                     warmrst_1hz_fp;
    bit [4:0]                               warmrst_pls_cnt;
    bit                                     warm_reset_out_t;

   //watchdog
    // bit         					wdg_en;
    bit [11:0]  					wdg_tmout_val;
    bit [11:0]  					wdg_timer;
    bit         					wdg_tmout;
					
    bit         					wdg_strb;
    bit         					wdg_kick;
					
    bit         					wdg_rst;
    bit         					wdg_rst_pls;
					
    bit [7:0]   					wdg_pls_wdth;
    bit [7:0]   					wdg_pls_timer;
    bit         					wdg_pls_tmout;
    bit         					wdg_pls_n;

    // `ifdef SIMULATION
    localparam ONE_SEC = 10;
    // `else
    // localparam ONE_SEC = 125_000_000;
    // `endif

    reg[27:0] cnt_1s; 
    reg        clk_1hz_fp;
    always @(posedge clk or posedge rst) 
    begin
      if (rst) 
        begin
          cnt_1s   <= 0;
          clk_1hz_fp <= 1'b0;
        end
      else if (cnt_1s == (ONE_SEC - 1)) 
        begin
          cnt_1s   <= 0;
          clk_1hz_fp <= 1'b1;        
        end
      else 
        begin
          cnt_1s   <= cnt_1s + 1;
          clk_1hz_fp <= 1'b0;
        end
    end

        // always_ff @(posedge rst,posedge clk) begin: p_misc2
        always_ff @(posedge clk) begin: p_misc2
        if (rst) begin
            pwrcyc_wait_timer   <= 16'd3;
            pwrcyc_en_d         <= '0;
            pwrcyc_cnt4_1hz     <= '0;
            pwrcyc_1hz_fp       <= 1'b0;
            zynq_power_cycle_en <= 1'b1;

            warmrst_wait_timer  <= 16'd3;
            warmrst_en_d        <= '0;
            warmrst_cnt4_1hz    <= '0;
            warmrst_1hz_fp      <= 1'b0;
            warmrst_pls_cnt     <= '1;
            warm_reset_out_t       <= 1'b1;
        end else begin
            //pwr_cyc
            if (enable_cold_boot)
                pwrcyc_wait_timer <= 16'd10;
            else if (pwrcyc_1hz_fp)
            // else if (clk_1hz_fp )
                pwrcyc_wait_timer <= pwrcyc_wait_timer - 1;

            if (~(|pwrcyc_wait_timer))
                pwrcyc_en_d[0] <= 1'b0;
            else if (enable_cold_boot)
                pwrcyc_en_d[0] <= 1'b1;

            pwrcyc_en_d[1] <= pwrcyc_en_d[0];

            pwrcyc_1hz_fp <= 1'b0;
            if (pwrcyc_en_d[0]) begin
                if (clk_10hz_fp) begin
                    pwrcyc_cnt4_1hz <= pwrcyc_cnt4_1hz + 1;
                    if (pwrcyc_cnt4_1hz==9) begin
                        pwrcyc_cnt4_1hz  <= '0;
                        pwrcyc_1hz_fp   <= 1'b1;
                    end
                end
            end else
                pwrcyc_cnt4_1hz <= '0;

            if (pwrcyc_en_d[1:0]==2'b10)
                zynq_power_cycle_en <= 1'b0;

            //warm_rst
            if (enable_warm_boot)
                warmrst_wait_timer <= 16'd20;
            else if (warmrst_1hz_fp)
                warmrst_wait_timer <= warmrst_wait_timer - 1;

            if (~(|warmrst_wait_timer))
                warmrst_en_d[0] <= 1'b0;
            else if (enable_warm_boot)
                warmrst_en_d[0] <= 1'b1;

            warmrst_en_d[1] <= warmrst_en_d[0];

            warmrst_1hz_fp <= 1'b0;
            if (warmrst_en_d[0]) begin
                if (clk_10hz_fp) begin
                    warmrst_cnt4_1hz <= warmrst_cnt4_1hz + 1;
                    if (warmrst_cnt4_1hz==9) begin
                        warmrst_cnt4_1hz <= '0;
                        warmrst_1hz_fp   <= 1'b1;
                    end
                end
            end else
                warmrst_cnt4_1hz <= '0;

            if (warmrst_en_d[1:0]==2'b10)
                warmrst_pls_cnt <= '0;
            else if (~(&warmrst_pls_cnt))
                warmrst_pls_cnt <= warmrst_pls_cnt + 1;

            if (warmrst_en_d[1:0]==2'b10)
                warm_reset_out_t <= 1'b0;
            else if (&warmrst_pls_cnt)
                warm_reset_out_t <= 1'b1;
        end
    end

    assign  warm_reset_out = warm_reset_out_t ? 1'bz : 1'b0;



    ///////////////////////////////////////////////////////////////
    // Watchdog
    ///////////////////////////////////////////////////////////////


always_ff @(posedge clk) begin

    if (rst) begin
        wdg_tmout_val <= 12'h10;
        wdg_timer <= 12'h10;
        wdg_tmout <= 0;
        wdg_pls_tmout <= 0;
        wdg_pls_wdth  <= 8'h3;
        wdg_pls_timer <= 8'h3;
        wdg_pls_n <= 1'b1;
    end else if (clk_1hz_fp & wdg_en)
        wdg_timer <= wdg_timer - 1;
        
        if (wdg_kick) begin
            wdg_timer <= wdg_tmout_val;
       end

        if (wdg_timer==0) begin
            wdg_tmout <= 1'b1;
        end
        
        if ( wdg_tmout) begin
			wdg_pls_n <= 1'b0;
			wdg_timer <= wdg_tmout_val;
		end
        
        if (wdg_pls_n)
            wdg_pls_timer <= wdg_pls_wdth;
        else begin 
            wdg_pls_tmout <= 0;
        if (clk_1hz_fp)
            wdg_pls_timer <= wdg_pls_timer - 1;

        end 
                
        if (wdg_pls_timer==0) begin
            wdg_pls_tmout <= 1'b1;
            wdg_pls_timer <= wdg_pls_wdth;
            wdg_tmout <= 1'b0;
            wdg_pls_n <= 1'b1;
        end

end

    assign zynq_wdog_timeout = wdg_pls_n ? 1'b1 : 1'b0;

endmodule

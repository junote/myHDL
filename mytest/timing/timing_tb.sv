module timing_tb;

    //input   
    bit                 clk_125m                    ;
    bit [2:1]           fpga_refclk_tx              ;
    bit [2:1]           mate_refclk_rx              ;
    bit                 synce_clk_ctrla_sled        ;
    bit                 synce_clk_ctrlb_sled        ;
    bit                 bp_mate_synce_clk_rx_1v8    ;
    bit                 bits_rx_clk_1v8             ;
    bit [3:0]           osc_recov_clk               ;
    bit [9:0]           ref_en                      ;
    bit [9:0]   [3:0]   ref_sel                     ;    
    //output
    bit                 clk_en_20m83                ;
    bit                 clk_en_20m83_d              ;
    bit                 clk_en_2m36                 ;
    bit                 clk_1k                      ;
    bit                 clk_1k_fp                   ;
    bit                 clk_10hz_fp                 ;
    bit                 clk_1hz                     ;
    bit [2:1]           fpga_refclk_rx              ;
    bit [2:1]           mate_refclk_tx              ;
    bit [2:1]           refclk_a                    ;
    bit [2:1]           refclk_b                    ;
    bit                 bp_mate_synce_clk_tx_1v8    ;
    bit                 bits_tx_clk_1v8             ;
    bit [10:0]          clk_loss;


    // initial begin
    //     $dumpfile("wave.vcd");
    //     $dumpvars(0,timing_tb);
    // end

    initial begin 
        ref_en = 10'h3ff;
        ref_sel[0] = 10'h1;
        ref_sel[1] = 10'h2;
        ref_sel[2] = 10'h4;
        ref_sel[3] = 10'h8;
        #10000 $finish;
    end

    always #4 clk_125m <= ~clk_125m;
    always #100 fpga_refclk_tx[1] <= ~fpga_refclk_tx[1];
    always #100 fpga_refclk_tx[2] <= ~fpga_refclk_tx[2];
    always #100 mate_refclk_rx[1] <= ~mate_refclk_rx[1];
    always #100 mate_refclk_rx[2] <= ~mate_refclk_rx[2];
    
    always #100 synce_clk_ctrla_sled<= ~synce_clk_ctrla_sled;
    always #100 synce_clk_ctrlb_sled <= 0;
    always #100 mate_refclk_rx[1] <= ~mate_refclk_rx[1];
    always #1000 bp_mate_synce_clk_rx_1v8 <= ~bp_mate_synce_clk_rx_1v8;
    

        always #100 osc_recov_clk[0] <= ~osc_recov_clk[0];
        always #100 osc_recov_clk[1] <= ~osc_recov_clk[1];
        always #100 osc_recov_clk[2] <= ~osc_recov_clk[2];
        always #100 osc_recov_clk[3] <= ~osc_recov_clk[3];



    timing u_timing(.*);

endmodule
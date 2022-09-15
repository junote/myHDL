module spi_ctrl_tb;
    import spi_pkg::*;
    
    //input clk
    bit                     clk         ;
    bit                     clk_en      ;
    bit                     clk_1k_fp   ;
    
    // spi pin
    bit                     spi_csn     ;
    bit                     spi_clk     ;
    bit                     spi_mosi    ;
    bit                     spi_miso    ;

    //polarity; phase
    bit                     r_spi_cpol  ;
    bit                     r_spi_cpha  ;

    //control pkg
    t_spi_if_ro             spi_ifi_ro  ;
    t_spi_if_ri             spi_ifi_ri  ;



    always #4 clk <= ~clk;
    always #27 clk_en <= ~clk_en;
    always #50 clk_1k_fp <= ~clk_1k_fp;

    initial begin
        r_spi_cpha = 0;
        r_spi_cpol = 0;

        // spi_ifi_ro.rdata_en = 0;
        // spi_ifi_ro.slv_sel  = 2'b00;
        // spi_ifi_ro.wd_len   = 2'b11;
        // spi_ifi_ro.wd_lst = 1'b1;
        spi_ifi_ro.rwdata = 32'haaaaaaaa;


        // spi_ifi_ro. strt = 1'b1;
        // #2000
        spi_ifi_ro.rdata_en = 1'b1;
        spi_ifi_ro.wd_empty = 1'b0;
        spi_ifi_ro.slv_sel  = 2'b00;
        spi_ifi_ro.wd_lst = 1'b1;
        spi_ifi_ro.rd_len = 2'b11;
        spi_ifi_ro.rd_lst = 1'b1;
        spi_ifi_ro. strt = 1'b1;

        // #10000 $finish;

    end

 
    spi_ctrl spi_ctrl_u(clk,clk_en,clk_1k_fp,
                        spi_csn,spi_clk,spi_mosi,spi_miso,
                        r_spi_cpha,r_spi_cpol,
                        spi_ifi_ro,spi_ifi_ri);
endmodule
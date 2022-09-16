package i2c_pkg;
    typedef struct packed {
        bit         rwn                 ;
        bit [7:1]   slv_addr            ;
        bit         s_en                ;
        bit         aw_en               ;
        bit         ptr_en              ;
        bit         p1_en               ;
        bit         sr_en               ;
        bit         ar_en               ;
        bit         rw_en               ;
        bit         p2_en               ;
        bit         int_en              ;

        bit [31:0]  ptr                 ;
        bit [31:0]  rwdata              ;

        bit [1:0]   ptr_len             ;
        bit         ptr_lst             ;
        bit         ptr_empty           ;

        bit [1:0]   wd_len              ;
        bit         wd_lst              ;
        bit         wd_empty            ;

        bit [1:0]   rd_len              ;
        bit         rd_lst              ;
        bit         rd_inf_empty        ;

        bit         rd_rdy              ;
        bit         strt                ;
    } t_i2c_if_ro;

    typedef struct packed {
        bit [31:0]  rdata               ;
        bit         rd_ind              ;

        bit         ptr_r               ;
        bit         wd_r                ;
        bit         rd_inf_r            ;

        bit         scl_stretch_timeout ;
        bit         sda_stretch         ;
        bit         dev_nack            ;
        bit         prt_nack            ;
        bit         data_nack           ;
        bit         ptr_timeout         ;
        bit         wdat_timeout        ;
        bit         rd_inf_timeout      ;
        bit         rdat_timeout        ;

        bit         cur_scl             ;
        bit         cur_sda             ;
        bit         i2c_busy            ;

        bit         done                ;
    } t_i2c_if_ri;
endpackage

package spi_pkg;
    typedef struct packed {
        bit         rdata_en        ;
        bit [1:0]   slv_sel         ;

        bit [1:0]   wd_len          ;
        bit         wd_lst          ;
        bit         wd_empty        ;

        bit [31:0]  rwdata          ;

        bit [1:0]   rd_len          ;
        bit         rd_lst          ;
        bit         rd_inf_empty    ;

        bit         rd_rdy          ;
        bit         strt            ;
    } t_spi_if_ro;

    typedef struct packed {
        bit [31:0]  rdata           ;
        bit         rd_ind          ;

        bit         wd_r            ;
        bit         rd_inf_r        ;

        bit         wdat_timeout    ;
        bit         rd_inf_timeout  ;
        bit         rdat_timeout    ;

        bit         done            ;
    } t_spi_if_ri;
endpackage

package crc_pkg;

    // polynomial: x^16 + x^12 + x^5 + 1
    // data width: 16
    // convention: the first serial bit is d[15]
    function [15:0] nextcrc16_d16;

        input [15:0] data;
        input [15:0] crc;
        reg [15:0] d;
        reg [15:0] c;
        reg [15:0] newcrc;
    begin
        d = data;
        c = crc;

        newcrc[0] = d[12] ^ d[11] ^ d[8] ^ d[4] ^ d[0] ^ c[0] ^ c[4] ^ c[8] ^ c[11] ^ c[12];
        newcrc[1] = d[13] ^ d[12] ^ d[9] ^ d[5] ^ d[1] ^ c[1] ^ c[5] ^ c[9] ^ c[12] ^ c[13];
        newcrc[2] = d[14] ^ d[13] ^ d[10] ^ d[6] ^ d[2] ^ c[2] ^ c[6] ^ c[10] ^ c[13] ^ c[14];
        newcrc[3] = d[15] ^ d[14] ^ d[11] ^ d[7] ^ d[3] ^ c[3] ^ c[7] ^ c[11] ^ c[14] ^ c[15];
        newcrc[4] = d[15] ^ d[12] ^ d[8] ^ d[4] ^ c[4] ^ c[8] ^ c[12] ^ c[15];
        newcrc[5] = d[13] ^ d[12] ^ d[11] ^ d[9] ^ d[8] ^ d[5] ^ d[4] ^ d[0] ^ c[0] ^ c[4] ^ c[5] ^ c[8] ^ c[9] ^ c[11] ^ c[12] ^ c[13];
        newcrc[6] = d[14] ^ d[13] ^ d[12] ^ d[10] ^ d[9] ^ d[6] ^ d[5] ^ d[1] ^ c[1] ^ c[5] ^ c[6] ^ c[9] ^ c[10] ^ c[12] ^ c[13] ^ c[14];
        newcrc[7] = d[15] ^ d[14] ^ d[13] ^ d[11] ^ d[10] ^ d[7] ^ d[6] ^ d[2] ^ c[2] ^ c[6] ^ c[7] ^ c[10] ^ c[11] ^ c[13] ^ c[14] ^ c[15];
        newcrc[8] = d[15] ^ d[14] ^ d[12] ^ d[11] ^ d[8] ^ d[7] ^ d[3] ^ c[3] ^ c[7] ^ c[8] ^ c[11] ^ c[12] ^ c[14] ^ c[15];
        newcrc[9] = d[15] ^ d[13] ^ d[12] ^ d[9] ^ d[8] ^ d[4] ^ c[4] ^ c[8] ^ c[9] ^ c[12] ^ c[13] ^ c[15];
        newcrc[10] = d[14] ^ d[13] ^ d[10] ^ d[9] ^ d[5] ^ c[5] ^ c[9] ^ c[10] ^ c[13] ^ c[14];
        newcrc[11] = d[15] ^ d[14] ^ d[11] ^ d[10] ^ d[6] ^ c[6] ^ c[10] ^ c[11] ^ c[14] ^ c[15];
        newcrc[12] = d[15] ^ d[8] ^ d[7] ^ d[4] ^ d[0] ^ c[0] ^ c[4] ^ c[7] ^ c[8] ^ c[15];
        newcrc[13] = d[9] ^ d[8] ^ d[5] ^ d[1] ^ c[1] ^ c[5] ^ c[8] ^ c[9];
        newcrc[14] = d[10] ^ d[9] ^ d[6] ^ d[2] ^ c[2] ^ c[6] ^ c[9] ^ c[10];
        newcrc[15] = d[11] ^ d[10] ^ d[7] ^ d[3] ^ c[3] ^ c[7] ^ c[10] ^ c[11];
        nextcrc16_d16 = newcrc;
    end
    endfunction

    function bit [15:0] switch_byte;
        input bit [15:0] din;

        switch_byte = {din[7:0],din[15:8]};
    endfunction

endpackage
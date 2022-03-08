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

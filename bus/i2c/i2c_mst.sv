`define  DUTY_1_3
module i2c_mst
    import i2c_pkg::*;
    #(
    parameter
        T_CK        = 8         ,   //unit ns
        T_CK_EN     = 0.4166    ,   //unit us
        TBUF        = 20            //unit us
    ) (
        input   bit         rst         ,
        input   bit         clk         ,
        input   bit         clk_en      ,
        input   bit         clk_1k_fp   ,

        input   t_i2c_if_ro i2c_ifi_ro  ,
        output  t_i2c_if_ri i2c_ifi_ri  ,

        input   bit         scl_i       ,
        input   bit         sda_i       ,

        output  bit         scl_oen     ,
        output  bit         sda_oen
    );

    localparam  int FILT_NUM    = $ceil(50/T_CK)        ,
                    LOG2_FLT    = $clog2(FILT_NUM)      ,
                    TBUF_NUM    = $ceil(TBUF/T_CK_EN)   ,
                    LOG2_TBUF   = $clog2(TBUF_NUM)      ;

    enum bit [2:0]  {BIT_IDLE='h0,BIT_NOP='h1,BIT_I_STA='h2,BIT_N_STA_1='h3,BIT_N_STA_2='h4,BIT_WR='h5,BIT_RD='h6,BIT_STO='h7} bit_state,bit_cmd;

    enum bit [4:0]  {USR_IDLE='h0,USR_S='h1,USR_S_END='h2,USR_AW='h3,
                     USR_AW_A='h4,USR_AW_END='h5,USR_PTR_GET='h6,USR_PTR='h7,
                     USR_PTR_A='h8,USR_PTR_END='h9,USR_P1='ha,USR_P1_END='hb,
                     USR_SR='hc,USR_SR_END='hd,USR_AR='he,USR_AR_A='hf,
                     USR_AR_END='h10,USR_WR_GET='h11,USR_WR='h12,USR_WR_A='h13,
                     USR_WR_END='h14,USR_RD_WAIT_INF='h15,USR_RD='h16,USR_RD_A='h17,
                     USR_RD_WAIT_BUF='h18,USR_RD_END='h19,USR_P2='h1a,USR_P2_END='h1b} usr_state;

    bit                 clk_en_i;

    bit [FILT_NUM+2:1]  scl_oen_d;
    bit [FILT_NUM+2:1]  sda_oen_d;

    bit [2:1]           scl_i_d;
    bit [2:1]           sda_i_d;

    bit [LOG2_FLT-1:0]  scl_i_filt_cnt;
    bit                 scl_i_filt;

    bit [LOG2_FLT-1:0]  sda_i_filt_cnt;
    bit                 sda_i_filt;

    bit                 scl_stretch_c;
    bit                 sda_stretch_c;

    bit [2:0]           cnt_stretch;
    bit                 scl_stretch_timeout;

    bit                 sda_stretch_evt;

    bit [LOG2_TBUF-1:0] tbuf_cnt;

`ifdef DUTY_1_3
    bit [2:0]   bit_phase;
`else
    bit [1:0]   bit_phase;
`endif
    bit         bit_txd;
    bit         bit_rxd;
    bit         bit_done;

    bit [2:0]   bit_cnt;
    bit [1:0]   byte_cnt;

    bit [31:0]  shft_reg;
    bit         burst_is_last;
    bit [1:0]   valid_len;

    bit [3:0]   burst_wait_cnt;

    assign  scl_stretch_c = ~scl_i_filt & scl_oen_d[FILT_NUM+2];
    assign  sda_stretch_c = ~sda_i_filt & sda_oen_d[FILT_NUM+2];

    always_ff @(posedge clk) begin: p_sync_filt
        scl_oen_d   <= {scl_oen_d[FILT_NUM+1:1],scl_oen};
        sda_oen_d   <= {sda_oen_d[FILT_NUM+1:1],sda_oen};
        scl_i_d     <= {scl_i_d[1],scl_i};
        sda_i_d     <= {sda_i_d[1],sda_i};

        if (sda_i_filt == sda_i_d[2] | sda_i_filt_cnt == FILT_NUM-1)
            sda_i_filt_cnt <= 'b0;
        else
            sda_i_filt_cnt <= sda_i_filt_cnt + 1;

        if (sda_i_filt_cnt == FILT_NUM-1)
            sda_i_filt <= sda_i_d[2];

        if (scl_i_filt == scl_i_d[2] | scl_i_filt_cnt == FILT_NUM-1)
            scl_i_filt_cnt <= 'b0;
        else
            scl_i_filt_cnt <= scl_i_filt_cnt + 1;

        if (scl_i_filt_cnt == FILT_NUM-1)
            scl_i_filt <= scl_i_d[2];
    end

    always_ff @(posedge clk) begin: p_stretch
        clk_en_i <= clk_en & ~scl_stretch_c;

        if (scl_stretch_c) begin
            if (clk_1k_fp & ~(& cnt_stretch))    // >=6ms
                cnt_stretch <= cnt_stretch + 1;
        end else
            cnt_stretch <= 'b0;

        scl_stretch_timeout <= & cnt_stretch;
    end

    assign  i2c_ifi_ri.cur_scl             = scl_i_filt;
    assign  i2c_ifi_ri.cur_sda             = sda_i_filt;
    assign  i2c_ifi_ri.scl_stretch_timeout = scl_stretch_timeout;

    always_ff @(posedge clk) begin: p_bit_fsm
        if (scl_stretch_timeout) begin
            unique case (bit_state)
                BIT_IDLE,BIT_I_STA
                            :   bit_state <= BIT_IDLE;
                default     :   bit_state <= BIT_NOP;
            endcase
        end else if (clk_en_i) begin
            unique case (bit_state)
                BIT_IDLE    :   if (bit_cmd == BIT_N_STA_1 && tbuf_cnt==TBUF_NUM-1)
                                    bit_state <= BIT_I_STA;
                BIT_I_STA   :   `ifdef DUTY_1_3
                                    if (bit_phase[2] & bit_phase[0])
                                `else
                                    if (bit_phase[1])
                                `endif
                                    bit_state <= BIT_NOP;
                BIT_WR,BIT_RD
                            :   `ifdef DUTY_1_3
                                    if (bit_phase[2])
                                `else
                                    if (bit_phase[1])
                                `endif
                                    bit_state <= BIT_NOP;

                BIT_N_STA_1 :   `ifdef DUTY_1_3
                                    if (bit_phase[2])
                                `else
                                    if (bit_phase[1])
                                `endif
                                    bit_state <= BIT_N_STA_2;
                BIT_N_STA_2 :   `ifdef DUTY_1_3
                                    if (~bit_phase[2])
                                `else
                                    if (~bit_phase[1])
                                `endif
                                    bit_state <= BIT_NOP;
                BIT_STO     :   `ifdef DUTY_1_3
                                    if (&bit_phase[2:1])
                                `else
                                    if (&bit_phase[1:0])
                                `endif
                                    bit_state <= BIT_IDLE;
                BIT_NOP     :   unique case (bit_cmd)
                                    BIT_N_STA_1 :   if (tbuf_cnt==TBUF_NUM-1)
                                                        bit_state <= bit_cmd;
                                    BIT_WR,BIT_RD,BIT_STO
                                                :   bit_state <= bit_cmd;
                                    default     :   bit_state <= BIT_NOP;
                                endcase
            endcase

            bit_phase <= bit_phase + 1;
            if (bit_state == BIT_IDLE | bit_state == BIT_NOP)
                bit_phase <= 'b0;

            if (bit_state == BIT_RD)
                `ifdef DUTY_1_3
                    if (bit_phase[2])
                `else
                    if (bit_phase[1])
                `endif
                    bit_rxd <= sda_i_filt;
        end

        unique case (bit_state)
            BIT_IDLE,BIT_NOP
                        :   if (clk_en_i)
                                if (tbuf_cnt!=TBUF_NUM-1)
                                    tbuf_cnt <= tbuf_cnt + 1;
            default     :   tbuf_cnt <= 'b0;
        endcase

        if (rst) begin
            scl_oen         <= 1'b1;
            sda_oen         <= 1'b1;
            sda_stretch_evt <= 1'b0;
        end else if (clk_en_i) begin
            unique case (bit_state)
                BIT_IDLE    :   scl_oen <= 1'b1;
                BIT_NOP     :   scl_oen <= 1'b0;
                BIT_I_STA   :   `ifdef DUTY_1_3
                                    scl_oen <= ~(bit_phase[2]&bit_phase[0]);
                                `else
                                    scl_oen <= 1'b1;
                                `endif
                BIT_WR,BIT_RD
                            :   `ifdef DUTY_1_3
                                    scl_oen <= bit_phase[1];
                                `else
                                    scl_oen <= ^bit_phase[1:0];
                                `endif
                BIT_N_STA_1 :   `ifdef DUTY_1_3
                                    scl_oen <= |bit_phase[2:1];
                                `else
                                    scl_oen <= ^bit_phase[1:0];
                                `endif
                BIT_N_STA_2 :   `ifdef DUTY_1_3
                                    scl_oen <= bit_phase[2];
                                `else
                                    scl_oen <= 1'b1;
                                `endif
                BIT_STO     :   `ifdef DUTY_1_3
                                    scl_oen <= |bit_phase[2:1];
                                `else
                                    scl_oen <= |bit_phase[1:0];
                                `endif
            endcase

            unique case (bit_state)
                BIT_I_STA   :   `ifdef DUTY_1_3
                                    sda_oen <= ~(|bit_phase[2:1]);
                                `else
                                    sda_oen <= ~(|bit_phase[1:0]);
                                `endif
                BIT_N_STA_2 :   sda_oen <= 1'b0;
                BIT_STO     :   `ifdef DUTY_1_3
                                    sda_oen <= bit_phase[2] & (|bit_phase[1:0]);
                                `else
                                    sda_oen <= &bit_phase[1:0];
                                `endif
                BIT_WR      :   sda_oen <= bit_txd;
                BIT_NOP     :   sda_oen <= sda_oen;
                default     :   sda_oen <= 1'b1;    //  BIT_N_STA_1,BIT_IDLE,BIT_RD
            endcase

            unique case (bit_state)
                BIT_I_STA,BIT_WR,BIT_N_STA_1,BIT_STO
                            :   if (sda_stretch_c)
                                    sda_stretch_evt <= 1'b1;
                BIT_N_STA_2 :   ;
                default     :   sda_stretch_evt <= 1'b0;
            endcase
        end

        bit_done <= 1'b0;
        if (clk_en_i)
            unique case (bit_state)
                BIT_IDLE    :   unique case (bit_cmd)
                                    BIT_NOP,BIT_N_STA_1
                                            :   bit_done <= 1'b0;
                                    default :   bit_done <= 1'b1;   //for wrong cmd
                                endcase
                BIT_I_STA   :   `ifdef DUTY_1_3
                                    bit_done <= bit_phase[2] & bit_phase[0];
                                `else
                                    bit_done <= bit_phase[1];
                                `endif
                BIT_WR,BIT_RD
                            :   `ifdef DUTY_1_3
                                    bit_done <= bit_phase[2];
                                `else
                                    bit_done <= bit_phase[1];
                                `endif
                BIT_N_STA_2 :   `ifdef DUTY_1_3
                                    bit_done <= ~bit_phase[2];
                                `else
                                    bit_done <= ~bit_phase[1];
                                `endif
                BIT_STO     :   `ifdef DUTY_1_3
                                    bit_done <= &bit_phase[2:1];
                                `else
                                    bit_done <= &bit_phase[1:0];
                                `endif
                default     :   bit_done <= 1'b0;
            endcase

        i2c_ifi_ri.sda_stretch <= 1'b0;
        if (bit_done & sda_stretch_evt)
            i2c_ifi_ri.sda_stretch <= 1'b1;

        i2c_ifi_ri.i2c_busy <= 1'b1;
        if (bit_state == BIT_IDLE)
            i2c_ifi_ri.i2c_busy <= 1'b0;
    end

    always_ff @(posedge clk) begin: p_usr_fsm
        unique case (usr_state)
            USR_IDLE        :   if (~scl_stretch_timeout & i2c_ifi_ro.strt)
                                    if (i2c_ifi_ro.s_en)
                                        usr_state <= USR_S;
                                    else
                                        usr_state <= USR_S_END;
            USR_S_END       :   if (i2c_ifi_ro.aw_en)
                                    usr_state <= USR_AW;
                                else
                                    usr_state <= USR_AW_END;
            USR_AW_END      :   if (i2c_ifi_ro.ptr_en)
                                    usr_state <= USR_PTR_GET;
                                else
                                    usr_state <= USR_PTR_END;
            USR_PTR_GET     :   if (~i2c_ifi_ro.ptr_empty)
                                    usr_state <= USR_PTR;
                                else if (& burst_wait_cnt)
                                    usr_state <= USR_PTR_END;
            USR_PTR_END     :   if (i2c_ifi_ro.p1_en)
                                    usr_state <= USR_P1;
                                else
                                    usr_state <= USR_P1_END;
            USR_P1_END      :   if (i2c_ifi_ro.sr_en)
                                    usr_state <= USR_SR;
                                else
                                    usr_state <= USR_SR_END;
            USR_SR_END      :   if (i2c_ifi_ro.ar_en)
                                    usr_state <= USR_AR;
                                else
                                    usr_state <= USR_AR_END;
            USR_AR_END      :   if (i2c_ifi_ro.rw_en) begin
                                    if (i2c_ifi_ro.rwn)
                                        usr_state <= USR_RD_WAIT_INF;
                                    else
                                        usr_state <= USR_WR_GET;
                                end else
                                    usr_state <= USR_WR_END;
            USR_RD_WAIT_INF :   if (~i2c_ifi_ro.rd_inf_empty)
                                    usr_state <= USR_RD;
                                else if (& burst_wait_cnt)
                                    usr_state <= USR_RD_END;
            USR_RD_WAIT_BUF :   if (~i2c_ifi_ro.rd_rdy) begin
                                    if (burst_is_last)
                                        usr_state <= USR_RD_END;
                                    else
                                        usr_state <= USR_RD_WAIT_INF;
                                end else if (& burst_wait_cnt)
                                    usr_state <= USR_RD_END;
            USR_RD_END      :   if (i2c_ifi_ro.p2_en)
                                    usr_state <= USR_P2;
                                else
                                    usr_state <= USR_P2_END;
            USR_WR_GET      :   if (~i2c_ifi_ro.wd_empty)
                                    usr_state <= USR_WR;
                                else if (& burst_wait_cnt)
                                    usr_state <= USR_WR_END;
            USR_WR_END      :   if (i2c_ifi_ro.p2_en)
                                    usr_state <= USR_P2;
                                else
                                    usr_state <= USR_P2_END;
            USR_P2_END      :   if (~i2c_ifi_ro.strt)
                                    usr_state <= USR_IDLE;
            default         :   if (scl_stretch_timeout)
                                    usr_state <= USR_P2_END;
                                else if (bit_done)
                                    unique case (usr_state)
                                        USR_S       :   usr_state <= USR_S_END;
                                        USR_AW      :   if (& bit_cnt)
                                                            usr_state <= USR_AW_A;
                                        USR_AW_A    :   usr_state <= USR_AW_END;
                                        USR_PTR     :   if (& bit_cnt)
                                                            usr_state <= USR_PTR_A;
                                        USR_PTR_A   :   if (byte_cnt==valid_len) begin
                                                            if (burst_is_last)
                                                                usr_state <= USR_PTR_END;
                                                            else
                                                                usr_state <= USR_PTR_GET;
                                                        end else
                                                            usr_state <= USR_PTR;
                                        USR_P1      :   usr_state <= USR_P1_END;
                                        USR_SR      :   usr_state <= USR_SR_END;
                                        USR_AR      :   if (& bit_cnt)
                                                            usr_state <= USR_AR_A;
                                        USR_AR_A    :   usr_state <= USR_AR_END;
                                        USR_RD      :   if (& bit_cnt)
                                                            usr_state <= USR_RD_A;
                                        USR_RD_A    :   if (byte_cnt==valid_len)
                                                            usr_state <= USR_RD_WAIT_BUF;
                                                        else
                                                            usr_state <= USR_RD;
                                        USR_WR      :   if (& bit_cnt)
                                                            usr_state <= USR_WR_A;
                                        USR_WR_A    :   if (byte_cnt==valid_len) begin
                                                            if (burst_is_last)
                                                                usr_state <= USR_WR_END;
                                                            else
                                                                usr_state <= USR_WR_GET;
                                                        end else
                                                            usr_state <= USR_WR;
                                        default     :   usr_state <= USR_P2_END;    //USR_P2
                                    endcase
        endcase

        unique case (usr_state)
            USR_S,USR_SR
                    :   bit_cmd <= BIT_N_STA_1;
            USR_AW,USR_PTR,USR_AR,USR_WR,USR_RD_A
                    :   bit_cmd <= BIT_WR;
            USR_AW_A,USR_PTR_A,USR_AR_A,USR_WR_A,USR_RD
                    :   bit_cmd <= BIT_RD;
            USR_P1,USR_P2
                    :   bit_cmd <= BIT_STO;
            default :   bit_cmd <= BIT_NOP;
        endcase

        i2c_ifi_ri.dev_nack <= 1'b0;
        if (usr_state==USR_AW_A || usr_state==USR_AR_A)
            i2c_ifi_ri.dev_nack <= bit_done & bit_rxd;

        i2c_ifi_ri.prt_nack <= 1'b0;
        if (usr_state==USR_PTR_A)
            i2c_ifi_ri.prt_nack <= bit_done & bit_rxd;

        i2c_ifi_ri.data_nack <= 1'b0;
        if (usr_state==USR_WR_A)
            i2c_ifi_ri.data_nack <= bit_done & bit_rxd;

        unique case (usr_state)
            USR_AW,USR_PTR,USR_AR,USR_RD,USR_WR
                    :   if (bit_done)
                            bit_cnt <= bit_cnt + 1;
            default :   bit_cnt <= 'b0;
        endcase

        unique case (usr_state)
            USR_PTR_A,USR_WR_A,USR_RD_A
                        :   if (bit_done)
                                byte_cnt <= byte_cnt + 1;
            USR_PTR,USR_WR,USR_RD
                        :   ;
            default     :   byte_cnt <= 'b0;
        endcase

        unique case (usr_state)
            USR_S_END       :   shft_reg[31:24] <= {i2c_ifi_ro.slv_addr,1'b0};
            USR_AW,USR_AR   :   if (bit_done)
                                    shft_reg[31:25] <= shft_reg[30:24];
            USR_PTR         :   if (i2c_ifi_ri.ptr_r)
                                    unique case(valid_len)
                                        2'h0    :   shft_reg <= {i2c_ifi_ro.ptr[7:0],24'h0};
                                        2'h1    :   shft_reg <= {i2c_ifi_ro.ptr[15:0],16'h0};
                                        2'h2    :   shft_reg <= {i2c_ifi_ro.ptr[23:0],8'h0};
                                        default :   shft_reg <= i2c_ifi_ro.ptr;
                                    endcase
                                else if (bit_done)
                                    shft_reg[31:1] <= shft_reg[30:0];
            USR_P1_END      :   shft_reg[31:24] <= {i2c_ifi_ro.slv_addr,1'b1};
            USR_WR          :   if (i2c_ifi_ri.wd_r)
                                    unique case(valid_len)
                                        2'h0    :   shft_reg <= {i2c_ifi_ro.rwdata[7:0],24'h0};
                                        2'h1    :   shft_reg <= {i2c_ifi_ro.rwdata[15:0],16'h0};
                                        2'h2    :   shft_reg <= {i2c_ifi_ro.rwdata[23:0],8'h0};
                                        default :   shft_reg <= i2c_ifi_ro.rwdata;
                                    endcase
                                else if (bit_done)
                                    shft_reg[31:1] <= shft_reg[30:0];
            USR_RD_WAIT_INF :   if (~i2c_ifi_ro.rd_inf_empty)
                                    shft_reg <= 'b0;
            USR_RD          :   if (bit_done)
                                    shft_reg <= {shft_reg[30:0],bit_rxd};
            default         :   ;
        endcase

        if (usr_state==USR_RD_A) begin
            if (burst_is_last & (byte_cnt==valid_len))
                bit_txd <= 1'b1;
            else
                bit_txd <= 1'b0;
        end else
            bit_txd <= shft_reg[31];

        unique case (usr_state)
            USR_PTR_GET     :   if (~i2c_ifi_ro.ptr_empty) begin
                                    burst_is_last <= i2c_ifi_ro.ptr_lst;
                                    valid_len     <= i2c_ifi_ro.ptr_len;
                                end
            USR_WR_GET      :   if (~i2c_ifi_ro.wd_empty) begin
                                    burst_is_last <= i2c_ifi_ro.wd_lst;
                                    valid_len     <= i2c_ifi_ro.wd_len;
                                end
            USR_RD_WAIT_INF :   if (~i2c_ifi_ro.rd_inf_empty) begin
                                    burst_is_last <= i2c_ifi_ro.rd_lst;
                                    valid_len     <= i2c_ifi_ro.rd_len;
                                end
            default         :   ;
        endcase

        i2c_ifi_ri.ptr_r <= 1'b0;
        if (usr_state==USR_PTR_GET)
            i2c_ifi_ri.ptr_r <= ~i2c_ifi_ro.ptr_empty;

        i2c_ifi_ri.wd_r <= 1'b0;
        if (usr_state==USR_WR_GET)
            i2c_ifi_ri.wd_r <= ~i2c_ifi_ro.wd_empty;

        i2c_ifi_ri.rd_inf_r <= 1'b0;
        if (usr_state==USR_RD_WAIT_INF)
            i2c_ifi_ri.rd_inf_r <= ~ i2c_ifi_ro.rd_inf_empty;

        i2c_ifi_ri.rd_ind <= 1'b0;
        if (usr_state==USR_RD_WAIT_BUF)
            if (~i2c_ifi_ro.rd_rdy) begin
                i2c_ifi_ri.rd_ind   <= 1'b1;
                i2c_ifi_ri.rdata    <= shft_reg;
            end

        unique case (usr_state)
            USR_PTR_GET,USR_WR_GET,USR_RD_WAIT_INF,USR_RD_WAIT_BUF
                        :   if (clk_1k_fp)
                                if (~(& burst_wait_cnt))
                                    burst_wait_cnt <= burst_wait_cnt + 1;   // >=15ms
            default     :   burst_wait_cnt <= 'b0;
        endcase

        i2c_ifi_ri.ptr_timeout <= 1'b0;
        if (usr_state==USR_PTR_GET)
            i2c_ifi_ri.ptr_timeout <= i2c_ifi_ro.ptr_empty & (& burst_wait_cnt);

        i2c_ifi_ri.wdat_timeout <= 1'b0;
        if (usr_state==USR_WR_GET)
            i2c_ifi_ri.wdat_timeout <= i2c_ifi_ro.wd_empty & (& burst_wait_cnt);

        i2c_ifi_ri.rd_inf_timeout <= 1'b0;
        if (usr_state==USR_RD_WAIT_INF)
            i2c_ifi_ri.rd_inf_timeout <= i2c_ifi_ro.rd_inf_empty & (& burst_wait_cnt);

        i2c_ifi_ri.rdat_timeout <= 1'b0;
        if (usr_state==USR_RD_WAIT_BUF)
            i2c_ifi_ri.rdat_timeout <= i2c_ifi_ro.rd_rdy & (& burst_wait_cnt);

        i2c_ifi_ri.done <= 1'b0;
        if (usr_state==USR_P2_END)
            i2c_ifi_ri.done <= 1'b1;
    end

endmodule
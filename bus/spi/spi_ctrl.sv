module spi_ctrl
    import spi_pkg::*;
    #(
        parameter SLV_NUM = 1
    ) (
    input   bit                     clk         ,
    input   bit                     clk_en      ,
    input   bit                     clk_1k_fp   ,

    output  bit     [SLV_NUM-1:0]   spi_csn     ,
    output  bit     [SLV_NUM-1:0]   spi_clk     ,
    output  bit                     spi_mosi    ,
    input   bit                     spi_miso    ,

    input   bit                     r_spi_cpol  ,
    input   bit                     r_spi_cpha  ,

    input   t_spi_if_ro             spi_ifi_ro  ,
    output  t_spi_if_ri             spi_ifi_ri
    );

    enum    bit [2:0]   {IDLE='h0,WR_WAIT_DATA='h1,WR_PRE='h2,WR='h3,RD_WAIT_INF='h4,RD='h5,RD_WAIT_BUF='h6,RW_DONE='h7} spi_state;

    bit             pre_phase;

    bit             bit_phase;
    bit [2:0]       bit_cnt;
    bit [1:0]       byte_cnt;

    bit [31:0]      tx_shft_reg;
    bit             burst_is_last;
    bit [1:0]       valid_len;
    bit [3:0]       burst_wait_cnt;

    bit [31:0]      rx_shft_reg;

    always_ff @(posedge clk) begin
        unique case (spi_state)
            IDLE            :   if (spi_ifi_ro.strt)
                                    spi_state <= WR_WAIT_DATA;
            WR_WAIT_DATA    :   if (~spi_ifi_ro.wd_empty)
                                    spi_state <= WR_PRE;
                                else if (&burst_wait_cnt)
                                    spi_state <= RW_DONE;
            WR_PRE          :   if (clk_en & (pre_phase^~r_spi_cpha))
                                    spi_state <= WR;
            WR              :   if (clk_en & bit_phase & (&bit_cnt) & (byte_cnt==valid_len))
                                    if (burst_is_last) begin
                                        if (spi_ifi_ro.rdata_en)
                                            spi_state <= RD_WAIT_INF;
                                        else
                                            spi_state <= RW_DONE;
                                    end else
                                        spi_state <= WR_WAIT_DATA;
            RD_WAIT_INF     :   if (~spi_ifi_ro.rd_inf_empty)
                                    spi_state <= RD;
                                else if (&burst_wait_cnt)
                                    spi_state <= RW_DONE;
            RD              :   if (clk_en & bit_phase & (&bit_cnt) & (byte_cnt==valid_len))
                                    spi_state <= RD_WAIT_BUF;
            RD_WAIT_BUF     :   if (~spi_ifi_ro.rd_rdy) begin
                                    if (burst_is_last)
                                        spi_state <= RW_DONE;
                                    else
                                        spi_state <= RD_WAIT_INF;
                                end else if (&burst_wait_cnt)
                                    spi_state <= RW_DONE;
            default         :   if (~spi_ifi_ro.strt & clk_en)  //RW_DONE
                                    spi_state <= IDLE;
        endcase

        if (spi_state==WR_PRE) begin
            if (clk_en)
                pre_phase <= ~pre_phase;
        end else
            pre_phase <= 1'b0;

        unique case(spi_state)
            WR_PRE  :   if (clk_en & pre_phase)
                            bit_phase <= ~bit_phase;
            WR,RD   :   if (clk_en)
                            bit_phase <= ~bit_phase;
            default :   bit_phase   <= 1'b0;
        endcase

        if (spi_state==WR || spi_state==RD) begin
            if (clk_en & bit_phase) begin
                bit_cnt <= bit_cnt + 1;
                if (&bit_cnt)
                    byte_cnt <= byte_cnt + 1;
            end
        end else begin
            bit_cnt     <= 'b0;
            byte_cnt    <= 'b0;
        end

        unique case (spi_state)
            WR_PRE      :   if (spi_ifi_ri.wd_r)
                                unique case(valid_len)
                                    2'h0    :   tx_shft_reg <= {spi_ifi_ro.rwdata[7:0],24'h0};
                                    2'h1    :   tx_shft_reg <= {spi_ifi_ro.rwdata[15:0],16'h0};
                                    2'h2    :   tx_shft_reg <= {spi_ifi_ro.rwdata[23:0],8'h0};
                                    default :   tx_shft_reg <= spi_ifi_ro.rwdata;
                                endcase
            WR          :   if (clk_en & (bit_phase^r_spi_cpha))
                                tx_shft_reg[31:1] <= tx_shft_reg[30:0];
            default     :   ;
        endcase

        unique case (spi_state)
            RD_WAIT_INF :   if (~spi_ifi_ro.rd_inf_empty)
                                rx_shft_reg <= 'b0;
            RD          :   if (clk_en & (~bit_phase^r_spi_cpha))
                                rx_shft_reg <= {rx_shft_reg[30:0],spi_miso};
            default     :   ;
        endcase

        unique case (spi_state)
            WR_WAIT_DATA    :   if (~spi_ifi_ro.wd_empty) begin
                                    burst_is_last   <= spi_ifi_ro.wd_lst;
                                    valid_len       <= spi_ifi_ro.wd_len;
                                end
            RD_WAIT_INF     :   if (~spi_ifi_ro.rd_inf_empty) begin
                                    burst_is_last   <= spi_ifi_ro.rd_lst;
                                    valid_len       <= spi_ifi_ro.rd_len;
                                end
            default         :   ;
        endcase

        spi_ifi_ri.wd_r <= 1'b0;
        if (spi_state==WR_WAIT_DATA)
            spi_ifi_ri.wd_r <= ~spi_ifi_ro.wd_empty;

        spi_ifi_ri.rd_inf_r <= 1'b0;
        if (spi_state==RD_WAIT_INF)
            spi_ifi_ri.rd_inf_r <= ~ spi_ifi_ro.rd_inf_empty;

        spi_ifi_ri.rd_ind <= 1'b0;
        if (spi_state==RD_WAIT_BUF)
            if (~spi_ifi_ro.rd_rdy) begin
                spi_ifi_ri.rd_ind   <= 1'b1;
                spi_ifi_ri.rdata    <= rx_shft_reg;
            end

        unique case (spi_state)
            WR_WAIT_DATA,RD_WAIT_INF,RD_WAIT_BUF
                    :   if (clk_1k_fp)
                            burst_wait_cnt <= burst_wait_cnt + 1;   // >=15ms
            default :   burst_wait_cnt <= 'b0;
        endcase

        spi_ifi_ri.wdat_timeout <= 1'b0;
        if (spi_state==WR_WAIT_DATA)
            spi_ifi_ri.wdat_timeout <= spi_ifi_ro.wd_empty & (& burst_wait_cnt);

        spi_ifi_ri.rd_inf_timeout <= 1'b0;
        if (spi_state==RD_WAIT_INF)
            spi_ifi_ri.rd_inf_timeout <= spi_ifi_ro.rd_inf_empty & (& burst_wait_cnt);

        spi_ifi_ri.rdat_timeout <= 1'b0;
        if (spi_state==RD_WAIT_BUF)
            spi_ifi_ri.rdat_timeout <= spi_ifi_ro.rd_rdy & (& burst_wait_cnt);

        spi_ifi_ri.done <= 1'b0;
        if (spi_state==RW_DONE)
            spi_ifi_ri.done <= spi_ifi_ro.strt;

        if (spi_state==IDLE)
            spi_csn <= '1;
        else
            for (int i=0;i<SLV_NUM;i++) begin
                spi_csn[i] <= 1'b1;
                if (spi_ifi_ro.slv_sel==i)
                    spi_csn[i] <= 1'b0;
            end

        unique case(spi_state)
            WR_PRE  :   for (int i=0;i<SLV_NUM;i++)
                            if (spi_ifi_ro.slv_sel==i) begin
                                if (clk_en & pre_phase)
                                    spi_clk[i] <= ~r_spi_cpol;
                            end else
                                spi_clk[i] <= r_spi_cpol;
            WR,RD   :   for (int i=0;i<SLV_NUM;i++)
                            if (spi_ifi_ro.slv_sel==i) begin
                                if (clk_en)
                                    spi_clk[i] <= (~bit_phase)^r_spi_cpol;
                            end else
                                spi_clk[i] <= r_spi_cpol;
            default :   if (r_spi_cpol)
                            spi_clk <= '1;
                        else
                            spi_clk <= '0;
        endcase
    end

    assign spi_mosi = tx_shft_reg[31];

endmodule
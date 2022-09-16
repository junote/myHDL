module  lbus_arbiter    #(
    parameter                               LBUS_M_NUM  =   5,
    parameter                               LBUS_S_NUM  =   5,
    parameter   [LBUS_S_NUM:0]  [31:2]      LBUS_S_BASE_ADDR = {30'h0000_5000>>2,30'h0000_4000>>2,30'h0000_3000>>2,30'h0000_2000>>2,30'h0000_1000>>2,30'h0000_0000>>2}
    ) (
    input   bit                             clk             ,

    input   bit [LBUS_M_NUM-1:0]            lbus_m_req      ,
    input   bit [LBUS_M_NUM-1:0]    [31:2]  lbus_m_addr     ,
    input   bit [LBUS_M_NUM-1:0]            lbus_m_rw       ,
    input   bit [LBUS_M_NUM-1:0]    [31:0]  lbus_m_wdata    ,
    output  bit [LBUS_M_NUM-1:0]    [31:0]  lbus_m_rdata    ,
    output  bit [LBUS_M_NUM-1:0]            lbus_m_ack      ,
    output  bit [LBUS_M_NUM-1:0]            lbus_m_err      ,

    output  bit [LBUS_S_NUM-1:0]            lbus_s_cs       ,
    output  bit                     [31:2]  lbus_s_addr     ,
    output  bit                             lbus_s_we       ,
    output  bit                     [31:0]  lbus_s_wdata    ,
    input   bit [LBUS_S_NUM-1:0]    [31:0]  lbus_s_rdata    ,
    input   bit [LBUS_S_NUM-1:0]            lbus_s_ack      ,
    input   bit [LBUS_S_NUM-1:0]            lbus_s_err
    );

    localparam  LOG2_M_NUM  = $clog2(LBUS_M_NUM);
    localparam  LOG2_S_NUM  = $clog2(LBUS_S_NUM);

    function [LOG2_M_NUM-1:0] mod_inc;
        input   bit [LOG2_M_NUM-1:0]    din;
    begin
        if (din==LBUS_M_NUM-1)
            mod_inc = 'b0;
        else
            mod_inc = din + 1'b1;
    end
    endfunction

    function [LOG2_M_NUM-1:0] next_arb;
        input   bit [LOG2_M_NUM-1:0]    arb;
        input   bit [LBUS_M_NUM-1:0]    pend_reqs;

        bit [LOG2_M_NUM-1:0]    cur_idx;
    begin
        next_arb = arb;

        /*
        case(arb)
            'd0     :   if (pend_reqs[1])
                            next_arb='d1;
                        else if (pend_reqs[2])
                            next_arb='d2;
                        else if (pend_reqs[3])
                            next_arb='d3;
                        else if (pend_reqs[4])
                            next_arb='d4;
            'd1     :   if (pend_reqs[2])
                            next_arb='d2;
                        else if (pend_reqs[3])
                            next_arb='d3;
                        else if (pend_reqs[4])
                            next_arb='d4;
                        else if (pend_reqs[0])
                            next_arb='d0;
            'd2     :   if (pend_reqs[3])
                            next_arb='d3;
                        else if (pend_reqs[4])
                            next_arb='d4;
                        else if (pend_reqs[0])
                            next_arb='d0;
                        else if (pend_reqs[1])
                            next_arb='d1;
            'd3     :   if (pend_reqs[4])
                            next_arb='d4;
                        else if (pend_reqs[0])
                            next_arb='d0;
                        else if (pend_reqs[1])
                            next_arb='d1;
                        else if (pend_reqs[2])
                            next_arb='d2;
            default :   if (pend_reqs[0])
                            next_arb='d0;
                        else if (pend_reqs[1])
                            next_arb='d1;
                        else if (pend_reqs[2])
                            next_arb='d2;
                        else if (pend_reqs[3])
                            next_arb='d3;
        endcase
        */

        cur_idx = arb;
        for(int i=1;i<LBUS_M_NUM;i++) begin
            cur_idx = mod_inc(cur_idx);

            if (pend_reqs[cur_idx]) begin
                next_arb = cur_idx;
                break;
            end
        end

    end
    endfunction

    enum    bit [2:0]   {ARB_IDLE='h0,ARB_SLV_SEL='h1,ARB_SLV_SEL_2='h2,ARB_SLV_WAIT='h3,ARB_SLV_DONE='h4}  arb_state;

    bit [4:0]               wait_cnt;

    bit [LOG2_M_NUM-1:0]    cur_m_arb;

    bit                     cur_m_req_c;

    bit [31:2]              m_addr_r;
    bit                     m_rw_r;
    bit [31:0]              m_wdata_r;

    bit                     s_hit_c;

    bit [LOG2_S_NUM-1 :0]   s_idx_c;
    bit [LOG2_S_NUM-1 :0]   s_idx_r;

    bit [31:0]              s_rdata_c;
    bit                     s_ack_c;
    bit                     s_err_c;

    always_comb begin
        cur_m_req_c     = lbus_m_req[cur_m_arb];

        s_hit_c = 1'b0;
        if (m_addr_r <= LBUS_S_BASE_ADDR[LBUS_S_NUM])
            s_hit_c = 1'b1;

        s_idx_c = LBUS_S_NUM-1;
        for (bit [LOG2_S_NUM-1:0] i=0;i<LBUS_S_NUM-1;i++)
            if (m_addr_r < LBUS_S_BASE_ADDR[i+1]) begin
                s_idx_c = i;
                break;
            end

        /*
        if (m_addr_r < LBUS_S_BASE_ADDR[1])
            s_idx_c = 'd0;
        else if (m_addr_r < LBUS_S_BASE_ADDR[2])
            s_idx_c = 'd1;
        else if (m_addr_r < LBUS_S_BASE_ADDR[3])
            s_idx_c = 'd2;
        else if (m_addr_r < LBUS_S_BASE_ADDR[4])
            s_idx_c = 'd3;
        */

        s_rdata_c   = lbus_s_rdata[s_idx_r];
        s_ack_c     = lbus_s_ack[s_idx_r];
        s_err_c     = lbus_s_err[s_idx_r];
    end

    always_ff @(posedge clk) begin
        case (arb_state)
            ARB_IDLE        :   if (cur_m_req_c)
                                    arb_state <= ARB_SLV_SEL;
            ARB_SLV_SEL     :   if (s_hit_c)
                                    arb_state <= ARB_SLV_SEL_2;
                                else
                                    arb_state <= ARB_SLV_DONE;
            ARB_SLV_SEL_2   :   arb_state <= ARB_SLV_WAIT;
            ARB_SLV_WAIT    :   if (wait_cnt==31 | s_ack_c)
                                    arb_state <= ARB_SLV_DONE;
            default         :   arb_state <= ARB_IDLE;  //ARB_SLV_DONE
        endcase

        if (arb_state==ARB_IDLE && cur_m_req_c) begin
            m_addr_r    <= lbus_m_addr[cur_m_arb];
            m_rw_r      <= lbus_m_rw[cur_m_arb];
            m_wdata_r   <= lbus_m_wdata[cur_m_arb];
        end

        lbus_m_ack  <= 'b0;
        lbus_m_err  <= 'b0;
        case (arb_state)
            ARB_SLV_SEL     :   if (s_hit_c)
                                    s_idx_r                 <= s_idx_c;
                                else begin
                                    lbus_m_ack[cur_m_arb]   <= 1'b1;
                                    lbus_m_err[cur_m_arb]   <= 1'b1;
                                end
            ARB_SLV_SEL_2   :   begin
                                    lbus_s_cs[s_idx_r]      <= 1'b1;
                                    lbus_s_addr             <= m_addr_r - LBUS_S_BASE_ADDR[s_idx_r];
                                    lbus_s_we               <= m_rw_r;
                                    lbus_s_wdata            <= m_wdata_r;
                                end
            ARB_SLV_WAIT    :   if (wait_cnt==31) begin
                                    lbus_m_ack[cur_m_arb]   <= 1'b1;
                                    lbus_m_err[cur_m_arb]   <= 1'b0;
                                    lbus_m_rdata[cur_m_arb] <= 32'h0702dead;
                                    lbus_s_cs               <= 'b0;
                                    lbus_s_we               <= 'b0;
                                end else begin
                                    lbus_m_ack[cur_m_arb] <= s_ack_c;
                                    lbus_m_err[cur_m_arb] <= s_err_c;
                                    if (~m_rw_r & s_ack_c)
                                        lbus_m_rdata[cur_m_arb] <= s_rdata_c;

                                    if (s_ack_c) begin
                                        lbus_s_cs   <= 'b0;
                                        lbus_s_we   <= 'b0;
                                    end
                                end
            default         :   ;
        endcase

        if (arb_state==ARB_SLV_WAIT)
            wait_cnt <= wait_cnt + 1;
        else
            wait_cnt <= '0;

        if (arb_state==ARB_IDLE) begin
            if (~cur_m_req_c)
                cur_m_arb <= next_arb(cur_m_arb,lbus_m_req);
        end else if (arb_state==ARB_SLV_DONE)
            cur_m_arb <= mod_inc(cur_m_arb);
    end

endmodule
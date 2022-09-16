`define MDIO_ISOLATE
module mdio #(
    parameter   DIV_FACTOR  = 8
    ) (
    input   bit         clk         ,

    output  bit         mdc         ,
`ifdef MDIO_ISOLATE
    output  bit         mdio_t      ,
    output  bit         mdio_o      ,
    input   bit         mdio_i      ,
`else
    inout               mdio        ,
`endif

    input   bit         r_mdc_strt  ,
    output  bit         r_mdc_fnsh  ,
    input   bit [28:0]  r_mdc_wdata ,
    output  bit [15:0]  r_mdc_rdata
    );

    localparam  int LOG2_DIVFAC = $clog2(DIV_FACTOR)    ,
                    HALF_DIVFAC = $floor(DIV_FACTOR/2)  ,
                    QUAT_DIVFAC = $floor(DIV_FACTOR/4)  ;

    enum bit [2:0]  {IDLE='h0,PRE='h1,CMD='h2,TRN_AROUND='h3,DATA='h4,FNSH='h5} state;

    bit [LOG2_DIVFAC-1:0]   cnt_div ;
    bit                     fsm_en  ;

`ifndef MDIO_ISOLATE
    bit                     mdio_t  ;
`endif

    bit [4:0]               mdc_cnt ;
    bit [15:0]              shft_out;
    bit [15:0]              shft_in ;

`ifdef MDIO_ISOLATE
    assign  mdio_o  = shft_out[15];
`else
    assign  mdio    = mdio_t ? 1'bz : shft_out[15];
`endif

    assign  r_mdc_rdata = shft_in;

    always_ff @(posedge clk) begin
        case (state)
            IDLE        :  if (r_mdc_strt)
                                state <= PRE;
            PRE         :   if (fsm_en & mdc_cnt == 31)
                                state <= CMD;
            CMD         :   if (fsm_en & mdc_cnt[3:0] == 4'hd)
                                state <= TRN_AROUND;
            TRN_AROUND  :   if (fsm_en & mdc_cnt[0])
                                state <= DATA;
            DATA        :   if (fsm_en & mdc_cnt[3:0] == 4'hf)
                                state <= FNSH;
            FNSH        :   if (~r_mdc_strt)
                                state <= IDLE;
            default     :   state <= IDLE;
        endcase

        cnt_div <= cnt_div + 1;
        if (state == IDLE | state == FNSH | cnt_div==DIV_FACTOR-1)
            cnt_div <= '0;

        fsm_en <= 1'b0;
        if (cnt_div == HALF_DIVFAC+QUAT_DIVFAC)
            fsm_en <= 1'b1;

        mdc <= 1'b0;
        if (cnt_div!=0 && cnt_div<=HALF_DIVFAC)
            mdc <= 1'b1;

        case (state)
            IDLE,FNSH   :   mdc_cnt <= '0;
            default     :   if (fsm_en)
                                mdc_cnt <= mdc_cnt + 1;
        endcase

        case (state)
            IDLE    :   mdio_t <= ~r_mdc_strt;
            CMD     :   if (fsm_en & mdc_cnt[3:0]==4'hd & r_mdc_wdata[27]) //read or post read
                            mdio_t <= 1'b1;
            default :   ;
        endcase

        case (state)
            IDLE        :   shft_out <= '1;
            PRE         :   if (fsm_en & mdc_cnt == 31)
                                shft_out <= {1'b0,r_mdc_wdata[28:16],2'b10};
            CMD         :   if (fsm_en)
                                shft_out <= {shft_out[14:0],1'b1};
            TRN_AROUND  :   if (fsm_en) begin
                                if (mdc_cnt[0])
                                    shft_out <= r_mdc_wdata[15:0];
                                else
                                    shft_out <= {shft_out[14:0],1'b1};
                            end
            DATA        :   if (fsm_en)
                                shft_out <= {shft_out[14:0],1'b1};
            default     :   ;
        endcase

        case (state)
            PRE     :   shft_in <= '0;
            DATA    :   if (cnt_div == 1 & r_mdc_wdata[27])
                            `ifdef MDIO_ISOLATE
                                shft_in <= {shft_in[14:0], mdio_i};
                            `else
                                shft_in <= {shft_in[14:0], mdio};
                            `endif
            default :   ;
        endcase

        r_mdc_fnsh <= 1'b0;
        if (state == FNSH)
            r_mdc_fnsh <= 1'b1;
    end

endmodule
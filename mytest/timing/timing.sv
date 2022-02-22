module  timing (
    input   bit                 clk_125m                     ,

    output  bit                 clk_en_20m83                ,
    output  bit                 clk_en_20m83_d              ,

    output  bit                 clk_en_2m36                 ,
    output  bit                 clk_1k                      ,
    output  bit                 clk_1k_fp                   ,
    output  bit                 clk_10hz_fp                 ,
    output  bit                 clk_1hz                     ,

    input   bit [2:1]           fpga_refclk_tx              ,
    input   bit [2:1]           mate_refclk_rx              ,
    input   bit                 synce_clk_ctrla_sled        ,
    input   bit                 synce_clk_ctrlb_sled        ,
    input   bit                 bp_mate_synce_clk_rx_1v8    ,
    input   bit                 bits_rx_clk_1v8             ,
    input   bit [3:0]           osc_recov_clk               ,

    output  bit [2:1]           fpga_refclk_rx              ,
    output  bit [2:1]           mate_refclk_tx              ,
    output  bit [2:1]           refclk_a                    ,
    output  bit [2:1]           refclk_b                    ,
    output  bit                 bp_mate_synce_clk_tx_1v8    ,
    output  bit                 bits_tx_clk_1v8             ,

    input   bit [9:0]           ref_en                      ,
    input   bit [9:0]   [3:0]   ref_sel                     ,
    output  bit [10:0]          clk_loss
    );

    function bit f_cksel;
        input   bit         ref_en;
        input   bit [3:0]   ref_sel;
        input   bit [10:0]  refck_in;
    begin
        if (ref_en)
            unique case (ref_sel)
                4'b0000 :   f_cksel = refck_in[0];
                4'b0001 :   f_cksel = refck_in[1];
                4'b0010 :   f_cksel = refck_in[2];
                4'b0011 :   f_cksel = refck_in[3];
                4'b0100 :   f_cksel = refck_in[4];
                4'b0101 :   f_cksel = refck_in[5];
                4'b0110 :   f_cksel = refck_in[6];
                4'b0111 :   f_cksel = refck_in[7];
                4'b1000 :   f_cksel = refck_in[8];
                4'b1001 :   f_cksel = refck_in[9];
                4'b1010 :   f_cksel = refck_in[10];
                default :   f_cksel = 1'b0;
            endcase
        else
            f_cksel = 1'b0;
    end endfunction

    bit [2:0]   cnt_div_4_20m83;
    bit [5:0]   cnt_div_4_2m36;

    bit [15:0]  cnt_div_4_4k;
    bit         clk_4k_fp;

    bit         cnt_div_4_2k;
    bit         clk_1k_d;

    bit [6:0]   cnt_div_4_10hz;
    bit [2:0]   cnt_div_4_2hz;

    bit [10:0]  refck_in;

    always_ff @(posedge clk_125m) begin
        cnt_div_4_20m83 <= cnt_div_4_20m83 + 1;
        clk_en_20m83    <= 1'b0;
        if (cnt_div_4_20m83==5) begin
            cnt_div_4_20m83 <= '0;
            clk_en_20m83    <= 1'b1;
        end
        clk_en_20m83_d <= clk_en_20m83;

        cnt_div_4_2m36  <= cnt_div_4_2m36 + 1;
        clk_en_2m36     <= 1'b0;
        if (cnt_div_4_2m36==52) begin
            cnt_div_4_2m36 <= '0;
            clk_en_2m36 <= 1'b1;
        end

        cnt_div_4_4k    <= cnt_div_4_4k + 1;
        clk_4k_fp       <= 1'b0;
        if (cnt_div_4_4k==31249) begin
            cnt_div_4_4k    <= '0;
            clk_4k_fp       <= 1'b1;
        end

        if (clk_4k_fp) begin
            cnt_div_4_2k <= cnt_div_4_2k + 1;
            if (cnt_div_4_2k)
                clk_1k  <= ~clk_1k;
        end
        clk_1k_d <= clk_1k;

        clk_1k_fp   <= ~clk_1k_d & clk_1k;

        clk_10hz_fp <= 1'b0;
        if (clk_1k_fp) begin
            cnt_div_4_10hz <= cnt_div_4_10hz + 1;
            if (cnt_div_4_10hz==99) begin
                cnt_div_4_10hz  <= '0;
                clk_10hz_fp     <= 1'b1;
            end
        end

        if (clk_10hz_fp) begin
            cnt_div_4_2hz <= cnt_div_4_2hz + 1;
            if (cnt_div_4_2hz[2]) begin
                cnt_div_4_2hz   <= '0;
                clk_1hz         <= ~clk_1hz;
            end
        end

    end

    always_comb begin
        refck_in = {osc_recov_clk[2:0],bits_rx_clk_1v8,bp_mate_synce_clk_rx_1v8,synce_clk_ctrlb_sled,synce_clk_ctrla_sled,
                    mate_refclk_rx[2:1],fpga_refclk_tx[2:1]};

        for (int i=1;i<=2;i++) begin
            fpga_refclk_rx[i]   = f_cksel(ref_en[i-1],ref_sel[i-1],refck_in);
            mate_refclk_tx[i]   = f_cksel(ref_en[i+1],ref_sel[i+1],refck_in);
            refclk_a[i]         = f_cksel(ref_en[i+3],ref_sel[i+3],refck_in);
            refclk_b[i]         = f_cksel(ref_en[i+5],ref_sel[i+5],refck_in);
        end
        bp_mate_synce_clk_tx_1v8    = f_cksel(ref_en[8],ref_sel[8],refck_in);
        bits_tx_clk_1v8             = f_cksel(ref_en[9],ref_sel[9],refck_in);

    end

    generate for (genvar i=0; i<=10; i++) begin
        clklos_det clklos_det_inst(
            .ref_clk    (clk_125m        )   ,
            .det_en     (clk_4k_fp      )   ,
            .clk_to_det (refck_in[i]    )   ,
            .clk_loss   (clk_loss[i]    )
        );
    end endgenerate

endmodule
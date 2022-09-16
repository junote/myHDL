module spi_mst(
    input   bit         clk             ,
    input   bit         proc_en_p       ,
    input   bit         proc_en         ,

    output  bit         spi_clk         ,
    output  bit         spi_mosi        ,
    input   bit         spi_miso        ,

    input   bit         r_spi_loop      ,
    input   bit         r_spi_ci        ,
    input   bit         r_spi_cp        ,
    input   bit         r_spi_en        ,
    input   bit [3:0]   r_spi_len       ,
    input   bit [31:0]  r_spi_txd       ,
    input   bit         r_spi_nf        ,

    output  bit [31:0]  r_spi_rxd       ,
    output  bit         r_spi_txstrt    ,
    output  bit         r_spi_txdone
    );

    enum bit [2:0]  {IDLE='h0,TX_STRT='h1,TXBUF_SHFT='h2,TXBUF_SHFT_DONE='h3,TX_RUN_P0='h4,TX_RUN_P1='h5,TX_DONE='h6} spi_state;

    bit [4:0]       spi_cnt;

    bit             rcv_en;
    bit             first_edge;
    bit             xmt_en;

    bit             t_shft_en;

    bit             rx_bit_sel;

    bit [31:0]      tx_buffer;
    bit [31:0]      rx_buffer;

    assign  rx_bit_sel  = r_spi_loop ? spi_mosi : spi_miso;
    assign  r_spi_rxd   = rx_buffer;
    assign  spi_mosi    = (r_spi_len == 0) ? tx_buffer[31] : tx_buffer[15]; //32bits

    always_ff @(posedge clk) begin
        unique case (spi_state)
            IDLE            :   if (proc_en_p & r_spi_en & ~r_spi_nf)
                                    spi_state <= TX_STRT;
            TX_STRT         :   begin
                                    spi_state <= TXBUF_SHFT;
                                    if (r_spi_len == 4'h0 | r_spi_len == 4'hf)      //32bits,16bits
                                        spi_state <= TX_RUN_P0;
                                end
            TXBUF_SHFT      :   if (spi_cnt[3:0] == 4'hf)
                                    spi_state <= TXBUF_SHFT_DONE;
            TXBUF_SHFT_DONE :   if (proc_en)
                                    spi_state <= TX_RUN_P0;
            TX_RUN_P0       :   if (proc_en)
                                    spi_state <= TX_RUN_P1;
            TX_RUN_P1       :   if (proc_en) begin
                                    spi_state <= TX_RUN_P0;
                                    if (spi_cnt == {1'b0,r_spi_len})
                                        spi_state <= TX_DONE;
                                end
            default         :   spi_state <= IDLE;  //TX_DONE
        endcase

        unique case (spi_state)
            TX_RUN_P0   :   if (proc_en)
                                spi_clk <= ~r_spi_ci;
            TX_RUN_P1   :   if (proc_en)
                                spi_clk <= r_spi_ci;
            default     :   spi_clk <= r_spi_ci;
        endcase

        unique case (spi_state)
            TX_STRT,TX_DONE :   spi_cnt[3:0] <= r_spi_len + 1;
            TXBUF_SHFT      :   spi_cnt <= spi_cnt + 1;
            TX_RUN_P0       :   ;
            TX_RUN_P1       :   if (proc_en)
                                    spi_cnt <= spi_cnt + 1;
            default         :   spi_cnt <= '0;
        endcase

        r_spi_txstrt <= 1'b0;
        if (spi_state == TX_STRT)
            r_spi_txstrt <= 1'b1;

        r_spi_txdone <= 1'b0;
        if (spi_state == TX_DONE)
            r_spi_txdone <= 1'b1;

        rcv_en <= 1'b0;
        if (proc_en_p) begin
            if ((spi_state == TX_RUN_P0 & ~r_spi_cp) | (spi_state == TX_RUN_P1 & r_spi_cp))
                rcv_en <= 1'b1;
        end

        if (rcv_en)
            rx_buffer <= {rx_buffer[30:0],rx_bit_sel};

        if (spi_state == TX_STRT)
            first_edge <= 1'b1;
        else if (spi_state == TX_RUN_P1)
            first_edge <= 1'b0;

        xmt_en <= 1'b0;
        if (proc_en_p)
            if ((spi_state == TX_RUN_P0 & r_spi_cp & ~first_edge) | (spi_state == TX_RUN_P1 & ~r_spi_cp))
                xmt_en <= 1'b1;

        t_shft_en <= 1'b0;
        if (spi_state == TXBUF_SHFT)
            t_shft_en <= 1'b1;

        if (spi_state == TX_STRT)       //load
            tx_buffer <= r_spi_txd;
        else if (xmt_en | t_shft_en)
            tx_buffer <= {tx_buffer[30:0], 1'b0};
    end

endmodule
module uart(
    input   bit                 clk                 ,

    input   bit [15:0]          uart_divider        ,   //'h32dc(9600), 'h43c(115200)
    input   bit                 uart_en             ,
    input   bit                 uart_prty_en        ,
    input   bit                 uart_prty_odd       ,

    input   bit [1:0]           uart_ffrst          ,
    input   bit                 uart_loop_en        ,

    output  bit [1:0]           uart_ff_ovf         ,
    output  bit [11:0]          uart_ff0_rd_cnt     ,
    output  bit [11:0]          uart_ff1_rd_cnt     ,
    output  bit                 uart_txff_rdy       ,

    input   bit                 uart_txchar_wr      ,
    input   bit [8:0]           uart_txchar         ,

    input   bit                 uart_rxchar_rd      ,
    output  bit [8:0]           uart_rxchar         ,
    output  bit                 uart_rxff_valid     ,

    output  bit                 uart_rx_frm_err     ,
    output  bit                 uart_rx_prty_err    ,
    output  bit                 uart_rx_brk         ,

    output  bit                 mon_uart_rxd        ,
    input   bit                 mon_uart_txd
);
    enum    bit [2:0]   {TX_IDLE='h0,TX_STRT='h1,TX_BRK='h2,TX_DATA='h3,TX_PRTY='h4}    tx_state;
    enum    bit [2:0]   {RX_IDLE='h0,RX_STRT='h1,RX_DATA='h2,RX_PRTY='h3,RX_STOP='h4,RX_BRK='h5}    rx_state;

    bit [15:0]          cnt_tx_div      ;
    bit                 tx_tick         ;
    bit [2:0]           tx_bit_cnt      ;
    bit                 tx_brk_ind      ;
    bit [7:0]           tx_shft_reg     ;
    bit                 tx_parity       ;

    bit [3:1]           uart_rxd_d      ;
    bit [15:0]          cnt_rx_div      ;

    bit [3:0]   [15:0]  rx_smpl_cord    ;
    bit [3:0]           rx_smpl_tick    ;
    bit                 smpl_tick2_d    ;

    bit [1:0]           smpl_1_cnt      ;

    bit [2:0]           rx_bit_cnt      ;
    bit [7:0]           rx_shft_reg     ;
    bit                 rx_parity       ;
    bit                 rx_brk_ind      ;
    bit                 rx_frm_vld      ;

    bit [1:0]           ff_wr           ;
    bit [1:0]           ff_pin          ;
    bit [1:0]   [7:0]   ff_din          ;
    bit [1:0]           ff_full         ;
    bit [1:0]   [12:0]  ff_rd_cnt_i     ;

    bit [1:0]           ff_rd           ;
    bit [1:0]   [3:0]   ff_pout         ;
    bit [1:0]   [31:0]  ff_dout         ;
    bit [1:0]           ff_empty        ;

    bit                 ff_rd1_d        ;

    always_ff @(posedge clk) begin:p_tx
        cnt_tx_div  <= cnt_tx_div + 1;
        tx_tick     <= 1'b0;
        if (cnt_tx_div == uart_divider) begin
            cnt_tx_div  <= '0;
            tx_tick     <= 1'b1;
        end

        if (tx_tick)
            case (tx_state)
                TX_IDLE :   if (~ff_empty[1])
                                tx_state <= TX_STRT;
                TX_STRT :   if (tx_brk_ind)
                                tx_state <= TX_BRK;
                            else
                                tx_state <= TX_DATA;
                TX_BRK  :   tx_state <= TX_DATA;
                TX_DATA :   if (tx_bit_cnt == 7)
                                if (uart_prty_en)
                                    tx_state <= TX_PRTY;
                                else
                                    tx_state <= TX_IDLE;
                default :   tx_state <= TX_IDLE;    //TX_PRTY
            endcase

        ff_rd[1] <= 1'b0;
        if (~ff_empty[1] & tx_tick & tx_state==TX_IDLE)
            ff_rd[1] <= 1'b1;
        ff_rd1_d <= ff_rd[1];

        if (ff_rd1_d) begin
            tx_brk_ind  <= ff_pout[1][0];
            tx_shft_reg <= ff_dout[1][7:0];
            tx_parity   <= uart_prty_odd;
        end else if (tx_tick & tx_state == TX_DATA) begin
            tx_shft_reg <= {1'b1, tx_shft_reg[7:1]};
            tx_parity   <= tx_parity ^ tx_shft_reg[0];
        end

        if (tx_state == TX_DATA) begin
            if (tx_tick == 1'b1)
                tx_bit_cnt <= tx_bit_cnt + 1;
        end else
            tx_bit_cnt <= '0;

        case (tx_state)
            TX_STRT,TX_BRK
                    :   mon_uart_rxd <= 1'b0;
            TX_DATA :   mon_uart_rxd <= ~tx_brk_ind & tx_shft_reg[0];
            TX_PRTY :   mon_uart_rxd <= ~tx_brk_ind & tx_parity;
            default :   mon_uart_rxd <= 1'b1;
        endcase
    end

    always_ff @(posedge clk) begin:p_rx
        if (uart_loop_en)
            uart_rxd_d <= {uart_rxd_d[2:1],mon_uart_rxd};
        else
            uart_rxd_d <= {uart_rxd_d[2:1],mon_uart_txd};

        case (rx_state)
            RX_IDLE :   if (uart_rxd_d[3:2] == 2'b10)
                            rx_state <= RX_STRT;
            RX_STRT :   if (smpl_tick2_d & smpl_1_cnt[1])   //false_strt
                            rx_state <= RX_IDLE;
                        else if (rx_smpl_tick[3])
                            rx_state <= RX_DATA;
            RX_DATA :   if (rx_smpl_tick[3] & rx_bit_cnt == 7)
                            if (uart_prty_en)
                                rx_state <= RX_PRTY;
                            else
                                rx_state <= RX_STOP;
            RX_PRTY :   if (rx_smpl_tick[3])
                            rx_state <= RX_STOP;
            RX_STOP :   if (smpl_tick2_d)
                            if (rx_brk_ind & ~smpl_1_cnt[1])
                                rx_state <= RX_BRK;
                            else
                                rx_state <= RX_IDLE;
            RX_BRK  :   if (uart_rxd_d[2])
                            rx_state <= RX_IDLE;
            default :   rx_state <= RX_IDLE;
        endcase

        if (rx_state == RX_IDLE)
            cnt_rx_div <= 'h1;
        else if (cnt_rx_div == uart_divider)
            cnt_rx_div <= '0;
        else
            cnt_rx_div <= cnt_rx_div + 1;

        if (rx_state == RX_IDLE) begin
            rx_smpl_cord[0] <= {2'h0,(uart_divider[15:2] - 1)};
            rx_smpl_cord[1] <= {1'b0,(uart_divider[15:1] - 1)};
            rx_smpl_cord[2] <= {1'b0,uart_divider[15:2],1'b0} + {2'h0,uart_divider[15:2]};
            rx_smpl_cord[3] <= uart_divider - 1;
        end

        rx_smpl_tick <= '0;
        for (int i=0;i<4;i++)
            if (cnt_rx_div == rx_smpl_cord[i])
                rx_smpl_tick[i] <= 1'b1;
        smpl_tick2_d <= rx_smpl_tick[2];

        if (rx_state == RX_IDLE | rx_smpl_tick[3])
            smpl_1_cnt <= '0;
        else if (|rx_smpl_tick[2:0] & uart_rxd_d[2])
            smpl_1_cnt <= smpl_1_cnt + 1;

        if (rx_state == RX_DATA) begin
            if (rx_smpl_tick[3])
                rx_bit_cnt <= rx_bit_cnt + 1;
        end else
            rx_bit_cnt <= '0;

        if (rx_state == RX_DATA & smpl_tick2_d)
            rx_shft_reg <= {smpl_1_cnt[1], rx_shft_reg[7:1]};

        if (rx_state==RX_STRT)
            rx_parity <= uart_prty_odd;
        else if ((rx_state == RX_DATA || rx_state==RX_PRTY) & smpl_tick2_d)
            rx_parity <= rx_parity ^ smpl_1_cnt[1];

        unique case (rx_state)
            RX_DATA,RX_PRTY,RX_STOP
                    :   if (smpl_tick2_d & smpl_1_cnt[1])
                            rx_brk_ind <= 1'b0;
            default :   rx_brk_ind <= 1'b1;
        endcase

        uart_rx_frm_err     <= 1'b0;
        uart_rx_prty_err    <= 1'b0;
        rx_frm_vld          <= 1'b0;
        uart_rx_brk         <= 1'b0;
        if (uart_en) begin
            if (rx_state==RX_STOP & smpl_tick2_d) begin
                uart_rx_frm_err <= ~smpl_1_cnt[1] & ~rx_brk_ind;

                if (smpl_1_cnt[1]) begin
                    if (uart_prty_en & rx_parity)
                        uart_rx_prty_err <= 1'b1;
                    else
                        rx_frm_vld <= 1'b1;
                end
            end else if (rx_state==RX_BRK & uart_rxd_d[2]) begin
                rx_frm_vld  <= 1'b1;
                uart_rx_brk <= 1'b1;
            end
        end

        uart_ff_ovf <= '0;
        if (rx_frm_vld & ff_full[0])
            uart_ff_ovf[0] <= 1'b1;
        if (uart_txchar_wr & ff_full[1])
            uart_ff_ovf[1] <= 1'b1;
    end

    assign  ff_wr[1]        = uart_en & uart_txchar_wr & ~ff_full[1];
    assign  ff_pin[1]       = uart_txchar[8];
    assign  ff_din[1]       = uart_txchar[7:0];

    assign  uart_txff_rdy   = ~ff_full[1];

    assign  ff_wr[0]        = rx_frm_vld & ~ff_full[0];
    assign  ff_pin[0]       = rx_brk_ind;
    assign  ff_din[0]       = rx_shft_reg;

    assign  ff_rd[0]        = uart_rxchar_rd & ~ff_empty[0];
    assign  uart_rxchar     = {ff_pout[0][0],ff_dout[0][7:0]};
    assign  uart_rxff_valid = ~ff_empty[0];

    assign  uart_ff0_rd_cnt = ff_rd_cnt_i[0][11:0];
    assign  uart_ff1_rd_cnt = ff_rd_cnt_i[1][11:0];

    generate for (genvar i=0; i<2; i++) begin:gen_fifo
        FIFO18E2 #(
            .CASCADE_ORDER              ("NONE"                 ),  // FIRST, LAST, MIDDLE, NONE, PARALLEL
            .CLOCK_DOMAINS              ("COMMON"               ),  // COMMON, INDEPENDENT
            .FIRST_WORD_FALL_THROUGH    ("FALSE"                ),  // FALSE, TRUE
            .INIT                       (36'h000000000          ),  // Initial values on output port
            .PROG_EMPTY_THRESH          (8                      ),  // Programmable Empty Threshold
            .PROG_FULL_THRESH           (2040                   ),  // Programmable Full Threshold
            // Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
            .IS_RDCLK_INVERTED          (1'b0                   ),  // Optional inversion for RDCLK
            .IS_RDEN_INVERTED           (1'b0                   ),  // Optional inversion for RDEN
            .IS_RSTREG_INVERTED         (1'b0                   ),  // Optional inversion for RSTREG
            .IS_RST_INVERTED            (1'b0                   ),  // Optional inversion for RST
            .IS_WRCLK_INVERTED          (1'b0                   ),  // Optional inversion for WRCLK
            .IS_WREN_INVERTED           (1'b0                   ),  // Optional inversion for WREN
            .RDCOUNT_TYPE               ("EXTENDED_DATACOUNT"   ),  // EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
            .READ_WIDTH                 (9                      ),  // 18-9
            .REGISTER_MODE              ("UNREGISTERED"         ),  // DO_PIPELINED, REGISTERED, UNREGISTERED
            .RSTREG_PRIORITY            ("RSTREG"               ),  // REGCE, RSTREG
            .SLEEP_ASYNC                ("FALSE"                ),  // FALSE, TRUE
            .SRVAL                      (36'h000000000          ),  // SET/reset value of the FIFO outputs
            .WRCOUNT_TYPE               ("RAW_PNTR"             ),  // EXTENDED_DATACOUNT, RAW_PNTR, SIMPLE_DATACOUNT, SYNC_PNTR
            .WRITE_WIDTH                (9                      )   // 18-9
        ) FIFO18E2_inst (
            // Write Control Signals inputs: Write clock and enable input signals
            .RST            (uart_ffrst[i]      ),      // 1-bit input: Reset
            .WRCLK          (clk                ),      // 1-bit input: Write clock
            .WREN           (ff_wr[i]           ),      // 1-bit input: Write enable
            // Write Data inputs: Write input data
            .DIN            ({24'h0,ff_din[i]}  ),      // 32-bit input: FIFO data input bus

            .RDCLK          (clk                ),      // 1-bit input: Read clock
            .RDEN           (ff_rd[i]           ),      // 1-bit input: Read enable
            .DOUT           (ff_dout[i]         ),      // 32-bit output: FIFO data output bus
            // Status outputs: Flags and other FIFO status outputs
            .FULL           (ff_full[i]         ),      // 1-bit output: Full

            .EMPTY          (ff_empty[i]        ),      // 1-bit output: Empty
            .RDCOUNT        (ff_rd_cnt_i[i]     ),      // 13-bit output: Read count

            .WRCOUNT        (                   ),      // 13-bit output: Write count
            .WRERR          (                   ),      // 1-bit output: Write Error

            .RDERR          (                   ),      // 1-bit output: Read error
            .DINP           ({3'h0,ff_pin[i]}   ),      // 4-bit input: FIFO parity input bus
            .DOUTP          (ff_pout[i]         ),      // 4-bit output: FIFO parity output bus.

            .PROGEMPTY      (                   ),      // 1-bit output: Programmable empty
            .PROGFULL       (                   ),      // 1-bit output: Programmable full

            .RDRSTBUSY      (                   ),      // 1-bit output: Reset busy (sync to RDCLK)
            .WRRSTBUSY      (                   ),      // 1-bit output: Reset busy (sync to WRCLK)
            // Cascade Signals inputs: Multi-FIFO cascade signals
            .CASDIN         (32'h0              ),      // 32-bit input: Data cascade input bus
            .CASDINP        (4'h0               ),      // 4-bit input: Parity data cascade input bus
            .CASDOMUX       (1'b0               ),      // 1-bit input: Cascade MUX select
            .CASDOMUXEN     (1'b0               ),      // 1-bit input: Enable for cascade MUX select
            .CASNXTRDEN     (1'b0               ),      // 1-bit input: Cascade next read enable
            .CASOREGIMUX    (1'b0               ),      // 1-bit input: Cascade output MUX select
            .CASOREGIMUXEN  (1'b0               ),      // 1-bit input: Cascade output MUX select enable
            .CASPRVEMPTY    (1'b0               ),      // 1-bit input: Cascade previous empty
            // Cascade Signals outputs: Multi-FIFO cascade signals
            .CASDOUT        (                   ),      // 32-bit output: Data cascade output bus
            .CASDOUTP       (                   ),      // 4-bit output: Parity data cascade output bus
            .CASNXTEMPTY    (                   ),      // 1-bit output: Cascade next empty
            .CASPRVRDEN     (                   ),      // 1-bit output: Cascade previous read enable
            // Read Control Signals inputs: Read clock, enable and reset input signals
            .REGCE          (1'b1               ),      // 1-bit input: Output register clock enable
            .RSTREG         (1'b0               ),      // 1-bit input: Output register reset
            .SLEEP          (1'b0               )       // 1-bit input: Sleep Mode
        );

    end endgenerate;

endmodule
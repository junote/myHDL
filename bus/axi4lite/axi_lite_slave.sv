module axi_lite_slave #(
    parameter LBUS_AW = 18
    ) (
    input   bit         clk             ,

    // Slave Interface Write Address Ports
    input   bit [31:2]  s_axi_awaddr    ,
    input   bit         s_axi_awvalid   ,
    output  bit         s_axi_awready   ,

    // slave interface write data ports
    input   bit [31:0]  s_axi_wdata     ,
    //input   bit [3:0]   s_axi_wstrb     ,
    input   bit         s_axi_wvalid    ,
    output  bit         s_axi_wready    ,

    // slave interface write response ports
    output  bit [1:0]   s_axi_bresp     ,
    output  bit         s_axi_bvalid    ,
    input   bit         s_axi_bready    ,

    // slave interface read address ports
    input   bit [31:2]  s_axi_araddr    ,
    input   bit         s_axi_arvalid   ,
    output  bit         s_axi_arready   ,

    // slave interface read data ports
    output  bit [31:0]  s_axi_rdata     ,
    output  bit [1:0]   s_axi_rresp     ,
    output  bit         s_axi_rvalid    ,
    input   bit         s_axi_rready    ,

    /* Register Rd/Wrt Interface with internal modules */
    output  bit         axi_reg_req     ,
    output  bit         axi_reg_rw      ,
    output  bit [31:2]  axi_reg_addr    ,
    output  bit [31:0]  axi_reg_wdata   ,
    input   bit [31:0]  axi_reg_rdata   ,
    input   bit         axi_reg_ack     ,
    input   bit         axi_reg_err
    );

    enum bit [2:0] {AXI_IDLE=3'h0,AXI_WR=3'h1,AXI_WR_RESP=3'h2,AXI_RD=3'h3,AXI_RD_VLD=3'h4} axi_state;

    always_ff @(posedge clk) begin
        case (axi_state)
            AXI_IDLE    :   if (s_axi_awvalid & s_axi_wvalid)
                                axi_state <= AXI_WR;
                            else if (s_axi_arvalid)
                                axi_state <= AXI_RD;
            AXI_WR      :   if (axi_reg_ack)
                                axi_state <= AXI_WR_RESP;
            AXI_WR_RESP :   if (s_axi_bready)
                                axi_state <= AXI_IDLE;
            AXI_RD      :   if (axi_reg_ack)
                                axi_state <= AXI_RD_VLD;
            AXI_RD_VLD  :   if (s_axi_rready)
                                axi_state <= AXI_IDLE;
            default     :   axi_state <= AXI_IDLE;
        endcase

        if (axi_state==AXI_IDLE)
            axi_reg_req <= (s_axi_awvalid & s_axi_wvalid) | s_axi_arvalid;
        else if (axi_state==AXI_WR || axi_state==AXI_RD)
            axi_reg_req <= ~axi_reg_ack;

        if (axi_state==AXI_IDLE)
            axi_reg_rw  <= (s_axi_awvalid & s_axi_wvalid);
        else if (axi_state==AXI_WR)
            axi_reg_rw  <= ~axi_reg_ack;

        if (axi_state==AXI_IDLE) begin
            if (s_axi_awvalid & s_axi_wvalid) begin
                axi_reg_addr <= s_axi_awaddr[LBUS_AW-1:2];
                //axi_reg_addr <= {{(32-LBUS_AW){1'b0}}, s_axi_awaddr[LBUS_AW-1:2]};
                axi_reg_wdata       <= s_axi_wdata;
            end else if (s_axi_arvalid)
                axi_reg_addr <= s_axi_araddr[LBUS_AW-1:2];
                //axi_reg_addr <= {{(32-LBUS_AW){1'b0}}, s_axi_araddr[LBUS_AW-1:2]};
        end

        if ((axi_state==AXI_RD) & axi_reg_ack)
            s_axi_rdata <= axi_reg_rdata;
    end

    always_comb begin
        s_axi_bresp     = 'h0;
        s_axi_rresp     = 'h0;

        s_axi_awready   = 1'b0;
        s_axi_wready    = 1'b0;
        s_axi_arready   = 1'b0;
        if (axi_state==AXI_IDLE) begin
            if (s_axi_awvalid & s_axi_wvalid) begin
                s_axi_awready   = 1'b1;
                s_axi_wready    = 1'b1;
            end

            s_axi_arready = ~(s_axi_awvalid & s_axi_wvalid) & s_axi_arvalid;
        end

        s_axi_bvalid = 1'b0;
        if (axi_state==AXI_WR_RESP)
            s_axi_bvalid = s_axi_bready;

        s_axi_rvalid = 1'b0;
        if (axi_state==AXI_RD_VLD)
            s_axi_rvalid = s_axi_rready;
    end

endmodule
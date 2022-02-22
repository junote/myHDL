module clklos_det(
    input   bit     ref_clk     ,
    input   bit     det_en      ,   // <= (1/2)*Fclk_to_det
    input   bit     clk_to_det  ,
    output  bit     clk_loss
    );

    bit     det_en_d;
    bit     clk_alive;

    always_ff @(posedge clk_to_det,posedge det_en_d)
        if (det_en_d)
            clk_alive <= 1'b0;
        else
            clk_alive <= 1'b1;

    always_ff @(posedge ref_clk) begin
        det_en_d <= det_en;

        if (det_en)
            clk_loss <= ~ clk_alive;
    end

endmodule
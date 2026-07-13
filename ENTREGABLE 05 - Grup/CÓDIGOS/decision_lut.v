module decision_lut(
    input [7:0] ocupacion,
    output reg [1:0] estado
);
    // 00 = libre
    // 01 = moderado
    // 10 = congestionado
    // 11 = reservado
    
    always @(*) begin
        if (ocupacion <= 8'd30)
            estado = 2'b00;
        else if (ocupacion <= 8'd70)
            estado = 2'b01;
        else
            estado = 2'b10;
    end
endmodule
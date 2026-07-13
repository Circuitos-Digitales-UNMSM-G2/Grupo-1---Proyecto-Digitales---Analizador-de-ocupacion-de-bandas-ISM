module channel_comparator(
    input [7:0] occ_ch1,
    input [7:0] occ_ch6,
    input [7:0] occ_ch11,
    output reg [7:0] canal_recomendado
);
    // Selecciona el canal con menor ocupación
    // En caso de empate, prioriza CH1, luego CH6, luego CH11
    
    always @(*) begin
        if ((occ_ch1 <= occ_ch6) && (occ_ch1 <= occ_ch11))
            canal_recomendado = 8'd1;
        else if ((occ_ch6 < occ_ch1) && (occ_ch6 <= occ_ch11))
            canal_recomendado = 8'd6;
        else
            canal_recomendado = 8'd11;
    end
endmodule
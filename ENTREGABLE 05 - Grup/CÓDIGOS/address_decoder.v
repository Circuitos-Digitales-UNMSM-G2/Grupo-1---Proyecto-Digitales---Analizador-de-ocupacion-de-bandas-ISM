module address_decoder(
    input [3:0] addr,
    output reg sel_rssi_ch1,
    output reg sel_occ_ch1,
    output reg sel_state_ch1,
    output reg sel_rssi_ch6,
    output reg sel_occ_ch6,
    output reg sel_state_ch6,
    output reg sel_rssi_ch11,
    output reg sel_occ_ch11,
    output reg sel_state_ch11,
    output reg sel_recommended
);
    always @(*) begin
        // Inicializar todas las señales en 0
        sel_rssi_ch1 = 0;
        sel_occ_ch1 = 0;
        sel_state_ch1 = 0;
        sel_rssi_ch6 = 0;
        sel_occ_ch6 = 0;
        sel_state_ch6 = 0;
        sel_rssi_ch11 = 0;
        sel_occ_ch11 = 0;
        sel_state_ch11 = 0;
        sel_recommended = 0;
        
        // Decodificar dirección
        case (addr)
            4'h0: sel_rssi_ch1 = 1;
            4'h1: sel_occ_ch1 = 1;
            4'h2: sel_state_ch1 = 1;
            4'h4: sel_rssi_ch6 = 1;
            4'h5: sel_occ_ch6 = 1;
            4'h6: sel_state_ch6 = 1;
            4'h8: sel_rssi_ch11 = 1;
            4'h9: sel_occ_ch11 = 1;
            4'hA: sel_state_ch11 = 1;
            4'hF: sel_recommended = 1;
            default: begin
                // No activar ninguna señal
                sel_rssi_ch1 = 0;
                sel_occ_ch1 = 0;
                sel_state_ch1 = 0;
                sel_rssi_ch6 = 0;
                sel_occ_ch6 = 0;
                sel_state_ch6 = 0;
                sel_rssi_ch11 = 0;
                sel_occ_ch11 = 0;
                sel_state_ch11 = 0;
                sel_recommended = 0;
            end
        endcase
    end
endmodule

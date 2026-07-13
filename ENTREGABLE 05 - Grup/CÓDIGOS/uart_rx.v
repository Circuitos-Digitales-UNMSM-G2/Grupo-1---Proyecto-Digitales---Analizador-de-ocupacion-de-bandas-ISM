// Módulo Receptor UART
// Configurado para: Reloj de 50 MHz y 115200 Baudios (CLKS_PER_BIT = 434)

module uart_rx #(
    parameter CLKS_PER_BIT = 434
)(
    input        clk,
    input        rst,
    input        rx_serial,  // El único cable de entrada desde el ESP32
    output reg       rx_dv,      // Pulso alto por 1 ciclo cuando el byte está listo (Data Valid)
    output reg [7:0] rx_byte     // El byte de datos recibido
);

    // Definición de estados
    localparam s_IDLE         = 3'b000;
    localparam s_RX_START_BIT = 3'b001;
    localparam s_RX_DATA_BITS = 3'b010;
    localparam s_RX_STOP_BIT  = 3'b011;
    localparam s_CLEANUP      = 3'b100;

    reg [2:0] r_SM_Main;
    reg [8:0] r_Clk_Count;
    reg [2:0] r_Bit_Index;   // Índice de los 8 bits
    reg [7:0] r_Rx_Data;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_SM_Main   <= s_IDLE;
            r_Clk_Count <= 0;
            r_Bit_Index <= 0;
            rx_dv       <= 1'b0;
            rx_byte     <= 8'd0;
            r_Rx_Data   <= 8'd0;
        end else begin
            case (r_SM_Main)
                
                // ESTADO 0: Esperando a que la línea baje a 0 (Start Bit)
                s_IDLE: begin
                    rx_dv       <= 1'b0;
                    r_Clk_Count <= 0;
                    r_Bit_Index <= 0;
                    
                    if (rx_serial == 1'b0)          // Detecta el inicio de transmisión
                        r_SM_Main <= s_RX_START_BIT;
                    else
                        r_SM_Main <= s_IDLE;
                end
                
                // ESTADO 1: Verifica que sea un Start Bit real (lee en la mitad del bit)
                s_RX_START_BIT: begin
                    if (r_Clk_Count == (CLKS_PER_BIT-1)/2) begin
                        if (rx_serial == 1'b0) begin
                            r_Clk_Count <= 0;  // Resetea el contador
                            r_SM_Main   <= s_RX_DATA_BITS;
                        end else begin
                            r_SM_Main   <= s_IDLE; // Falsa alarma
                        end
                    end else begin
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main   <= s_RX_START_BIT;
                    end
                end
                
                // ESTADO 2: Lee los 8 bits de datos
                s_RX_DATA_BITS: begin
                    if (r_Clk_Count < CLKS_PER_BIT-1) begin
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main   <= s_RX_DATA_BITS;
                    end else begin
                        r_Clk_Count            <= 0;
                        r_Rx_Data[r_Bit_Index] <= rx_serial; // Guarda el bit actual
                        
                        // Verifica si ya leímos los 8 bits
                        if (r_Bit_Index < 7) begin
                            r_Bit_Index <= r_Bit_Index + 1;
                            r_SM_Main   <= s_RX_DATA_BITS;
                        end else begin
                            r_Bit_Index <= 0;
                            r_SM_Main   <= s_RX_STOP_BIT;
                        end
                    end
                end
                
                // ESTADO 3: Espera el Stop Bit
                s_RX_STOP_BIT: begin
                    if (r_Clk_Count < CLKS_PER_BIT-1) begin
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main   <= s_RX_STOP_BIT;
                    end else begin
                        rx_dv       <= 1'b1;       // ¡Avisa que el dato está listo!
                        rx_byte     <= r_Rx_Data;  // Saca el byte completo
                        r_Clk_Count <= 0;
                        r_SM_Main   <= s_CLEANUP;
                    end
                end
                
                // ESTADO 4: Un ciclo de reloj para mantener rx_dv en alto
                s_CLEANUP: begin
                    r_SM_Main <= s_IDLE;
                    rx_dv     <= 1'b0;
                end
                
                default: r_SM_Main <= s_IDLE;
            endcase
        end
    end
endmodule
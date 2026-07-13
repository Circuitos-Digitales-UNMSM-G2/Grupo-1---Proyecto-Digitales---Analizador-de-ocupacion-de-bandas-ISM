module ism_analyzer_top(
    input clk,
    input rst,
    input rx_serial,                     // El único cable de entrada de datos desde el ESP32
    output [1:0] estado_ch1,
    output [1:0] estado_ch6,
    output [1:0] estado_ch11,
    output reg [7:0] canal_recomendado,
    output reg output_valid,
    
    // Puertos de monitoreo/debug (opcionales, puedes mantenerlos o reducirlos)
    output reg [3:0] state,
    output reg [3:0] addr,
    output reg write_enable,
    output reg [7:0] data_in,
    output [7:0] data_out
);

    // Definición de estados de la FSM
    localparam IDLE             = 4'd0;
    localparam CAPTURE          = 4'd1; // Reutilizado para captura secuencial UART
    localparam WRITE_CH1_RSSI   = 4'd2;
    localparam WRITE_CH1_OCC    = 4'd3;
    localparam WRITE_CH1_STATE  = 4'd4;
    localparam WRITE_CH6_RSSI   = 4'd5;
    localparam WRITE_CH6_OCC    = 4'd6;
    localparam WRITE_CH6_STATE  = 4'd7;
    localparam WRITE_CH11_RSSI  = 4'd8;
    localparam WRITE_CH11_OCC   = 4'd9;
    localparam WRITE_CH11_STATE = 4'd10;
    localparam COMPARE          = 4'd11;
    localparam WRITE_RESULT     = 4'd12;
    localparam OUTPUT_STATE     = 4'd13;

    // Registros internos para almacenar las métricas
    reg [7:0] rssi1_reg, occ1_reg;
    reg [7:0] rssi6_reg, occ6_reg;
    reg [7:0] rssi11_reg, occ11_reg;
    
    // Contador para identificar cuál de los 6 bytes está llegando
    reg [2:0] byte_count;

    // Cables de interconexión interna
    wire [1:0] estado1_wire, estado6_wire, estado11_wire;
    wire [7:0] recommended_wire;
    wire rx_dv;
    wire [7:0] rx_byte;

    // 1. Instanciación del nuevo módulo de entrada UART RX
    uart_rx #(.CLKS_PER_BIT(434)) UART_REC (
        .clk(clk),
        .rst(rst),
        .rx_serial(rx_serial),
        .rx_dv(rx_dv),
        .rx_byte(rx_byte)
    );

    // 2. Instanciación de tus módulos internos originales
    decision_lut LUT1 (.ocupacion(occ1_reg), .estado(estado1_wire));
    decision_lut LUT6 (.ocupacion(occ6_reg), .estado(estado6_wire));
    decision_lut LUT11(.ocupacion(occ11_reg), .estado(estado11_wire));

    channel_comparator COMP (
        .occ_ch1(occ1_reg),
        .occ_ch6(occ6_reg),
        .occ_ch11(occ11_reg),
        .canal_recomendado(recommended_wire)
    );

    metric_memory MEM(
        .clk(clk),
        .rst(rst),
        .write_enable(write_enable),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    // Asignación de salidas de estado combinacionales
    assign estado_ch1  = estado1_wire;
    assign estado_ch6  = estado6_wire;
    assign estado_ch11 = estado11_wire;

    // Máquina de Estados Finitos (FSM)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state             <= IDLE;
            addr              <= 4'd0;
            data_in           <= 8'd0;
            write_enable      <= 1'b0;
            output_valid      <= 1'b0;
            canal_recomendado <= 8'd0;
            rssi1_reg         <= 8'd0;
            occ1_reg          <= 8'd0;
            rssi6_reg         <= 8'd0;
            occ6_reg          <= 8'd0;
            rssi11_reg        <= 8'd0;
            occ11_reg         <= 8'd0;
            byte_count        <= 3'd0;
        end else begin
            write_enable <= 1'b0;

            case (state)
                
                // Espera el primer byte (RSSI CH1) para comenzar
                IDLE: begin
                    byte_count <= 3'd0;
                    if (rx_dv) begin
                        output_valid <= 1'b0;
                        rssi1_reg  <= rx_byte;
                        byte_count <= 3'd1;
                        state      <= CAPTURE;
                    end
                end

                // Captura secuencial de los 5 bytes restantes
                CAPTURE: begin
                    if (rx_dv) begin
                        case (byte_count)
                            3'd1: occ1_reg   <= rx_byte;
                            3'd2: rssi6_reg  <= rx_byte;
                            3'd3: occ6_reg   <= rx_byte;
                            3'd4: rssi11_reg <= rx_byte;
                            3'd5: begin
                                    occ11_reg <= rx_byte;
                                    state     <= WRITE_CH1_RSSI; // Avanza al flujo original
                                  end
                        endcase
                        byte_count <= byte_count + 1;
                    end
                end

                // --- Flujo original de escritura en memoria y procesamiento ---
                WRITE_CH1_RSSI: begin
                    addr         <= 4'h0;
                    data_in      <= rssi1_reg;
                    write_enable <= 1'b1;
                    state        <= WRITE_CH1_OCC;
                end

                WRITE_CH1_OCC: begin
                    addr         <= 4'h1;
                    data_in      <= occ1_reg;
                    write_enable <= 1'b1;
                    state        <= WRITE_CH1_STATE;
                end

                WRITE_CH1_STATE: begin
                    addr         <= 4'h2;
                    data_in      <= {6'b000000, estado1_wire}; // Corrección de sintaxis de concatenación
                    write_enable <= 1'b1;
                    state        <= WRITE_CH6_RSSI;
                end

                WRITE_CH6_RSSI: begin
                    addr         <= 4'h4;
                    data_in      <= rssi6_reg;
                    write_enable <= 1'b1;
                    state        <= WRITE_CH6_OCC;
                end

                WRITE_CH6_OCC: begin
                    addr         <= 4'h5;
                    data_in      <= occ6_reg;
                    write_enable <= 1'b1;
                    state        <= WRITE_CH6_STATE;
                end

                WRITE_CH6_STATE: begin
                    addr         <= 4'h6;
                    data_in      <= {6'b000000, estado6_wire};
                    write_enable <= 1'b1;
                    state        <= WRITE_CH11_RSSI;
                end

                WRITE_CH11_RSSI: begin
                    addr         <= 4'h8;
                    data_in      <= rssi11_reg;
                    write_enable <= 1'b1;
                    state        <= WRITE_CH11_OCC;
                end

                WRITE_CH11_OCC: begin
                    addr         <= 4'h9;
                    data_in      <= occ11_reg;
                    write_enable <= 1'b1;
                    state        <= WRITE_CH11_STATE;
                end

                WRITE_CH11_STATE: begin
                    addr         <= 4'hA;
                    data_in      <= {6'b000000, estado11_wire};
                    write_enable <= 1'b1;
                    state        <= COMPARE;
                end

                COMPARE: begin
                    canal_recomendado <= recommended_wire;
                    state             <= WRITE_RESULT;
                end

                WRITE_RESULT: begin
                    addr         <= 4'hF;
                    data_in      <= canal_recomendado;
                    write_enable <= 1'b1;
                    state        <= OUTPUT_STATE;
                end

                OUTPUT_STATE: begin
                    output_valid <= 1'b1;
                    state        <= IDLE; // Regresa a esperar una nueva trama
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule

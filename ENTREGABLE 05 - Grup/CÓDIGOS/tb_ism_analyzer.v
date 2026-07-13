`timescale 1ns/1ps

module tb_ism_analyzer;

    // Señales de prueba
    reg clk;
    reg rst;
    reg rx_serial;
    
    // Cables para observar las salidas
    wire [1:0] estado_ch1, estado_ch6, estado_ch11;
    wire [7:0] canal_recomendado;
    wire output_valid;

    // 1. Instanciamos tu diseño principal (Device Under Test)
    ism_analyzer_top DUT (
        .clk(clk),
        .rst(rst),
        .rx_serial(rx_serial),
        .estado_ch1(estado_ch1),
        .estado_ch6(estado_ch6),
        .estado_ch11(estado_ch11),
        .canal_recomendado(canal_recomendado),
        .output_valid(output_valid)
    );

    // 2. Generador de Reloj (50 MHz = periodo de 20ns)
    always #10 clk = ~clk;

    // 3. Tarea para simular el envío UART desde un ESP32 a 115200 baudios
    // 1 bit a 115200 baudios dura aprox 8680 nanosegundos
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            rx_serial = 0; // Start bit
            #8680;
            for(i=0; i<8; i=i+1) begin
                rx_serial = data[i]; // Data bits
                #8680;
            end
            rx_serial = 1; // Stop bit
            #8680;
            #20000; // Pequeña pausa entre bytes
        end
    endtask

    // 4. Secuencia de la simulación
    initial begin
        // Inicialización
        clk = 0;
        rst = 1;
        rx_serial = 1; // El estado de reposo del UART es 1
        
        #100; // Esperamos 100ns
        rst = 0; // Apagamos el reset
        #500;
        
        $display("Iniciando inyeccion de metricas UART...");

        // Caso de prueba del PDF:
        // CH1: RSSI 75, Ocupacion 55
        send_byte(8'd75);
        send_byte(8'd55);
        
        // CH6: RSSI 65, Ocupacion 15
        send_byte(8'd65);
        send_byte(8'd15);
        
        // CH11: RSSI 60, Ocupacion 60
        send_byte(8'd60);
        send_byte(8'd60);

        wait(output_valid == 1'b1);
        if (canal_recomendado != 8'd6) begin
            $display("ERROR: canal esperado 6, recibido %0d", canal_recomendado);
        end else begin
            $display("OK: FPGA recomendo canal %0d por bus paralelo", canal_recomendado);
        end
        
        $display("Simulacion terminada.");
        $stop; // Detenemos la gráfica
    end

endmodule

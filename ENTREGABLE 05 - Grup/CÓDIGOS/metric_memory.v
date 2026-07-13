module metric_memory(
    input clk,
    input rst,
    input write_enable,
    input [3:0] addr,
    input [7:0] data_in,
    output reg [7:0] data_out
);
    // Declaración de memoria: 16 posiciones de 8 bits
    reg [7:0] memory [0:15];
    integer i;
    
    // Proceso de escritura sincrónica
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Inicializar toda la memoria a cero
            for (i = 0; i < 16; i = i + 1)
                memory[i] <= 8'd0;
        end else begin
            if (write_enable)
                memory[addr] <= data_in;
        end
    end
    
    // Proceso de lectura combinacional
    always @(*) begin
        data_out = memory[addr];
    end
endmodule
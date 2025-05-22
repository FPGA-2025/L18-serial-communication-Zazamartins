// Módulo transmissor serial
module transmitter (
    input clk,          // Sinal de clock
    input rstn,         // Sinal de reset ativo baixo
    input start,        // Sinal para iniciar transmissão
    input [6:0] data_in, // Dados de entrada (7 bits)
    output reg serial_out // Saída serial
);

    // Definição dos estados da máquina de estados
    localparam RESET                = 3'd0; // Estado de reset
    localparam AGUARDA_START_BIT    = 3'd1; // Espera pelo sinal de start
    localparam START_BIT            = 3'd2; // Envia bit de start
    localparam ENVIA_DADOS          = 3'd3; // Estado de envio dos dados
    localparam FINALIZA_ENVIO_DADOS = 3'd4; // Finaliza o envio

    // Registradores para controle
    reg [2:0] estado;           // Estado atual
    reg [2:0] proximo_estado;   // Próximo estado
    reg [3:0] contador_bit;     // Contador de bits enviados
    reg [7:0] buffer_dados;     // Buffer para armazenar dados + bit de paridade

    // Lógica sequencial (clock e reset)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin        // Reset assíncrono ativo baixo
            estado = RESET;     // Volta para estado inicial
        end else begin
            estado = proximo_estado; // Atualiza o estado
        end
    end

    // Lógica combinacional para próximo estado
    always @(estado) begin
        case (estado)
            RESET: begin
                // Sempre vai para AGUARDA_START_BIT após reset
                proximo_estado = AGUARDA_START_BIT;
            end

            AGUARDA_START_BIT: begin
                // Se start for 0, inicia transmissão (lógica invertida?)
                proximo_estado = !start ? START_BIT : AGUARDA_START_BIT;
            end

            START_BIT: begin
                // Após bit de start, vai para envio de dados
                proximo_estado = ENVIA_DADOS;
            end

            ENVIA_DADOS: begin
                // Fica neste estado até enviar todos os bits (8)
                proximo_estado = contador_bit >= 8 ? FINALIZA_ENVIO_DADOS : ENVIA_DADOS;
            end

            FINALIZA_ENVIO_DADOS: begin
                // Volta para esperar novo start
                proximo_estado = AGUARDA_START_BIT;
            end
        endcase
    end

    // Lógica de saída e controle de dados
    always @(posedge clk) begin
        case (estado)
            RESET: begin
                // Inicializa registradores
                buffer_dados = 8'b00000000;  // Limpa buffer
                serial_out   = 8'b11111111;  // Mantém linha inativa
            end

            AGUARDA_START_BIT: begin
                // Estado de espera - não faz nada
            end

            START_BIT: begin
                contador_bit = 4'b0000;      // Zera contador de bits
                buffer_dados = {(^data_in), data_in}; // Calcula bit de paridade e armazena dados
                serial_out   = 1'b0;         // Envia bit de start (0)
            end

            ENVIA_DADOS: begin
                contador_bit <= contador_bit+1; // Incrementa contador (usa <= para atribuição não-bloqueante)

                if (contador_bit < 8) begin
                    // Envia bits do buffer sequencialmente
                    serial_out = buffer_dados[contador_bit];
                end else begin
                    // Todos bits enviados, coloca linha em 1
                    serial_out = 1'b1;
                end
            end

            FINALIZA_ENVIO_DADOS: begin
                serial_out = 1'b0;            // Bit de stop (0) - observação: normalmente seria 1
            end
        endcase
    end
endmodule
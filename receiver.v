module receiver (
    input clk,
    input rstn,
    output ready,
    output [6:0] data_out,
    output parity_ok_n,
    input serial_in
);

    reg [3:0] contador_bit;
    reg [7:0] buffer_dados;
    reg recebendo_dados;

    reg _ready;
    reg [6:0] _data_out;
    reg _parity_ok_n;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            recebendo_dados = 0;
            contador_bit = 4'b0000;
            buffer_dados = 8'b00000000;
            _data_out = 7'b0000000;
            _ready = 0;
            _parity_ok_n = 1;
        end else begin

            _ready = 0;

            if(!recebendo_dados) begin
                if (!serial_in) begin
                    contador_bit = 4'b0000;
                    recebendo_dados = 1;
                end
            end else begin
                contador_bit <= contador_bit+1; 
    
                if (contador_bit < 8) begin
                    buffer_dados = {serial_in, buffer_dados[7:1]};
                end else begin
                    _data_out = buffer_dados[6:0];
                    _parity_ok_n = ^{buffer_dados[7:0]};
                    _ready = 1;
                    recebendo_dados = 0;
                end
            end
        end
    end

    assign ready       = _ready;
    assign data_out    = _data_out;
    assign parity_ok_n = _parity_ok_n;

endmodule
module uart_tx ( // 8-E-2
    input clk,
    input rst,
    input tx_start,
    input [7:0] data, // [MSB:LSB]
    output reg tx // bit serrial saindo
);  
    // converter o clock para a frequencia de transmissão
    parameter CLK_FREQ = 50_000_000; // Ex. FPGA com 50MHZ
    parameter BAUD_RATE = 9600; // faixa de transmissão
    localparam DIVISOR = CLK_FREQ / BAUD_RATE;

    // quantos bits um reg precisa ter para represetar um númerO? Nesse caso o do DIVISOR
    // $clog2(N) retorna o menor número de bits que consegue representar N valores diferentes (de 0 a N-1)
    /* 
        DIVISOR = 5208
        2^12 = 4096 → só representa valores de 0 a 4095. Não é suficiente (5207 > 4095).
        2^13 = 8192 → representa valores de 0 a 8191. Suficiente.
        Como 12 bits não bastam e 13 bastam, $clog2(5208) = 13.
    */
    parameter largura = $clog2(DIVISOR)-1;
    reg [largura : 0] contador;
    reg baud_tick; // 

    always @(posedge clk) begin
        if (rst) begin
            contador <= 0;
            baud_tick <= 0;
        end
        else if (contador == DIVISOR - 1) begin
            baud_tick <= 1;
            contador <= 0;
        end
        else begin
            baud_tick <= 0;
            contador <= contador + 1;
        end
    end

    // Máquina de estados

    reg [2 : 0] state;  // até 8 estados
    reg [2 : 0] bit_index; // mostra o indice o bit que está sendo transmitido, 3 bits pois 2^3 = 8 representações
    reg [7 : 0] data_reg;  // guarda os dados para não perder no meio da transmissão 
    reg parity_bit;

    localparam IDLE   = 3'd0, // <largura em bits>'<base><valor>
               START  = 3'd1,
               DATA   = 3'd2,
               PARITY = 3'd3,
               STOP1  = 3'd4,
               STOP2  = 3'd5;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            bit_index <= 0;
            tx <= 1;
        end
        else if (baud_tick) begin
            case (state)
                IDLE: begin
                    if (tx_start) begin
                        tx <= 1;
                        data_reg <= data;
                        parity_bit <= ^data;
                        state <= START;
                    end
                end 
                START: begin
                    tx <= 0;
                    bit_index <= 0;
                    state <= DATA;
                end
                DATA: begin
                    tx <= data_reg[bit_index];
                    if (bit_index != 7) begin
                        bit_index <= bit_index + 1;
                        state <= DATA;
                    end
                    else begin
                        state <= PARITY;
                    end
                end
                PARITY: begin
                    tx <= parity_bit;
                    state <= STOP1;
                end
                STOP1: begin
                    tx <= 1;
                    state <= STOP2;
                end
                STOP2: begin
                    tx <= 1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
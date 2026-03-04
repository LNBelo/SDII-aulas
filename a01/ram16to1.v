module RAM_16x1 (
    input wire clk, // Clock
    input wire we, // Sinal de escrita
    input wire [3:0] addr, // Endereco de 4 bits
    input wire din, // Dado de entrada
    output wire dout // Dado de saída
);
    // Divisão de endereço: subaddr indexa dentro de cada RAM_4x2, block escolhe qual bloco/bit
    wire [1:0] subaddr = addr[1:0];
    wire [1:0] block   = addr[3:2];

    // Saídas das duas RAM_4x2
    wire [1:0] ra_dout;
    wire [1:0] rb_dout;

    // sinais de escrita para cada RAM
    wire ra_we = we & (block == 2'b00 | block == 2'b01);
    wire rb_we = we & (block == 2'b10 | block == 2'b11);

    // sinais de entrada de 2 bits para escrita (formados preservando o outro bit)
    reg [1:0] ra_din;
    reg [1:0] rb_din;

    // Formar os dados de escrita combinacionalmente a partir das saídas atuais
    always @* begin
        // default: manter conteúdo atual
        ra_din = ra_dout;
        rb_din = rb_dout;

        if (ra_we) begin
            if (block == 2'b00) begin
                // escrever no bit 0 do ramA, preservar bit1
                ra_din = {ra_dout[1], din};
            end else begin // block == 2'b01
                // escrever no bit 1 do ramA, preservar bit0
                ra_din = {din, ra_dout[0]};
            end
        end

        if (rb_we) begin
            if (block == 2'b10) begin
                rb_din = {rb_dout[1], din};
            end else begin // block == 2'b11
                rb_din = {din, rb_dout[0]};
            end
        end
    end

    // Instanciar duas RAM_4x2 com inicialização para escrever E7A5 (16'b1110011110100101)
    // ra INIT (mem3..mem0) = {2'b10,2'b01,2'b10,2'b01} = 8'b10011001 (0x99)
    // rb INIT (mem3..mem0) = {2'b10,2'b11,2'b11,2'b01} = 8'b10111101 (0xBD)
    RAM_4x2 #(.INIT(8'b10011001)) ramA (
        .clk(clk),
        .we(ra_we),
        .addr(subaddr),
        .din(ra_din),
        .dout(ra_dout)
    );

    RAM_4x2 #(.INIT(8'b10111101)) ramB (
        .clk(clk),
        .we(rb_we),
        .addr(subaddr),
        .din(rb_din),
        .dout(rb_dout)
    );

    // Selecionar o bit de saída a partir do bloco
    assign dout = (block == 2'b00) ? ra_dout[0] :
                  (block == 2'b01) ? ra_dout[1] :
                  (block == 2'b10) ? rb_dout[0] :
                                     rb_dout[1];

endmodule

module RAM_4x2 #(
    parameter [7:0] INIT = 8'b00000000
) (
    input wire clk, // Clock
    input wire we, // Sinal de escrita
    input wire [1:0] addr, // Endereco de 2 bits
    input wire [1:0] din, // Dado de entrada
    output reg [1:0] dout // Dado de saída
);
    // 4 palavras de 2 bits como flip-flops
    reg [1:0] mem0, mem1, mem2, mem3;

    // Inicializar com valor passado via parâmetro
    initial begin
        mem0 = INIT[1:0];
        mem1 = INIT[3:2];
        mem2 = INIT[5:4];
        mem3 = INIT[7:6];
    end

    always @(posedge clk) begin
        if (we) begin
            case (addr)
                2'd0: mem0 <= din;
                2'd1: mem1 <= din;
                2'd2: mem2 <= din;
                2'd3: mem3 <= din;
                default: ;
            endcase
        end
    end

    // Leitura combinacional
    always @* begin
        case (addr)
            2'd0: dout = mem0;
            2'd1: dout = mem1;
            2'd2: dout = mem2;
            2'd3: dout = mem3;
            default: dout = 2'b00;
        endcase
    end
endmodule

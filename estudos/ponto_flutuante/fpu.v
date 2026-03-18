// FPU (Floating Point Unit)
module extrator_ieee754 (
    // retorna os blocos sinal, expoente e fracao
    input wire [31:0] float_in,
    output wire sinal, // 0 (positivo) e 1 (negativo)
    output wire [7:0] expoente,
    output wire [22:0] fracao
);
    assign sinal = float_in[31];
    assign expoente = float_in[30:23];
    assign fracao = float_in[22:0];
endmodule

module classificador_ieee754 (
    // verifica os casos especiais
    input wire [7:0] expoente,
    input wire [22:0] fracao,
    output wire eh_zero,
    output wire eh_infinito,
    output wire eh_nan
);
    wire expoente_zero, fracao_zero, expoente_255;

    assign expoente_zero = (expoente == 8'b00000000);
    assign fracao_zero = (fracao == 0);
    assign expoente_255 = (expoente == 8'b11111111);

    assign eh_zero = (expoente_zero && fracao_zero);
    assign eh_infinito = (expoente_255 && fracao_zero);
    assign eh_nan = (expoente_255 && !fracao_zero);    
endmodule

module alinhador_ieee754 (
    // normaliza deixando como o mesmo expoente 
    // cmp_ab
    // right_shifter
    input wire [7:0]  exp_a,
    input wire [23:0] frac_a, // 24bits: {1'b1, fracao_a}
    input wire [7:0]  exp_b,
    input wire [23:0] frac_b, // 24bits: {1'b1, fracao_b}
    
    output reg [7:0]  exp_comum,
    output reg [23:0] frac_a_alinhada,
    output reg [23:0] frac_b_alinhada
);
    reg [7:0] diferenca;

    always @(*) begin
        if(exp_a > exp_b) begin
            exp_comum = exp_a;
            diferenca = exp_a - exp_b;
            frac_a_alinhada = frac_a;
            frac_b_alinhada = frac_b >> diferenca; // deslocamento pra a direita
        end

        else if(exp_b > exp_a) begin
            exp_comum = exp_b;
            diferenca = exp_b - exp_a;
            frac_b_alinhada = frac_b;
            frac_a_alinhada = frac_a >> diferenca;
        end

        else begin
            exp_comum = exp_a;
            diferenca = 0; // evita a criação de memória (latch)
            frac_a_alinhada = frac_a;
            frac_b_alinhada = frac_b;
        end
    end
    
endmodule

module full_subtractor_1bit (
    input wire a,
    input wire b,
    input wire bin, // borrow in (empréstimo que vem de fora)
    output wire diff,
    output wire bout //borrow out (empréstimo que sobra)
);
    assign diff = a ^ b ^ bin;
    assign bout = (!a & bin) | (!a & b) | (b & bin);
endmodule

module full_subtractor_nbit #(parameter N = 8)(
    input wire bin,
    input wire [N-1:0] a,
    input wire [N-1:0] b,
    output wire [N-1:0] diff,
    output wire bout
);
    wire [N:0] conectar_bout_ao_bin;
    assign conectar_bout_ao_bin[0] = bin;
    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : gen_digits
            full_subtractor_1bit digit_subtractor(
                .bin(conectar_bout_ao_bin[i]),
                .a(a[i]),
                .b(b[i]),
                .diff(diff[i]),
                .bout(conectar_bout_ao_bin[i+1])
            );            
        end
    endgenerate

    // O bout final do módulo (MSB)
    assign bout = conectar_bout_ao_bin[N];

endmodule
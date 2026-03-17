// FPU (Floating Point Unit)
module extrator_ieee754 (
    input wire [31:0] float_in,
    output wire sinal,
    output wire [7:0] expoente,
    output wire [22:0] fracao
);
    assign sinal = float_in[31];
    assign expoente = float_in[30:23];
    assign fracao = float_in[22:0];
endmodule

module classificador_ieee754 (
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
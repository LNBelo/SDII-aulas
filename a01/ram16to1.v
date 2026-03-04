// E7A5
// 1110011110100101
module RAM_16x1 (
    input wire clk, // Clock
    input wire we, // Sinal de escrita
    input wire [3:0] addr, // Endereco
    input wire din, // Dado de entrada
    output wire dout // Dado de saida
);

// celulas de memoria (registradores)
reg m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15;

// Inicializacao com valor E7A5 (1110011110100101)
initial begin
    // 0101
    m0 = 1'b1;
    m1 = 1'b0;
    m2 = 1'b1;
    m3 = 1'b0;
    // 1010
    m4 = 1'b0;
    m5 = 1'b1;
    m6 = 1'b0;
    m7 = 1'b1;
    // 0111
    m8 = 1'b1;
    m9 = 1'b1;
    m10 = 1'b1;
    m11 = 1'b0;
    // 1110
    m12 = 1'b0;
    m13 = 1'b1;
    m14 = 1'b1;
    m15 = 1'b1;
end

// Decodificador de escrita
wire we0, we1, we2, we3, we4, we5, we6, we7, we8, we9, we10, we11, we12, we13, we14, we15;

assign we0  = we & (~addr[3] & ~addr[2] & ~addr[1] & ~addr[0]);
assign we1  = we & (~addr[3] & ~addr[2] & ~addr[1] &  addr[0]);
assign we2  = we & (~addr[3] & ~addr[2] &  addr[1] & ~addr[0]);
assign we3  = we & (~addr[3] & ~addr[2] &  addr[1] &  addr[0]);
assign we4  = we & (~addr[3] &  addr[2] & ~addr[1] & ~addr[0]);
assign we5  = we & (~addr[3] &  addr[2] & ~addr[1] &  addr[0]);
assign we6  = we & (~addr[3] &  addr[2] &  addr[1] & ~addr[0]);
assign we7  = we & (~addr[3] &  addr[2] &  addr[1] &  addr[0]);
assign we8  = we & ( addr[3] & ~addr[2] & ~addr[1] & ~addr[0]);
assign we9  = we & ( addr[3] & ~addr[2] & ~addr[1] &  addr[0]);
assign we10 = we & ( addr[3] & ~addr[2] &  addr[1] & ~addr[0]);
assign we11 = we & ( addr[3] & ~addr[2] &  addr[1] &  addr[0]);
assign we12 = we & ( addr[3] &  addr[2] & ~addr[1] & ~addr[0]);
assign we13 = we & ( addr[3] &  addr[2] & ~addr[1] &  addr[0]);
assign we14 = we & ( addr[3] &  addr[2] &  addr[1] & ~addr[0]);
assign we15 = we & ( addr[3] &  addr[2] &  addr[1] &  addr[0]);

// logica sequencial de escrita
always @(posedge clk) begin
    if (we0) m0 <= din;
    if (we1) m1 <= din;
    if (we2) m2 <= din;
    if (we3) m3 <= din;
    if (we4) m4 <= din;
    if (we5) m5 <= din;
    if (we6) m6 <= din;
    if (we7) m7 <= din;
    if (we8) m8 <= din;
    if (we9) m9 <= din;
    if (we10) m10 <= din;
    if (we11) m11 <= din;
    if (we12) m12 <= din;
    if (we13) m13 <= din;
    if (we14) m14 <= din;
    if (we15) m15 <= din;
end

// mux de leitura
assign dout = (~addr[3] & ~addr[2] & ~addr[1] & ~addr[0]) ? m0 :
              (~addr[3] & ~addr[2] & ~addr[1] &  addr[0]) ? m1 :
              (~addr[3] & ~addr[2] &  addr[1] & ~addr[0]) ? m2 :
              (~addr[3] & ~addr[2] &  addr[1] &  addr[0]) ? m3 :
              (~addr[3] &  addr[2] & ~addr[1] & ~addr[0]) ? m4 :
              (~addr[3] &  addr[2] & ~addr[1] &  addr[0]) ? m5 :
              (~addr[3] &  addr[2] &  addr[1] & ~addr[0]) ? m6 :
              (~addr[3] &  addr[2] &  addr[1] &  addr[0]) ? m7 :
              ( addr[3] & ~addr[2] & ~addr[1] & ~addr[0]) ? m8 :
              ( addr[3] & ~addr[2] & ~addr[1] &  addr[0]) ? m9 :
              ( addr[3] & ~addr[2] &  addr[1] & ~addr[0]) ? m10 :
              ( addr[3] & ~addr[2] &  addr[1] &  addr[0]) ? m11 :
              ( addr[3] &  addr[2] & ~addr[1] & ~addr[0]) ? m12 :
              ( addr[3] &  addr[2] & ~addr[1] &  addr[0]) ? m13 :
              ( addr[3] &  addr[2] &  addr[1] & ~addr[0]) ? m14 :
                                                            m15;
endmodule

// E7A5
// 1110011110100101

module rom_4x1 (
    input [1:0] address, // Endereco de entrada (2 bits)
    input [3:0] data_in, // Entrada de dados (4 bits)
    output data_out // Saida da ROM (1 bit)
);

assign data_out = (address == 2'b00) ? data_in[0] :
                  (address == 2'b01) ? data_in[1] :
                  (address == 2'b10) ? data_in[2] :
                  (address == 2'b11) ? data_in[3] : 1'b0;

endmodule

module mux4to1 (
    input wire A, B, C, D,
    input wire [1:0] S,
    output wire Y
);
    assign Y = (~S[1] & ~S[0] & A) |
               (~S[1] &  S[0] & B) |
               ( S[1] & ~S[0] & C) |
               ( S[1] &  S[0] & D);
endmodule

module rom_16x1 (
    input [3:0] address, // Endereco de entrada (4 bits)
    output data_out // Saida da ROM (1 bit)
);
    wire [3:0] D;
    wire [15:0] data_in = 16'b1110011110100101; // Dados da ROM
    
    rom_4x1 rom0 (
        .address(address[1:0]),
        .data_in(data_in[3:0]),
        .data_out(D[0])
    );
    rom_4x1 rom1 (
        .address(address[1:0]),
        .data_in(data_in[7:4]),
        .data_out(D[1])
    );
    rom_4x1 rom2 (
        .address(address[1:0]),
        .data_in(data_in[11:8]),
        .data_out(D[2])
    );
    rom_4x1 rom3 (
        .address(address[1:0]),
        .data_in(data_in[15:12]),
        .data_out(D[3])
    );
    
    mux4to1 mux (
        .A(D[0]),
        .B(D[1]),
        .C(D[2]),
        .D(D[3]),
        .S(address[3:2]),
        .Y(data_out)
    );

endmodule
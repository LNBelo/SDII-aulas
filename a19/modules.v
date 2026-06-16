/**
 * @file modules.v
 * @author Bruno Albertini (balbertini@usp.br)
 * @date 3 June 2026
 * @brief Modules for single cyle RISC-V from textbook "Computer Organization and Design RISC-V Edition" by David A. Patterson and John L. Hennessy
 */


// Registrador Contador de Programa
module pc #(
    parameter W = 32,
    parameter RST_ADDR = 0
    )(
        input  [W-1:0] NextPC, // Entrada do próximo valor do PC a ser carregado
        input load,            // Sinal de controle para habilitar a carga do próximo valor do PC
        output reg [W-1:0] PC, // Saída do valor atual do PC
        input clock, reset
    );
    always @(posedge clock) begin
        if (reset)
            PC <= RST_ADDR;
        else if (load)
            PC <= NextPC;
    end
endmodule

// MUX 2:1
module mux21
    #( parameter W = 32)
     ( input  [W-1:0] A, B,
       input  Sel,
       output [W-1:0] Y
     );
    assign Y = Sel ? B : A;
endmodule

// Gerador de Imediatos
module immgen
    #(
        parameter W = 32
    )(
        input  [31:0]  instruction,
        output [W-1:0] immediate
    );
    reg [W-1:0] imm_reg;
    assign immediate = imm_reg;

    always @(*) begin
        case (instruction[6:0])
            // I-type: load, arith-imm, jalr, system
            7'b0000011, 7'b0010011, 7'b1100111, 7'b1110011:
                imm_reg = {{(W-12){instruction[31]}}, instruction[31:20]};

            // S-type: store — imediato partido em [31:25] e [11:7]
            7'b0100011:
                imm_reg = {{(W-12){instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-type: branch — bits embaralhados pelo spec para manter rs1/rs2 no mesmo lugar que R-type
            // reconstrói: imm[12|10:5] em [31:25], imm[4:1|11] em [11:7], bit 0 sempre 0 (endereços pares)
            7'b1100011:
                imm_reg = {{(W-13){instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};

            // U-type: lui, auipc — os 20 bits superiores, 12 LSBs zerados
            7'b0110111, 7'b0010111:
                imm_reg = {instruction[31:12], 12'b0};

            // J-type: jal — bits embaralhados igual B-type para manter rd no mesmo lugar que I-type
            // reconstrói: imm[20|10:1|11|19:12], bit 0 sempre 0
            7'b1101111:
                imm_reg = {{(W-21){instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

            default:
                imm_reg = {W{1'b0}};
        endcase
    end
endmodule

// Banco de Registradores
module registerfile
    #( parameter W = 32)
    (
        input  [4  :0] Read1, Read2, WriteReg, // Entrada de escolha dos registradores a ler e a escrever
        input  [W-1:0] WriteData, // Dado a ser escrito no registrador escolhido por WriteReg
        input  RegWrite, // Sinal de controle para habilitar a escrita no registrador escolhido por WriteReg
        output [W-1:0] Data1, Data2, // Saída de dados dos registradores lidos
        input clock
    );
    reg [W-1:0] regs [31:0];

    // Leitura assíncrona — necessário para single-cycle (resultado disponível no mesmo ciclo)
    // x0 é hardwired zero conforme especificação RISC-V
    assign Data1 = (Read1 == 5'd0) ? {W{1'b0}} : regs[Read1];
    assign Data2 = (Read2 == 5'd0) ? {W{1'b0}} : regs[Read2];

    always @(posedge clock) begin
        if (RegWrite && WriteReg != 5'd0) // x0 não pode ser sobrescrito
            regs[WriteReg] <= WriteData;
    end
endmodule

// Somador genérico para o PC
module adder
    #( parameter W = 32)
     ( input  [W-1:0] A, B,
       output [W-1:0] Y
     );
    assign Y = A + B;
endmodule

// Unidade Lógica e Aritmética
module alu
    #( parameter W = 32)
     ( input  [3  :0] ALUctl,  // Escolhe a operação a ser realizada pela ALU
       input  [W-1:0] A, B,    // Entradas da ALU
       output [W-1:0] ALUout,  // Saída da ALU
       output Zero             // Sinal de zero, que indica se a saída da ALU é zero (usado para instruções de desvio)
     );
    // AluCtl: 0000 AND, 0001 OR, 0010 ADD, 0110 SUB, 0111 SLT, 1100 NOR
    reg [W-1:0] result;
    assign ALUout = result;
    assign Zero   = (result == {W{1'b0}});

    always @(*) begin
        case (ALUctl)
            4'b0000: result = A & B;
            4'b0001: result = A | B;
            4'b0010: result = A + B;
            4'b0110: result = A - B;
            // $signed necessário para comparação com sinal em complemento de 2
            4'b0111: result = ($signed(A) < $signed(B)) ? {{(W-1){1'b0}}, 1'b1} : {W{1'b0}};
            4'b1100: result = ~(A | B);
            default: result = {W{1'b0}};
        endcase
    end
endmodule

module rom32
    #(
        parameter D = 10,              // Profundidade (número de palavras)
        parameter L=$clog2(D),         // Tamanho do endereço (número de bits para endereçar palavras de 8 bits)
        parameter IFILE = "rom_hex.vh" // Arquivo de inicialização da ROM
    )(
        input  [L-1:0] adr,         // Endereço de entrada para acessar a ROM
        output [31:0]  data_o       // Saída de dados da ROM (32 bits)
    );

    localparam WORD_WIDTH = 32; // largura de cada palavra em bits
    localparam LAST_ADDR = D - 1; // último índice válido do array
    
    reg [WORD_WIDTH-1:0] memoria [0:LAST_ADDR]; // array de D palavras de 32 bits

    initial begin
        $readmemh(IFILE, memoria);
    end

    // Leitura
    assign data_o = memoria[adr];
endmodule

module ram
#(
    parameter W = 64,               // Largura (tamanho de cada palavra em bits)
    parameter D = 10,               // Profundidade (número de palavras)
    parameter L=$clog2(D),          // Tamanho do endereço (número de bits para endereçar palavras de 8 bits)
    parameter IFILE = "ram_hex.vh"  // Arquivo de inicialização da RAM
)(
    input  clk, we,
    input  [L-1:0] adr,
    input  [W-1:0] data_i,
    output [W-1:0] data_o
);
    localparam LAST_ADDR = D - 1; // último índice válido do array

    reg [W-1:0] memoria [0:LAST_ADDR]; // array de D palavras de 64 bits

    initial begin
        $readmemh(IFILE, memoria);
    end

    // Leitura assíncrona para deixar o dado disponível no mesmo ciclo do endereço
    assign data_o = memoria[adr];

    // Escrita síncrona controlada por we (write enable)
    always @(posedge clk) begin
        if (we)
            memoria[adr] <= data_i;
    end
endmodule

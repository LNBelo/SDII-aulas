module polirv_sc_fd #(
    parameter W = 32, // Largura dos dados em bits
    parameter D = 10, // Profundidade das memórias em bits (2^D palavras)
    parameter imdatafile = "imem_data.vh",
    parameter dmdatafile = "dmem_data.vh"
) (
    input          clk, rst,
    input          branch, mem2reg, dm_we, alu_src, reg_write,
    input  [3:0]   alu_op,
    output [31:0]  instruction,
    output         zero
);

    // Complete aqui o datapath do processador, implementando as instruções:
    // - tipo R: ADD, SUB, AND, OR
    // - tipo I: ADDI, ANDI, ORI
    // - tipo S: SW
    // - tipo L: LW
    // - tipo B: BEQ
    
endmodule

module polirv_sc_uc (
    input         zero,
    input  [31:0] instruction,
    output        branch, mem2reg, dm_we, alu_src, reg_write,
    output [3:0]  alu_op
);
    // Complete aqui a unidade de controle do processador, gerando os sinais de controle a partir do opcode e dos campos funct3 e funct7 da instrução.
endmodule


// **********************************
// Não precisa alterar a partir daqui
module polirv_sc #(
    parameter W = 32, // Largura dos dados em bits
    parameter D = 10, // Profundidade das memórias em bits (2^D palavras)
    parameter imdatafile = "imem_data.vh",
    parameter dmdatafile = "dmem_data.vh"
) (
    input          clk, rst
);
    wire [31:0]  instruction;
    wire branch, mem2reg, dm_we, alu_src, reg_write;
    wire [3:0] alu_op;
    wire zero;

    polirv_sc_uc control_unit (
        .zero(zero),
        .instruction(instruction),
        .branch(branch),
        .mem2reg(mem2reg),
        .dm_we(dm_we),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .alu_op(alu_op)
    );

    polirv_sc_fd #(.W(W), .D(D), .imdatafile(imdatafile), .dmdatafile(dmdatafile)) datapath (
        .clk(clk),
        .rst(rst),
        .branch(branch),
        .mem2reg(mem2reg),
        .dm_we(dm_we),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .alu_op(alu_op),
        .instruction(instruction),
        .zero(zero)
    );
endmodule

module polirv_sc_tb;
    reg clk, rst;
    polirv_sc #(
        .W(32), .D(10), 
        .imdatafile("mem_data.vh"), 
        .dmdatafile("mem_data.vh")
    ) polirv_sc_dut (
        .clk(clk),
        .rst(rst)
    );
    initial begin
        $dumpfile("polirv_sc_tb.vcd");
        $dumpvars(0, polirv_sc_tb);
        clk = 0; rst = 1;
        #5 rst = 0;
        #20000 $finish;
    end

    always #5 clk = ~clk;
endmodule   
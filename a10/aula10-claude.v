module testbench;

    reg clk, rst;
    wire done;
    toplevel dut (
        .clk_i(clk),
        .rst_i(rst),
        .dma_done_o(done)
    );

    always begin 
        #10 clk = !clk;
    end

    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
        clk = 0;
        rst = 1;
        #10 rst = 0;
        #100000 $finish;
    end
    
endmodule

module toplevel (
    // Wishbone Syscon
    input  wire                    clk_i,
    input  wire                    rst_i,
    output wire                    dma_done_o
);
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 14;
        
    wire wbm_we,  wbm_stb,  wbm_ack,  wbm_cyc,
                  wbs0_stb, wbs0_ack, wbs0_cyc,
         wbs2_we, wbs2_stb, wbs2_ack, wbs2_cyc;
    wire [ADDR_WIDTH-1:0] wbm_adr, wbs0_adr, wbs1_adr, wbs2_adr;
    wire [DATA_WIDTH-1:0] wbm_dat_i, wbs0_dat_o, wbs1_dat_o, wbs2_dat_o;
    wire [DATA_WIDTH-1:0] wbm_dat_o, wbs0_dat_i, wbs1_dat_i, wbs2_dat_i;

    dma #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ADD_SOURCE(14'h0000),
        .ADD_DESTIN(14'h3C00),
        .WORDS(1024)
    ) dma (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .done_o(dma_done),
        .wb_cyc_o(wbm_cyc),
        .wb_stb_o(wbm_stb),
        .wb_we_o(wbm_we),
        .wb_adr_o(wbm_adr),
        .wb_dat_o(wbm_dat_i),
        .wb_dat_i(wbm_dat_o),
        .wb_ack_i(wbm_ack)
    );

    wb_rom #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(DATA_WIDTH),
        .INIT_FILE("imdata.hex")
    ) rom (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .wb_cyc_i(wbs0_cyc),
        .wb_stb_i(wbs0_stb),
        .wb_adr_i(wbs0_adr[9:2]),
        .wb_dat_o(wbs0_dat_o),
        .wb_ack_o(wbs0_ack)
    );

    wb_ram #(
        .ADDR_WIDTH(8),
        .DATA_WIDTH(DATA_WIDTH)
    ) ram (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .wb_cyc_i(wbs2_cyc),
        .wb_stb_i(wbs2_stb),
        .wb_we_i(wbs2_we),
        .wb_adr_i(wbs2_adr[9:2]),
        .wb_dat_i(wbs2_dat_o),
        .wb_dat_o(wbs2_dat_i),
        .wb_ack_o(wbs2_ack)
    );


    wb_mux_3 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) bus (
        .clk(clk_i),
        .rst(rst_i),

        .wbm_adr_i(wbm_adr),
        .wbm_dat_i(wbm_dat_i),
        .wbm_dat_o(wbm_dat_o),
        .wbm_we_i(wbm_we),
        .wbm_sel_i(4'b1111),
        .wbm_stb_i(wbm_stb),
        .wbm_ack_o(wbm_ack),
        .wbm_err_o(),
        .wbm_rty_o(),
        .wbm_cyc_i(wbm_cyc),

        .wbs0_adr_o(wbs0_adr),
        .wbs0_dat_i(wbs0_dat_o),
        .wbs0_dat_o(),
        .wbs0_we_o(),
        .wbs0_sel_o(),
        .wbs0_stb_o(wbs0_stb),
        .wbs0_ack_i(wbs0_ack),
        .wbs0_err_i(),
        .wbs0_rty_i(),
        .wbs0_cyc_o(wbs0_cyc),
        .wbs0_addr(14'h0000),
        .wbs0_addr_msk(14'h3C00),

        .wbs1_addr(14'h0400),
        .wbs1_addr_msk(14'h3FFF),


        .wbs2_adr_o(wbs2_adr),
        .wbs2_dat_i(wbs2_dat_i),
        .wbs2_dat_o(wbs2_dat_o),
        .wbs2_we_o(wbs2_we),
        .wbs2_sel_o(),
        .wbs2_stb_o(wbs2_stb),
        .wbs2_ack_i(wbs2_ack),
        .wbs2_err_i(),
        .wbs2_rty_i(),
        .wbs2_cyc_o(wbs2_cyc),
        .wbs2_addr(14'h3C00),
        .wbs2_addr_msk(14'h3C00)
    );    
endmodule

module dma #(
    parameter ADDR_WIDTH = 8 ,
    parameter DATA_WIDTH = 32,
    parameter ADD_SOURCE = 0,
    parameter ADD_DESTIN = 255,
    parameter WORDS = 16
)(
    // Sinais de Sistema
    input  wire                    clk_i,
    input  wire                    rst_i,
    output reg                     done_o,
    
    // Interface Wishbone Master
    output  reg                     wb_cyc_o,
    output  reg                     wb_stb_o,
    output  reg                     wb_we_o,
    output  reg  [ADDR_WIDTH-1:0]   wb_adr_o,
    output  reg  [DATA_WIDTH-1:0]   wb_dat_o,
    input   wire [DATA_WIDTH-1:0]   wb_dat_i,
    input   wire                    wb_ack_i
);
    
    // Definição dos Estados
    localparam [1:0] IDLE  = 2'd0,
                    READ  = 2'd1,
                    WRITE = 2'd2,
                    DONE  = 2'd3;

    reg [1:0] state;

    // Registradores Internos
    reg [ADDR_WIDTH-1:0] current_src_adr;
    reg [ADDR_WIDTH-1:0] current_dst_adr;
    reg [31:0]           words_left;
    reg [DATA_WIDTH-1:0] data_buffer;

    always @(posedge clk_i) begin
        if (rst_i) begin
            state        <= IDLE;
            wb_cyc_o     <= 1'b0;
            wb_stb_o     <= 1'b0;
            wb_we_o      <= 1'b0;
            wb_adr_o     <= {ADDR_WIDTH{1'b0}};
            wb_dat_o     <= {DATA_WIDTH{1'b0}};
            done_o       <= 1'b0;
            words_left   <= 32'd0;
        end else begin
            // Valores padrão para pulsos e sinais de controle para evitar latches
            done_o   <= 1'b0;
            
            case (state)
                IDLE: begin
                    wb_cyc_o <= 1'b0;
                    wb_stb_o <= 1'b0;
                    current_src_adr <= ADD_SOURCE;
                    current_dst_adr <= ADD_DESTIN;
                    words_left      <= WORDS;
                    state           <= READ;
                end

                READ: begin
                    // Configura barramento para leitura
                    wb_cyc_o <= 1'b1;
                    wb_stb_o <= 1'b1;
                    wb_we_o  <= 1'b0;
                    wb_adr_o <= current_src_adr;

                    // Aguarda a memória escrava responder
                    if (wb_ack_i) begin
                        data_buffer <= wb_dat_i; // Salva o dado lido
                        wb_cyc_o    <= 1'b0;     // Encerra ciclo de leitura
                        wb_stb_o    <= 1'b0;
                        state       <= WRITE;
                    end
                end

                WRITE: begin
                    // Configura barramento para escrita
                    wb_cyc_o <= 1'b1;
                    wb_stb_o <= 1'b1;
                    wb_we_o  <= 1'b1;
                    wb_adr_o <= current_dst_adr;
                    wb_dat_o <= data_buffer;

                    // Aguarda a memória escrava responder
                    if (wb_ack_i) begin
                        wb_cyc_o <= 1'b0; // Encerra ciclo de escrita
                        wb_stb_o <= 1'b0;
                        
                        // Atualiza endereços (assumindo endereçamento por palavra. Se for por byte, some 4)
                        current_src_adr <= current_src_adr + 1'b1;
                        current_dst_adr <= current_dst_adr + 1'b1;
                        
                        words_left <= words_left - 1'b1;

                        if (words_left == 1) begin
                            state <= DONE;
                        end else begin
                            state <= READ;
                        end
                    end
                end

                DONE: begin
                    done_o <= 1'b1; // Pulso de conclusão
                    state  <= DONE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule


module wb_rom #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter INIT_FILE  = "rom_data.hex" // Arquivo com os dados iniciais
)(
    // Sinais de Sistema
    input  wire                    clk_i,
    input  wire                    rst_i,
    
    // Interface Wishbone
    input  wire                    wb_cyc_i,
    input  wire                    wb_stb_i,
    input  wire [ADDR_WIDTH-1:0]   wb_adr_i,
    output reg  [DATA_WIDTH-1:0]   wb_dat_o,
    output reg                     wb_ack_o
);

    // Declaração do array de memória
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Inicialização da ROM a partir de um arquivo
    initial begin
        $readmemh(INIT_FILE, mem);
    end

    // Condição para um acesso válido ao barramento
    wire valid_access = wb_cyc_i & wb_stb_i;

    always @(posedge clk_i) begin
        if (rst_i) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= {DATA_WIDTH{1'b0}};
        end else begin
            wb_ack_o <= 1'b0;
            
            // Tratamento da Leitura
            if (valid_access && !wb_ack_o) begin
                wb_ack_o <= 1'b1; // Confirma a leitura
                wb_dat_o <= mem[wb_adr_i]; // Coloca o dado no barramento
            end
        end
    end

endmodule


module wb_ram #(
    parameter ADDR_WIDTH = 8,  // Largura do endereço (2^8 = 256 posições)
    parameter DATA_WIDTH = 32  // Largura dos dados (32 bits)
)(
    // Sinais de Sistema
    input  wire                    clk_i,
    input  wire                    rst_i,
    
    // Interface Wishbone
    input  wire                    wb_cyc_i,
    input  wire                    wb_stb_i,
    input  wire                    wb_we_i,
    input  wire [ADDR_WIDTH-1:0]   wb_adr_i,
    input  wire [DATA_WIDTH-1:0]   wb_dat_i,
    output reg  [DATA_WIDTH-1:0]   wb_dat_o,
    output reg                     wb_ack_o
);

    // Declaração do array de memória
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Condição para um acesso válido ao barramento
    wire valid_access = wb_cyc_i & wb_stb_i;

    always @(posedge clk_i) begin
        if (rst_i) begin
            wb_ack_o <= 1'b0;
            wb_dat_o <= {DATA_WIDTH{1'b0}};
        end else begin
            // Por padrão, o ACK desce após 1 ciclo
            wb_ack_o <= 1'b0; 
            
            // Se houver um acesso válido e ainda não enviamos o ACK
            if (valid_access && !wb_ack_o) begin
                wb_ack_o <= 1'b1; // Sinaliza que a operação vai terminar neste ciclo
                
                if (wb_we_i) begin
                    // Operação de Escrita
                    mem[wb_adr_i] <= wb_dat_i;
                end else begin
                    // Operação de Leitura
                    wb_dat_o <= mem[wb_adr_i];
                end
            end
        end
    end

endmodule


/*
 * Wishbone 3 port multiplexer
 */
module wb_mux_3 #
(
    parameter DATA_WIDTH = 8,                     // width of data bus in bits (8, 16, 32, or 64)
    parameter ADDR_WIDTH = 8,                     // width of address bus in bits
    parameter SELECT_WIDTH = (DATA_WIDTH/8)       // width of word select bus (1, 2, 4, or 8)
)
(
    input  wire                    clk,
    input  wire                    rst,

    /*
     * Wishbone master input
     */
    input  wire [ADDR_WIDTH-1:0]   wbm_adr_i,     // ADR_I() address input
    input  wire [DATA_WIDTH-1:0]   wbm_dat_i,     // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbm_dat_o,     // DAT_O() data out
    input  wire                    wbm_we_i,      // WE_I write enable input
    input  wire [SELECT_WIDTH-1:0] wbm_sel_i,     // SEL_I() select input
    input  wire                    wbm_stb_i,     // STB_I strobe input
    output wire                    wbm_ack_o,     // ACK_O acknowledge output
    output wire                    wbm_err_o,     // ERR_O error output
    output wire                    wbm_rty_o,     // RTY_O retry output
    input  wire                    wbm_cyc_i,     // CYC_I cycle input

    /*
     * Wishbone slave 0 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs0_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs0_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs0_dat_o,    // DAT_O() data out
    output wire                    wbs0_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs0_sel_o,    // SEL_O() select output
    output wire                    wbs0_stb_o,    // STB_O strobe output
    input  wire                    wbs0_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs0_err_i,    // ERR_I error input
    input  wire                    wbs0_rty_i,    // RTY_I retry input
    output wire                    wbs0_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 0 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs0_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs0_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 1 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs1_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs1_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs1_dat_o,    // DAT_O() data out
    output wire                    wbs1_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs1_sel_o,    // SEL_O() select output
    output wire                    wbs1_stb_o,    // STB_O strobe output
    input  wire                    wbs1_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs1_err_i,    // ERR_I error input
    input  wire                    wbs1_rty_i,    // RTY_I retry input
    output wire                    wbs1_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 1 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs1_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs1_addr_msk, // Slave address prefix mask

    /*
     * Wishbone slave 2 output
     */
    output wire [ADDR_WIDTH-1:0]   wbs2_adr_o,    // ADR_O() address output
    input  wire [DATA_WIDTH-1:0]   wbs2_dat_i,    // DAT_I() data in
    output wire [DATA_WIDTH-1:0]   wbs2_dat_o,    // DAT_O() data out
    output wire                    wbs2_we_o,     // WE_O write enable output
    output wire [SELECT_WIDTH-1:0] wbs2_sel_o,    // SEL_O() select output
    output wire                    wbs2_stb_o,    // STB_O strobe output
    input  wire                    wbs2_ack_i,    // ACK_I acknowledge input
    input  wire                    wbs2_err_i,    // ERR_I error input
    input  wire                    wbs2_rty_i,    // RTY_I retry input
    output wire                    wbs2_cyc_o,    // CYC_O cycle output

    /*
     * Wishbone slave 2 address configuration
     */
    input  wire [ADDR_WIDTH-1:0]   wbs2_addr,     // Slave address prefix
    input  wire [ADDR_WIDTH-1:0]   wbs2_addr_msk  // Slave address prefix mask
);

wire wbs0_match = ~|((wbm_adr_i ^ wbs0_addr) & wbs0_addr_msk);
wire wbs1_match = ~|((wbm_adr_i ^ wbs1_addr) & wbs1_addr_msk);
wire wbs2_match = ~|((wbm_adr_i ^ wbs2_addr) & wbs2_addr_msk);

wire wbs0_sel = wbs0_match;
wire wbs1_sel = wbs1_match & ~(wbs0_match);
wire wbs2_sel = wbs2_match & ~(wbs0_match | wbs1_match);

wire master_cycle = wbm_cyc_i & wbm_stb_i;

wire select_error = ~(wbs0_sel | wbs1_sel | wbs2_sel) & master_cycle;

// master
assign wbm_dat_o = wbs0_sel ? wbs0_dat_i :
                   wbs1_sel ? wbs1_dat_i :
                   wbs2_sel ? wbs2_dat_i :
                   {DATA_WIDTH{1'b0}};

assign wbm_ack_o = wbs0_ack_i |
                   wbs1_ack_i |
                   wbs2_ack_i;

assign wbm_err_o = wbs0_err_i |
                   wbs1_err_i |
                   wbs2_err_i |
                   select_error;

assign wbm_rty_o = wbs0_rty_i |
                   wbs1_rty_i |
                   wbs2_rty_i;

// slave 0
assign wbs0_adr_o = wbm_adr_i;
assign wbs0_dat_o = wbm_dat_i;
assign wbs0_we_o = wbm_we_i & wbs0_sel;
assign wbs0_sel_o = wbm_sel_i;
assign wbs0_stb_o = wbm_stb_i & wbs0_sel;
assign wbs0_cyc_o = wbm_cyc_i & wbs0_sel;

// slave 1
assign wbs1_adr_o = wbm_adr_i;
assign wbs1_dat_o = wbm_dat_i;
assign wbs1_we_o = wbm_we_i & wbs1_sel;
assign wbs1_sel_o = wbm_sel_i;
assign wbs1_stb_o = wbm_stb_i & wbs1_sel;
assign wbs1_cyc_o = wbm_cyc_i & wbs1_sel;

// slave 2
assign wbs2_adr_o = wbm_adr_i;
assign wbs2_dat_o = wbm_dat_i;
assign wbs2_we_o = wbm_we_i & wbs2_sel;
assign wbs2_sel_o = wbm_sel_i;
assign wbs2_stb_o = wbm_stb_i & wbs2_sel;
assign wbs2_cyc_o = wbm_cyc_i & wbs2_sel;


endmodule

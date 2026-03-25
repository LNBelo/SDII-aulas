///////
// SOMADOR / SUBTRATOR
///////

module add_sub #(
    parameter N = 8
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    input  wire sub,              // 0: soma (A+B), 1: subtração (A-B)
    output wire [N-1:0] result,
    output wire         cout,  // carry out
    output wire         overflow, // overflow em complemento de 2
    output wire         negative // result[N-1]: resultado negativo
);
    wire [N-1:0] b_comp;
    wire [N:0]   soma_ext;         

    // se sub=1 inverte b para soma em comp2
    assign b_comp   = b ^ {N{sub}};
    assign soma_ext = {1'b0, a} + {1'b0, b_comp} + sub;

    assign result   = soma_ext[N-1:0];
    assign cout     = soma_ext[N];
    assign negative = result[N-1];

    // overflow em complemento de 2
    assign overflow = ~(a[N-1] ^ b_comp[N-1]) & (a[N-1] ^ result[N-1]);
endmodule


///////
// REGISTRADOR N BITS
///////

module register #(
    parameter N = 8
)(
    input  wire         clk, // reset
    input  wire         rst,
    input  wire         load, // load enable
    input  wire [N-1:0] data_in,
    output reg  [N-1:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= {N{1'b0}};
        else if (load)
            data_out <= data_in;
    end
endmodule


///////
// REGISTRADOR COM DESLOCAMENTO À ESQUERDA
///////

module shift_left #(
    parameter N = 8
)(
    input  wire         clk,
    input wire rst, // reset
    input wire load, // load
    input wire shift, // desloca para a esquerda
    input  wire [N-1:0] data_in,
    output reg  [N-1:0] data_out
);
    always @(posedge clk) begin
        if (rst)
            data_out <= {N{1'b0}};
        else if (load)
            data_out <= data_in;
        else if (shift)
            data_out <= {data_out[N-2:0], 1'b0}; // shift left com entrada 0
    end
endmodule


///////
// MUX 2:1
///////

module mux2 #(
    parameter N = 8
)(
    input  wire [N-1:0] I0,
    input  wire [N-1:0] I1,
    input  wire         sel,
    output wire [N-1:0] y
);
    assign y = sel ? I1 : I0;
endmodule


///////
// FLUXO DE DADOS
///////

module df #(
    parameter N = 8
    )(
    input wire clk,
    input wire rst,

    // Carregamento inicial
    input wire load_m, // M <- divisor
    input wire [N-1:0] divisor,
    input wire load_aq, // A <-0 , Q ← dividend
    input wire [N-1:0] dividend,

    // Controles da UC
    input wire shift_aq, // desloca {A,Q} 1 bit a esquerda
    input wire update_a, // escreve resultado da ULA em {A,Q}

    // Saıdas
    output wire [N-1:0] M,
    output wire [N-1:0] A, // resto parcial (MSBs de {A,Q})
    output wire [N-1:0] Q, // quociente (LSBs de {A,Q})
    output wire negative // (A-M) < 0 -> UC observa (opcional)
    );

    wire [2*N-1:0] aq_reg;
    wire [2*N-1:0] aq_init;
    wire [2*N-1:0] aq_next;
    wire [2*N-1:0] aq_data_in;

    wire [N-1:0] a_sub;
    wire         cout_sub;
    wire         ovf_sub;

    // M = divisor
    register #(.N(N)) reg_m (
        .clk(clk),
        .rst(rst),
        .load(load_m),
        .data_in(divisor),
        .data_out(M)
    );

    // estado atual de {A,Q}
    assign A = aq_reg[2*N-1:N];
    assign Q = aq_reg[N-1:0];

    // carga inicial: A <- 0, Q <- dividend
    assign aq_init = {{N{1'b0}}, dividend};

    // subtração A - M
    add_sub #(.N(N)) alu (
        .a(A),
        .b(M),
        .sub(1'b1),
        .result(a_sub),
        .cout(cout_sub),
        .overflow(ovf_sub),
        .negative(negative)
    );

    // passo de update do restoring division:
    // se A-M < 0 => restaura A e Q[0]=0
    // senão      => A <- A-M e Q[0]=1
    assign aq_next = negative
                   ? {A,     {Q[N-1:1], 1'b0}}
                   : {a_sub, {Q[N-1:1], 1'b1}};

    // MUX para decidir entre carga inicial e atualização após subtração
    mux2 #(.N(2*N)) mux_aq (
        .I0(aq_next),
        .I1(aq_init),
        .sel(load_aq),
        .y(aq_data_in)
    );

    // registrador {A,Q} com shift
    shift_left #(.N(2*N)) reg_aq (
        .clk(clk),
        .rst(rst),
        .load(load_aq | update_a),
        .shift(shift_aq),
        .data_in(aq_data_in),
        .data_out(aq_reg)
    );

endmodule


///////
// EXERCICIO 2
// UNIDADE DE CONTROLE
///////

module uc #(
    parameter N = 24
)(
    input  wire clk,
    input  wire rst,
    input  wire start,

    output reg  load_m,
    output reg  load_aq,
    output reg  shift_aq,
    output reg  update_a,
    output wire done
);
    // Definicao estados
    localparam [1:0]
        IDLE   = 2'b00,
        SHIFT  = 2'b01,
        UPDATE = 2'b10,
        DONE   = 2'b11;

    reg [1:0] state, next_state;
    integer count;

    assign done = (state == DONE);

    // registradores de estado e contador
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
        end else begin
            state <= next_state;

            // Gerenciamento do contador do loop
            if (state == IDLE && start)
                count <= N;  // Inicializa o contador com o numero de bits
            else if (state == UPDATE)
                count <= count - 1; // Decrementa a cada ciclo de atualizacao
        end
    end

    // lógica combinacional
    always @(*) begin
        load_m   = 1'b0;
        load_aq  = 1'b0;
        shift_aq = 1'b0;
        update_a = 1'b0;
        next_state = state;

        case (state)
            IDLE: begin
                if (start) begin
                    load_m    = 1'b1; // Carrega o divisor em M
                    load_aq   = 1'b1; // Carrega o dividendo em Q e zera A
                    next_state = SHIFT;
                end
            end

            SHIFT: begin
                shift_aq   = 1'b1; // Desloca {A, Q} 1 bit a esquerda
                next_state = UPDATE;
            end

            UPDATE: begin
                update_a = 1'b1; // fluxo de dados escreve o resultado da ULA
                if (count > 1)
                    next_state = SHIFT; // Repete para todos os N bits
                else
                    next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule


///////
// TOPO: RESTORING DIVISION
///////

module restoring_div #(
    parameter N = 8
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire [N-1:0] dividend,
    input  wire [N-1:0] divisor,
    output wire [N-1:0] quotient,
    output wire [N-1:0] remainder,
    output wire         done
);

    wire load_m, load_aq, shift_aq, update_a;
    wire [N-1:0] M, A, Q;
    wire negative;

    uc #(.N(N)) control_unit (
        .clk(clk),
        .rst(rst),
        .start(start),
        .load_m(load_m),
        .load_aq(load_aq),
        .shift_aq(shift_aq),
        .update_a(update_a),
        .done(done)
    );

    df #(.N(N)) datapath (
        .clk(clk),
        .rst(rst),
        .load_m(load_m),
        .divisor(divisor),
        .load_aq(load_aq),
        .dividend(dividend),
        .shift_aq(shift_aq),
        .update_a(update_a),
        .M(M),
        .A(A),
        .Q(Q),
        .negative(negative)
    );

    assign quotient  = Q;
    assign remainder = A;

endmodule
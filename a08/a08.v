///////
// SOMADOR SUBTRADOR
///////

module add_sub #(
    parameter N = 8
    )(
    input wire [N-1:0] a,
    input wire [N-1:0] b,
    input wire sub, // 0: soma (A+B), 1: subtração (A-B)
    output wire [N-1:0] result,
    output wire cout, // carry out
    output wire overflow, // overflow em complemento de 2
    output wire negative // result[N-1]: resultado negativo
    );
    wire [N-1:0] b_comp;
    wire [N-1:0] soma_ext;

    // se sub=1 inverte b para soma em comp2
    assign b_comp = b ^ {N{sub}};

    assign soma_ext = {1'b0, a} + {1'b0, b_comp} + sub;

    assign result = soma_ext[N-1:0];
    assign cout = soma_ext[N];
    assign negative = result[N-1];

    assign overflow = (~(a[N-1] ^ b_comp[N-1])) & (a[N-1] ^ result[N-1]);
endmodule

///////
// REGISTRADOR
///////

module register #(
    parameter N = 8
)(
    input wire clk,
    input wire rst,      // reset
    input wire load,     // load enable
    input wire [N-1:0] data_in,
    output reg [N-1:0] data_out
);

    always @(posedge clk) begin
        if (rst) begin
            data_out <= {N{1'b0}}; 
        end 
        else if (load) begin
            data_out <= data_in;   
        end
    end

endmodule

///////
// SHIFT_LEFT
///////

module shift_left #(
    parameter N = 8
    )(
    input wire clk,
    input wire rst, // reset
    input wire load, // load
    input wire shift, // desloca para a esquerda
    input wire [N-1:0] data_in,
    output reg [N-1:0] data_out
    );
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 1; i < N; i = i + 1) begin
                data_out[i] <= 1'b0;
            end
            data_out[0] <= 1'b1;
        end
        else begin
            if (load) begin
                data_out <= data_in;
            end
            else if (shift) begin
                for (i = 0; i < N-1; i = i + 1) begin
                    data_out[i+1] <= data_out[i];
                end
                data_out[0] <= 1'b1;
            end
        end
    end

endmodule

///////
// DF
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

    // Saidas
    output wire [N-1:0] M,
    output wire [N-1:0] A, // resto parcial (MSBs de {A,Q})
    output wire [N-1:0] Q, // quociente (LSBs de {A,Q})
    output wire negative // (A-M) < 0 -> UC observa (opcional)
    );

    register #(.N(N)) reg_M (
        .clk(clk),
        .rst(rst),
        .load(),
        .data_in(),
        .data_out()
    );
    register #(.N(N)) reg_A (
        .clk(clk),
        .rst(rst),
        .load(),
        .data_in(),
        .data_out()
    );
    register #(.N(N)) reg_Q (
        .clk(clk),
        .rst(rst),
        .load(),
        .data_in(),
        .data_out()
    );

    add_sub #(.N(N)) a_s_1 (
        .a(),
        .b(),
        .sub(),
        .result(),
        .cout(),
        .overflow(),
        .negative()
    );
    shift_left #(.N(8)) shifter (
        .clk(clk),
        .rst(rst),
        .load(),
        .shift(),
        .data_in(),
        .data_out()
    );

endmodule

///////
// EXERCICIO 2
// UNIDADE DE CONTROLE
///////

module uc #(parameter N=24)(
    input wire clk, 
    input wire rst,
    input wire start,

    output reg load_m,
    output reg load_aq,
    output reg shift_aq,
    output reg update_a,
    output wire done
);

    // Definicao estados
    localparam [1:0]
        IDLE   = 2'b00,
        SHIFT  = 2'b01,
        UPDATE = 2'b10,
        DONE   = 2'b11;

    reg [1:0] state, next_state;
    reg [31:0] count; // Contador param N

    assign done = (state == DONE);

    // Controle contador
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
        end else begin
            state <= next_state;
            
            // Gerenciamento do contador do loop
            if (state == IDLE && start) begin
                count <= N; // Inicializa o contador com o numero de bits
            end else if (state == UPDATE) begin
                count <= count - 1; // Decrementa a cada ciclo de atualizacao
            end
        end
    end

    // Proximo estado e controle de saidas
    always @(*) begin
        next_state = state;
        load_m     = 1'b0;
        load_aq    = 1'b0;
        shift_aq   = 1'b0;
        update_a   = 1'b0;

        case (state)
            IDLE: begin
                if (start) begin
                    load_m  = 1'b1; // Carrega o divisor em M
                    load_aq = 1'b1; // Carrega o dividendo em Q e zera A
                    next_state = SHIFT;
                end
            end
            
            SHIFT: begin
                shift_aq = 1'b1; // Desloca {A, Q} 1 bit à esquerda
                next_state = UPDATE;
            end
            
            UPDATE: begin
                update_a = 1'b1; // fluxo de dados escreve o resultado da ULA
                if (count > 1) begin
                    next_state = SHIFT; // Repete para todos os N bits
                end else begin
                    next_state = DONE;
                end
            end
            
            DONE: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule

///////
// EXERCICIO 3
// RESTORING DIVISION
///////

module restoring_div #(
    parameter N = 8
    )(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [N-1:0] dividend, // dividendo (N bits)
    input wire [N-1:0] divisor, // divisor (N bits)
    output wire [N-1:0] quotient, // quociente
    output wire [N-1:0] remainder, // resto
    output wire done
    );

endmodule



module mux2 #(
    parameter N = 8
) (
    input  wire [N-1:0] I0,
    input  wire [N-1:0] I1,
    input  wire sel,
    output wire [N-1:0] y
);

    assign y = sel ? I1 : I0;

endmodule
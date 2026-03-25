`timescale 1ns / 1ps
`include "a08.v"

module tb_restoring_div();

    localparam N = 8;
    reg clk, rst, start;
    reg [N-1:0] dividend, divisor;
    wire [N-1:0] quotient, remainder;
    wire done;

    // A instanciação continua exatamente igual
    restoring_div #(.N(N)) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .dividend(dividend),
        .divisor(divisor),
        .quotient(quotient),
        .remainder(remainder),
        .done(done)
    );

    // Geração do Clock (Período de 10ns)
    always #5 clk = ~clk;

    // Tarefa para facilitar a execução de testes repetitivos
    task run_test(input [N-1:0] test_dividend, input [N-1:0] test_divisor);
        begin
            // Sincroniza com a borda de descida do clock para mudar entradas
            @(negedge clk); 
            dividend = test_dividend;
            divisor  = test_divisor;
            start    = 1'b1;
            
            // Mantém o start em alto por 1 ciclo de clock
            @(negedge clk);
            start    = 1'b0;

            // Espera o sinal done ir para nível alto
            wait(done == 1'b1);
            
            // Imprime o resultado no console
            $display("Tempo: %0t | Divisao: %d / %d -> Quociente: %d, Resto: %d", 
                     $time, test_dividend, test_divisor, quotient, remainder);
                     
            #30; 
        end
    endtask

    // Bloco inicial de estímulos
    initial begin
        // Condições iniciais
        clk = 0;
        rst = 1;
        start = 0;
        dividend = 0;
        divisor = 0;

        // Aguarda um tempo e libera o reset
        #25;
        rst = 0;
        #10;

        $display("Iniciando simulacao do Restoring Division...");

        // Caso de Teste 1: Divisão normal com resto (45 / 6 = 7, resto 3)
        run_test(8'd45, 8'd6);

        // Caso de Teste 2: Divisão exata (100 / 25 = 4, resto 0)
        run_test(8'd100, 8'd25);

        // Caso de Teste 3: Dividendo menor que o divisor (5 / 12 = 0, resto 5)
        run_test(8'd5, 8'd12);

        // Caso de Teste 4: Valores máximos para 8 bits (255 / 15 = 17, resto 0)
        run_test(8'd255, 8'd15);

        $display("Simulacao concluida com sucesso!");
        $finish;
    end

endmodule
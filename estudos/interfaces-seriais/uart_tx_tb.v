`timescale 1ns/1ps

module uart_tx_tb;

    reg clk;
    reg rst;
    reg tx_start;
    reg [7:0] data;
    wire tx;

    // DIVISOR pequeno (100 / 10 = 10 ciclos por bit) só para a simulação
    // ficar rápida e fácil de ler no GTKWave. Os valores default
    // (50_000_000 / 9600) continuam sendo os usados em hardware real.
    uart_tx #(
        .CLK_FREQ(100),
        .BAUD_RATE(10)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .data(data),
        .tx(tx)
    );

    // Clock de 10ns de período (100MHz "simulado")
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, uart_tx_tb);

        rst      = 1;
        tx_start = 0;
        data     = 8'h55; // 01010101 - alterna 0/1, fácil de ver na forma de onda

        #50;       // segura o reset por 5 ciclos de clock
        rst = 0;
        #20;       // settle antes de iniciar a transmissão

        tx_start = 1;
        #100;      // segura tx_start por 1 período de baud inteiro (10 ciclos)
                    // garante que o baud_tick "veja" o tx_start em IDLE
        tx_start = 0;

        // 1 frame = 12 bits (8-E-2) * 10 ciclos/bit * 10ns/ciclo = 1200ns
        // espera o frame inteiro terminar, com folga
        #1500;

        $finish;
    end

endmodule

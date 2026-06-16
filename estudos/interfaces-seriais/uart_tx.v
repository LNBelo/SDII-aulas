module uart_tx (
    input clk,
    input rst,
    input tx_start,
    input [7:0] data, // [MSB:LSB]
    output tx // bit serrial saindo
);  
    // converter o clock para a frequencia de transmissão
    parameter CLK_FREQ = 50_000_000; // Ex. FPGA com 50MHZ
    parameter BAUD_RATE = 9600; // faixa de transmissão
    localparam DIVISOR = CLK_FREQ / BAUD_RATE;

    parameter largura = $clog2(DIVISOR)-1;
    reg [largura : 0] contador;
    reg baud_tick;

    always @(posedge clk) begin
        
    end

endmodule
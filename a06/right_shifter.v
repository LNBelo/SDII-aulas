module right_shifter #(parameter N = 8) (
    input wire clk, // Clock
    input wire rst, // Reset (active high)
    input wire [N-1:0] data_in, // Data input (loaded when shift_enable=0)
    input wire shift_enable, // Shift enable: 0=load, 1=shift right
    output wire [N-1:0] data_out // Data output (current register value)
);

reg [N-1:0] data_out_reg;

always @(posedge clk or posedge rst) begin
    if (rst) data_out_reg <= {1'b1, {(N-1){1'b0}}};
    else begin
        if (shift_enable) begin
            data_out_reg <= {1'b1, data_out[N-1:1]};
        end
        else begin
            data_out_reg <= {1'b1, data_in[N-2:0]};
        end
    end
    
end

assign data_out = data_out_reg;

endmodule

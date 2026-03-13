module rom_16(addr, CS, OE, out);
  input [3:0] addr;
  input CS, OE;
  output reg [15:0] out;
  reg [15:0] data[15:0];
  initial
    for (integer i = 0; i < 16; i++)
      data[i]=~i[15:0];
      
  always @(addr, CS, OE)
    if (OE==1'b1)
      out=data[addr];
    else
      out=16'bz;
endmodule
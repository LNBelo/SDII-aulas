module ram_4(in, addr, RW, CS, OE, out);
  input [15:0] in;
  input [1:0] addr;
  input RW, CS, OE;
  output reg [15:0] out;
  reg [15:0] data[3:0];
  
  always @(addr, CS, OE, RW)
  begin
    if(RW==1'b0 & OE==1'b1)
      out=data[addr];
    else
      out=16'bz;
    if(RW==1'b1)
      data[addr]=in;
  end
endmodule
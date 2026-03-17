module rom_16(addr, CS, OE, out);
  input [3:0] addr;
  input CS, OE;
  output reg [15:0] out;
  reg [15:0] data[15:0];
  initial
    for (integer i = 0; i < 16; i++)
      data[i]=~i[15:0];
  always @(addr, CS, OE)
    if (OE==1'b1 & CS==1'b1)
      out=data[addr];
    else
      out=16'bz;
endmodule


module ram_4(in, addr, RW, CS, OE, out);
  input [15:0] in;
  input [1:0] addr;
  input RW, CS, OE;
  output reg [15:0] out;
  reg [15:0] data[3:0];
  always @(in, addr, CS, OE, RW)
  begin
    if(RW==1'b0 & OE==1'b1 & CS==1'b1)
      out=data[addr];
    else
      out=16'bz;
    if(RW==1'b1 & CS==1'b1)
      data[addr]=in;
  end
endmodule


module ram_8 (in, addr, RW, CS, OE, out);
    input [15:0] in;
    input [2:0] addr;
    input RW, CS, OE;
    output wire [15:0] out;

    wire CS0 = CS & ~addr[2];
    wire CS1 = CS & addr[2];

    ram_4 ram0 (
        .in(in),
        .addr(addr[1:0]),
        .RW(RW),
        .CS(CS0),
        .OE(OE),
        .out(out)
    );

    ram_4 ram1 (
        .in(in),
        .addr(addr[1:0]),
        .RW(RW),
        .CS(CS1),
        .OE(OE),
        .out(out)
    );
endmodule

module memchip_64 (in, addr, RW, out);
    input [15:0] in;
    input [5:0] addr;
    input RW;
    output [15:0] out;

    wire CS0, CS1, CS2;
    assign CS0 = ~addr[5] & ~addr[4];
    assign CS1 = ~addr[5] & addr[4] & ~addr[3];
    assign CS2 = addr[5] & ~addr[4] & addr[3];

    rom_16 rom0 (
        .addr(addr[3:0]),
        .CS(CS0),
        .OE(1'b1),
        .out(out)
    );

    ram_8 ram1 (
        .in(in),
        .addr(addr[2:0]),
        .RW(RW),
        .CS(CS1),
        .OE(1'b1),
        .out(out)
    );

    ram_8 ram2 (
        .in(in),
        .addr(addr[2:0]),
        .RW(RW),
        .CS(CS2),
        .OE(1'b1),
        .out(out)
    );

endmodule
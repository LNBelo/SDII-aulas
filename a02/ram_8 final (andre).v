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
  always @(addr, CS, OE, RW, in)
  begin
    if(RW==1'b0 & OE==1'b1 & CS==1'b1)
      out=data[addr];
    else
      out=16'bz;
    if(RW==1'b1 & CS==1'b1)
      data[addr]=in;
  end
endmodule


module ram_8(in, addr, RW, CS, OE, out);
    input [15:0] in;
    input [2:0] addr; // Vai de 0 a 8
    input RW, CS, OE;
    output wire [15:0] out;

    wire CS_ram1 = CS & ~addr[2]; // Ativa quando CS=1 e addr[2]=0
    wire CS_ram2 = CS & addr[2];  // Ativa quando CS=1 e addr[2]=1

    ram_4 ram1(
        .in(in),
        .addr(addr[1:0]),
        .RW(RW),
        .CS(CS_ram1),
        .OE(OE),
        .out(out)
    );

    ram_4 ram2(
        .in(in),
        .addr(addr[1:0]),
        .RW(RW),
        .CS(CS_ram2),
        .OE(OE),
        .out(out)
    );
endmodule

module memchip_64(in, addr, RW, out);
    input [15:0] in;
    input [5:0] addr; // Vai de 0 a 63
    input RW;

    parameter OE = 1'b1;
    output wire [15:0] out;

    wire CS_rom;
    assign CS_rom = ~addr[5] & ~addr[4];

    wire CS_ram1_8;
    assign CS_ram1_8 = ~addr[5] & addr[4] & ~addr[3];

    wire CS_ram2_8;
    assign CS_ram2_8 = addr[5] & ~addr[4] & addr[3];
       
    rom_16 rom1(
        .addr(addr[3:0]),
        .CS(CS_rom),
        .OE(OE),
        .out(out)
    );

    ram_8 ram1_8(
        .in(in),
        .addr(addr[2:0]),
        .RW(RW),
        .CS(CS_ram1_8),
        .OE(OE),
        .out(out)
    );

    ram_8 ram2_8(
        .in(in),
        .addr(addr[2:0]),
        .RW(RW),
        .CS(CS_ram2_8),
        .OE(OE),
        .out(out)
    );

endmodule
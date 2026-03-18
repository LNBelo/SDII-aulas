module full_subtractor_nbit #(
    parameter N = 8
) (
    input [N-1:0] a, // minuendo
    input [N-1:0] b, // subtraendo
    input bin, // borrow in
    output [N-1:0] diff, // diferen¸ca
    output bout // borrow out
);

    wire [N:0] borrow;
    assign borrow[0] = bin;
    assign bout = borrow[N];

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : sub_loop
            full_subtractor_1bit fs (
                .a(a[i]),
                .b(b[i]),
                .bin(borrow[i]),
                .diff(diff[i]),
                .bout(borrow[i+1])
            );
        end
    endgenerate

endmodule
module small_alu (
    input wire [7:0] A,
    input wire [7:0] B,
    output wire [7:0] diff, // diff = |A-B|
    output wire A_gt_B, // A > B
    output wire A_eq_B, // A == B
    output wire A_lt_B // A < B
);

    wire bout;
    wire [7:0] diffAB;
    wire [7:0] diffBA;

full_subtractor_nbit #(8) fsn (
    .a(A), // minuendo
    .b(B), // subtraendo
    .bin(1'b0), // borrow in
    .diff(diffAB), // diferença
    .bout(bout)
);

full_subtractor_nbit #(8) fsn2 (
    .a(B), // minuendo
    .b(A), // subtraendo
    .bin(1'b0), // borrow in
    .diff(diffBA), // diferença
    .bout(bout)
);

cmp_ab cmp(
    .A(A),
    .B(B),
    .A_gt_B(A_gt_B), // A > B
    .A_lt_B(A_lt_B), // A < B
    .A_eq_B(A_eq_B) // A == B
);

assign diff = (A_gt_B) ? diffAB : diffBA;

endmodule
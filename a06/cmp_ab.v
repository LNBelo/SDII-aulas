module cmp_ab (
    input wire [7:0] A,
    input wire [7:0] B,
    output wire A_gt_B, // A > B
    output wire A_lt_B, // A < B
    output wire A_eq_B // A == B
);

wire [7:0] gt;
wire [7:0] eq;

assign gt = A & ~B;
assign eq = ~(A ^ B);

assign A_gt_B = gt[7]
| (eq[7] & gt[6])
| (eq[7] & eq[6] & gt[5])
| (eq[7] & eq[6] & eq[5] & gt[4])
| (eq[7] & eq[6] & eq[5] & eq[4] & gt[3])
| (eq[7] & eq[6] & eq[5] & eq[4] & eq[3] & gt[2])
| (eq[7] & eq[6] & eq[5] & eq[4] & eq[3] & eq[2] & gt[1])
| (eq[7] & eq[6] & eq[5] & eq[4] & eq[3] & eq[2] & eq[1] & gt[0]);

assign A_eq_B = &eq;

assign A_lt_B = ~A_gt_B & ~A_eq_B;

endmodule
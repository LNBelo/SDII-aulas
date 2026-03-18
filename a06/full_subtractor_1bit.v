module full_subtractor_1bit (
    input a, // minuendo
    input b, // subtraendo
    input bin, // borrow in
    output diff, // diferen¸ca
    output bout // borrow out
);

    assign diff = a ^ b ^ bin;
    assign bout = (~a & b) | (~(a ^ b) & bin);

endmodule
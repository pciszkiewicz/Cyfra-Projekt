module delay_test(
    input logic clk,
    input logic rst_n,

    input logic [10:0] hcount_in,
    input logic [10:0] vcount_in,
    input logic vsync_in,
    input logic hsync_in,

    output logic [10:0] hcount_out,
    output logic [10:0] vcount_out,
    output logic vsync_out,
    output logic hsync_out
);

delay #(
    .WIDTH(24),
    .CLK_DEL(4)
) u_delay (
    .clk(clk),
    .rst_n(rst_n),
    .din({hcount_in, hsync_in, vcount_in, vsync_in}),
    .dout({hcount_out, hsync_out, vcount_out, vsync_out})
);

endmodule

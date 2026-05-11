/**
 * MTM UEC2
 * Modified by: Piotr Ciszkiewicz
 *
 * Description:
 * Top level synthesizable module.
 */

 module top_vga_basys3 (
    input  logic       clk,
    input  logic       btnC,
    output logic       Vsync,
    output logic       Hsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    output logic       JA1,
    inout  wire        PS2Clk,
    inout  wire        PS2Data
);

logic       locked;
logic       pclk;
logic       clk_100MHz;
logic       pclk_mirror;

logic [1:0] rst_pclk_sync_n;
logic [1:0] rst_100m_sync_n;
logic       async_rst_n;

assign JA1 = pclk_mirror;
assign async_rst_n = ~(btnC || !locked);

clk_wiz_0 u_clk_wiz (
    .clk(clk),
    .clk100MHz(clk_100MHz),
    .clk40MHz(pclk),
    .locked(locked)
);

always_ff @(posedge pclk or negedge async_rst_n) begin
    if (!async_rst_n) begin
        rst_pclk_sync_n <= 2'b00;
    end else begin
        rst_pclk_sync_n <= {rst_pclk_sync_n[0], 1'b1};
    end
end

always_ff @(posedge clk_100MHz or negedge async_rst_n) begin
    if (!async_rst_n) begin
        rst_100m_sync_n <= 2'b00;
    end else begin
        rst_100m_sync_n <= {rst_100m_sync_n[0], 1'b1};
    end
end

ODDR pclk_oddr (
    .Q(pclk_mirror),
    .C(pclk),
    .CE(1'b1),
    .D1(1'b1),
    .D2(1'b0),
    .R(1'b0),
    .S(1'b0)
);

top_vga u_top_vga (
    .clk(pclk),
    .clk100MHz(clk_100MHz),
    .rst_pclk_n(rst_pclk_sync_n[1]),
    .rst_100m_n(rst_100m_sync_n[1]),
    .vs(Vsync),
    .hs(Hsync),
    .r(vgaRed),
    .g(vgaGreen),
    .b(vgaBlue),
    .ps2_clk(PS2Clk),
    .ps2_data(PS2Data)
);

endmodule
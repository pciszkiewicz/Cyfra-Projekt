/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * Mouse cursor drawing module.
 */

 module draw_mouse (
    input  logic        clk,
    input  logic        rst_n,
    vga_if.out          out,
    vga_if.in           in,
    input  logic [11:0] xpos,
    input  logic [11:0] ypos
);

logic [11:0] m_rgb_out;

MouseDisplay u_mouse_display (
    .pixel_clk(clk),
    .xpos(xpos),
    .ypos(ypos),
    .hcount(in.hcount),
    .vcount(in.vcount),
    .blank(in.hblnk || in.vblnk),
    .rgb_in(in.rgb),
    .rgb_out(m_rgb_out),
    .enable_mouse_display_out()
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= '0;
        out.vsync  <= '0;
        out.vblnk  <= '0;
        out.hcount <= '0;
        out.hsync  <= '0;
        out.hblnk  <= '0;
        out.rgb    <= '0;
    end else begin
        out.vcount <= in.vcount;
        out.vsync  <= in.vsync;
        out.vblnk  <= in.vblnk;
        out.hcount <= in.hcount;
        out.hsync  <= in.hsync;
        out.hblnk  <= in.hblnk;
        out.rgb    <= m_rgb_out;
    end
end

endmodule
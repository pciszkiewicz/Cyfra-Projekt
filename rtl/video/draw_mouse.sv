`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Moduł renderowania celownika myszy.
 * Pobiera zsynchronizowane współrzędne X/Y z domeny sprzętowej i rysuje
 * sprajt celownika (crosshair), centrując teksturę 16x16px idealnie w punkcie kliknięcia.
 */

module draw_mouse (
    input logic clk,
    input logic rst_n,
    vga_if.out out,
    vga_if.in in,
    input logic [11:0] xpos,
    input logic [11:0] ypos
);

/* Local variables and signals */
logic is_mouse;
logic [3:0] mx, my;
logic [7:0] mouse_addr;

(* rom_style = "block" *) logic [11:0] rom_mouse [256];

logic [11:0] pix_mouse_reg, pix_mouse_nxt;
logic is_m_d1_reg, is_m_d1_nxt;
logic hsync_d1_reg, hsync_d1_nxt;
logic vsync_d1_reg, vsync_d1_nxt;
logic hblnk_d1_reg, hblnk_d1_nxt;
logic vblnk_d1_reg, vblnk_d1_nxt;
logic [10:0] hcount_d1_reg, hcount_d1_nxt;
logic [10:0] vcount_d1_reg, vcount_d1_nxt;
logic [11:0] rgb_d1_reg, rgb_d1_nxt;

logic [11:0] rgb_nxt;

/* Signals assignments */
assign mouse_addr = {my, mx};

/* Memory initialization */
initial begin
    $readmemh("../../rtl/memory/crosshair.mem", rom_mouse);
end

/* Module internal logic */
always_comb begin
    /* Odjecie 8 by utrzymac srodek celownika (os X/Y myszy w centrum 16x16px tekstury) */
    mx = 4'(in.hcount - (xpos - 12'd8));
    my = 4'(in.vcount - (ypos - 12'd8));
    is_mouse = (in.hcount >= xpos - 12'd8) && (in.hcount < xpos + 12'd8) &&
               (in.vcount >= ypos - 12'd8) && (in.vcount < ypos + 12'd8);
end

always_comb begin
    pix_mouse_nxt = rom_mouse[mouse_addr];
    is_m_d1_nxt = is_mouse;
    rgb_d1_nxt = in.rgb;
    hcount_d1_nxt = in.hcount;
    vcount_d1_nxt = in.vcount;
    hsync_d1_nxt = in.hsync;
    vsync_d1_nxt = in.vsync;
    hblnk_d1_nxt = in.hblnk;
    vblnk_d1_nxt = in.vblnk;
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pix_mouse_reg <= 12'h0;
        is_m_d1_reg <= 1'b0;
        rgb_d1_reg <= 12'h0;
        hcount_d1_reg <= 11'h0;
        vcount_d1_reg <= 11'h0;
        hsync_d1_reg <= 1'b0;
        vsync_d1_reg <= 1'b0;
        hblnk_d1_reg <= 1'b0;
        vblnk_d1_reg <= 1'b0;
    end else begin
        pix_mouse_reg <= pix_mouse_nxt;
        is_m_d1_reg <= is_m_d1_nxt;
        rgb_d1_reg <= rgb_d1_nxt;
        hcount_d1_reg <= hcount_d1_nxt;
        vcount_d1_reg <= vcount_d1_nxt;
        hsync_d1_reg <= hsync_d1_nxt;
        vsync_d1_reg <= vsync_d1_nxt;
        hblnk_d1_reg <= hblnk_d1_nxt;
        vblnk_d1_reg <= vblnk_d1_nxt;
    end
end

always_comb begin
    rgb_nxt = rgb_d1_reg;
    
    if (!vblnk_d1_reg && !hblnk_d1_reg) begin
        /* Rysuj jesli to kursor i nie jest przezroczysty */
        if (is_m_d1_reg && pix_mouse_reg != 12'hF0F) begin
            rgb_nxt = pix_mouse_reg;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.hcount <= 11'h0;
        out.vcount <= 11'h0;
        out.hsync <= 1'b0;
        out.vsync <= 1'b0;
        out.hblnk <= 1'b0;
        out.vblnk <= 1'b0;
        out.rgb <= 12'h0;
    end else begin
        out.hcount <= hcount_d1_reg;
        out.vcount <= vcount_d1_reg;
        out.hsync <= hsync_d1_reg;
        out.vsync <= vsync_d1_reg;
        out.hblnk <= hblnk_d1_reg;
        out.vblnk <= vblnk_d1_reg;
        out.rgb <= rgb_nxt;
    end
end

endmodule
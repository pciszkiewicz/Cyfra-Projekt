`timescale 1ns / 1ps

module draw_mouse (
    input  logic        clk,
    input  logic        rst_n,
    vga_if.in           in,
    vga_if.out          out,
    input  logic [11:0] xpos,
    input  logic [11:0] ypos
);

    logic is_mouse;
    logic [3:0] mx, my; 

    always_comb begin
        // -8 by utrzymać środek celownika (oś X/Y myszy w centrum 16x16px tekstury)
        mx = in.hcount - (xpos - 8);
        my = in.vcount - (ypos - 8);
        is_mouse = (in.hcount >= xpos - 8) && (in.hcount < xpos + 8) &&
                   (in.vcount >= ypos - 8) && (in.vcount < ypos + 8);
    end

    logic [7:0] mouse_addr;
    assign mouse_addr = {my, mx};

    (* rom_style = "block" *) logic [11:0] rom_mouse [255:0];
    initial begin
        $readmemh("../../rtl/memory/crosshair.mem", rom_mouse);
    end

    logic [11:0] pix_mouse, rgb_d1;
    logic is_m_d1;
    logic hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic [10:0] hcount_d1, vcount_d1;

    always_ff @(posedge clk) begin
        pix_mouse <= rom_mouse[mouse_addr];
        is_m_d1   <= is_mouse;
        rgb_d1    <= in.rgb;
        hcount_d1 <= in.hcount; vcount_d1 <= in.vcount;
        hsync_d1  <= in.hsync;  vsync_d1  <= in.vsync;
        hblnk_d1  <= in.hblnk;  vblnk_d1  <= in.vblnk;
    end

    logic [11:0] rgb_nxt;
    always_comb begin
        rgb_nxt = rgb_d1;
        if (!vblnk_d1 && !hblnk_d1) begin
            // Rysuj jeśli to kursor i nie jest przezroczysty
            if (is_m_d1 && pix_mouse != 12'hF0F) rgb_nxt = pix_mouse;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.hcount <= 0; out.vcount <= 0;
            out.hsync <= 0; out.vsync <= 0;
            out.hblnk <= 0; out.vblnk <= 0;
            out.rgb <= 0;
        end else begin
            out.hcount <= hcount_d1; out.vcount <= vcount_d1;
            out.hsync <= hsync_d1; out.vsync <= vsync_d1;
            out.hblnk <= hblnk_d1; out.vblnk <= vblnk_d1;
            out.rgb <= rgb_nxt;
        end
    end

endmodule
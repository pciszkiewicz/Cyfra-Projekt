`timescale 1ns / 1ps

module draw_entities (
    input  logic        clk,
    input  logic        rst_n,
    vga_if.in           in,
    vga_if.out          out,
    input  logic [15:0] cam_world_x, cam_world_y,
    input  logic [15:0] enemy_world_x, enemy_world_y,
    input  logic [7:0]  enemy_hp,
    input  logic [15:0] bullet_world_x, bullet_world_y,
    input  logic        bullet_active,
    input  logic [15:0] enemy_bullet_x, enemy_bullet_y,
    input  logic        enemy_bullet_active
);

    logic signed [15:0] screen_x, screen_y;
    always_comb begin
        screen_x = signed'({1'b0, in.hcount}) + signed'({1'b0, cam_world_x}) - 16'sd512;
        screen_y = signed'({1'b0, in.vcount}) + signed'({1'b0, cam_world_y}) - 16'sd384;
    end

    logic is_p, is_e, is_b, is_eb;
    logic [9:0] addr_p, addr_e;
    logic [5:0] addr_b, addr_eb;

    // Zmienne pomocnicze do obliczania relatywnej pozycji (zapobiegają błędom składni wycinania bitów)
    logic [15:0] diff_p_x,  diff_p_y;
    logic [15:0] diff_e_x,  diff_e_y;
    logic [15:0] diff_b_x,  diff_b_y;
    logic [15:0] diff_eb_x, diff_eb_y;

    always_comb begin
        // Obliczenie różnic pozycji
        diff_p_x  = screen_x - cam_world_x;
        diff_p_y  = screen_y - cam_world_y;
        
        diff_e_x  = screen_x - enemy_world_x;
        diff_e_y  = screen_y - enemy_world_y;
        
        diff_b_x  = screen_x - bullet_world_x;
        diff_b_y  = screen_y - bullet_world_y;
        
        diff_eb_x = screen_x - enemy_bullet_x;
        diff_eb_y = screen_y - enemy_bullet_y;

        // Gracz 1
        is_p = (screen_x >= cam_world_x) && (screen_x < cam_world_x + 32) &&
               (screen_y >= cam_world_y) && (screen_y < cam_world_y + 32);
        addr_p = {diff_p_y[4:0], diff_p_x[4:0]};

        // Wróg
        is_e = (screen_x >= enemy_world_x) && (screen_x < enemy_world_x + 32) &&
               (screen_y >= enemy_world_y) && (screen_y < enemy_world_y + 32) && (enemy_hp > 0);
        addr_e = {diff_e_y[4:0], diff_e_x[4:0]};

        // Pocisk Gracza (8x8px)
        is_b = bullet_active && (screen_x >= bullet_world_x) && (screen_x < bullet_world_x + 8) &&
               (screen_y >= bullet_world_y) && (screen_y < bullet_world_y + 8);
        addr_b = {diff_b_y[2:0], diff_b_x[2:0]};

        // Pocisk Wroga (8x8px)
        is_eb = enemy_bullet_active && (screen_x >= enemy_bullet_x) && (screen_x < enemy_bullet_x + 8) &&
                (screen_y >= enemy_bullet_y) && (screen_y < enemy_bullet_y + 8);
        addr_eb = {diff_eb_y[2:0], diff_eb_x[2:0]};
    end

    (* rom_style = "block" *) logic [11:0] rom_p  [1023:0];
    (* rom_style = "block" *) logic [11:0] rom_e  [1023:0];
    (* rom_style = "block" *) logic [11:0] rom_b  [63:0];
    (* rom_style = "block" *) logic [11:0] rom_eb [63:0];

    initial begin
        $readmemh("../../rtl/memory/player_sprite.mem", rom_p);
        $readmemh("../../rtl/memory/enemy_sprite.mem", rom_e);
        $readmemh("../../rtl/memory/bullet_blue.mem", rom_b);
        $readmemh("../../rtl/memory/bullet_red.mem", rom_eb);
    end

    logic [11:0] pix_p, pix_e, pix_b, pix_eb, rgb_d1;
    logic is_p_d1, is_e_d1, is_b_d1, is_eb_d1;
    logic hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic [10:0] hcount_d1, vcount_d1;

    always_ff @(posedge clk) begin
        pix_p  <= rom_p[addr_p];
        pix_e  <= rom_e[addr_e];
        pix_b  <= rom_b[addr_b];
        pix_eb <= rom_eb[addr_eb];

        is_p_d1 <= is_p; is_e_d1 <= is_e; 
        is_b_d1 <= is_b; is_eb_d1 <= is_eb;
        
        rgb_d1 <= in.rgb;
        hcount_d1 <= in.hcount; vcount_d1 <= in.vcount;
        hsync_d1 <= in.hsync; vsync_d1 <= in.vsync;
        hblnk_d1 <= in.hblnk; vblnk_d1 <= in.vblnk;
    end

    logic [11:0] rgb_nxt;
    always_comb begin
        rgb_nxt = rgb_d1;
        if (!vblnk_d1 && !hblnk_d1) begin
            // Magiczna funkcja Chroma Key (Przezroczystość dla F0F)
            if      (is_b_d1  && pix_b  != 12'hF0F) rgb_nxt = pix_b;
            else if (is_eb_d1 && pix_eb != 12'hF0F) rgb_nxt = pix_eb;
            else if (is_p_d1  && pix_p  != 12'hF0F) rgb_nxt = pix_p;
            else if (is_e_d1  && pix_e  != 12'hF0F) rgb_nxt = pix_e;
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
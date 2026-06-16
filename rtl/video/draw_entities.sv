`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Renderer postaci (Gracz, Przeciwnik) oraz pocisków w locie.
 * Wykorzystuje pamięci ROM sprajtów graczy oraz pocisków sieciowych.
 * Implementuje kluczowanie kolorem (Chroma Keying - kolor F0F jako przezroczysty).
 */

module draw_entities (
    input logic clk,
    input logic rst_n,
    vga_if.out out,
    vga_if.in in,
    input logic [15:0] cam_world_x,
    input logic [15:0] cam_world_y,
    input logic [15:0] enemy_world_x,
    input logic [15:0] enemy_world_y,
    input logic [7:0] enemy_hp,
    input logic [15:0] bullet_world_x,
    input logic [15:0] bullet_world_y,
    input logic bullet_active,
    input logic [15:0] enemy_bullet_x,
    input logic [15:0] enemy_bullet_y,
    input logic enemy_bullet_active
);

/* Local variables and signals */
logic signed [15:0] screen_x, screen_y;

logic is_p, is_e, is_b, is_eb;
logic [9:0] addr_p, addr_e;
logic [5:0] addr_b, addr_eb;

/* Zmienne pomocnicze do obliczania relatywnej pozycji */
logic [15:0] diff_p_x, diff_p_y;
logic [15:0] diff_e_x, diff_e_y;
logic [15:0] diff_b_x, diff_b_y;
logic [15:0] diff_eb_x, diff_eb_y;

(* rom_style = "block" *) logic [11:0] rom_p [1024];
(* rom_style = "block" *) logic [11:0] rom_e [1024];
(* rom_style = "block" *) logic [11:0] rom_b [64];
(* rom_style = "block" *) logic [11:0] rom_eb [64];

logic [11:0] pix_p_reg, pix_p_nxt;
logic [11:0] pix_e_reg, pix_e_nxt;
logic [11:0] pix_b_reg, pix_b_nxt;
logic [11:0] pix_eb_reg, pix_eb_nxt;

logic is_p_d1_reg, is_p_d1_nxt;
logic is_e_d1_reg, is_e_d1_nxt;
logic is_b_d1_reg, is_b_d1_nxt;
logic is_eb_d1_reg, is_eb_d1_nxt;

logic hsync_d1_reg, hsync_d1_nxt;
logic vsync_d1_reg, vsync_d1_nxt;
logic hblnk_d1_reg, hblnk_d1_nxt;
logic vblnk_d1_reg, vblnk_d1_nxt;
logic [10:0] hcount_d1_reg, hcount_d1_nxt;
logic [10:0] vcount_d1_reg, vcount_d1_nxt;
logic [11:0] rgb_d1_reg, rgb_d1_nxt;

logic [11:0] rgb_nxt;

/* Memory initialization */
initial begin
    $readmemh("../../rtl/memory/player_sprite.mem", rom_p);
    $readmemh("../../rtl/memory/enemy_sprite.mem", rom_e);
    $readmemh("../../rtl/memory/bullet_blue.mem", rom_b);
    $readmemh("../../rtl/memory/bullet_red.mem", rom_eb);
end

/* Module internal logic */
always_comb begin
    screen_x = signed'({1'b0, in.hcount}) + signed'({1'b0, cam_world_x}) - 16'sd512;
    screen_y = signed'({1'b0, in.vcount}) + signed'({1'b0, cam_world_y}) - 16'sd384;

    /* Obliczenie roznic pozycji */
    diff_p_x = screen_x - cam_world_x;
    diff_p_y = screen_y - cam_world_y;
    
    diff_e_x = screen_x - enemy_world_x;
    diff_e_y = screen_y - enemy_world_y;
    
    diff_b_x = screen_x - bullet_world_x;
    diff_b_y = screen_y - bullet_world_y;
    
    diff_eb_x = screen_x - enemy_bullet_x;
    diff_eb_y = screen_y - enemy_bullet_y;

    /* Gracz 1 */
    is_p = (screen_x >= cam_world_x) && (screen_x < cam_world_x + 16'd32) &&
           (screen_y >= cam_world_y) && (screen_y < cam_world_y + 16'd32);
    addr_p = {diff_p_y[4:0], diff_p_x[4:0]};

    /* Wrog */
    is_e = (screen_x >= enemy_world_x) && (screen_x < enemy_world_x + 16'd32) &&
           (screen_y >= enemy_world_y) && (screen_y < enemy_world_y + 16'd32) &&
           (enemy_hp > 8'd0);
    addr_e = {diff_e_y[4:0], diff_e_x[4:0]};

    /* Pocisk Gracza (8x8px) */
    is_b = bullet_active && (screen_x >= bullet_world_x) && (screen_x < bullet_world_x + 16'd8) &&
           (screen_y >= bullet_world_y) && (screen_y < bullet_world_y + 16'd8);
    addr_b = {diff_b_y[2:0], diff_b_x[2:0]};

    /* Pocisk Wroga (8x8px) */
    is_eb = enemy_bullet_active && (screen_x >= enemy_bullet_x) && (screen_x < enemy_bullet_x + 16'd8) &&
            (screen_y >= enemy_bullet_y) && (screen_y < enemy_bullet_y + 16'd8);
    addr_eb = {diff_eb_y[2:0], diff_eb_x[2:0]};
end

always_comb begin
    pix_p_nxt = rom_p[addr_p];
    pix_e_nxt = rom_e[addr_e];
    pix_b_nxt = rom_b[addr_b];
    pix_eb_nxt = rom_eb[addr_eb];

    is_p_d1_nxt = is_p;
    is_e_d1_nxt = is_e;
    is_b_d1_nxt = is_b;
    is_eb_d1_nxt = is_eb;
    
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
        pix_p_reg <= 12'h0;
        pix_e_reg <= 12'h0;
        pix_b_reg <= 12'h0;
        pix_eb_reg <= 12'h0;

        is_p_d1_reg <= 1'b0;
        is_e_d1_reg <= 1'b0;
        is_b_d1_reg <= 1'b0;
        is_eb_d1_reg <= 1'b0;
        
        rgb_d1_reg <= 12'h0;
        hcount_d1_reg <= 11'h0;
        vcount_d1_reg <= 11'h0;
        hsync_d1_reg <= 1'b0;
        vsync_d1_reg <= 1'b0;
        hblnk_d1_reg <= 1'b0;
        vblnk_d1_reg <= 1'b0;
    end else begin
        pix_p_reg <= pix_p_nxt;
        pix_e_reg <= pix_e_nxt;
        pix_b_reg <= pix_b_nxt;
        pix_eb_reg <= pix_eb_nxt;

        is_p_d1_reg <= is_p_d1_nxt;
        is_e_d1_reg <= is_e_d1_nxt;
        is_b_d1_reg <= is_b_d1_nxt;
        is_eb_d1_reg <= is_eb_d1_nxt;
        
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
        /* Magiczna funkcja Chroma Key (Przezroczystosc dla F0F) */
        if (is_b_d1_reg && pix_b_reg != 12'hF0F) begin
            rgb_nxt = pix_b_reg;
        end else if (is_eb_d1_reg && pix_eb_reg != 12'hF0F) begin
            rgb_nxt = pix_eb_reg;
        end else if (is_p_d1_reg && pix_p_reg != 12'hF0F) begin
            rgb_nxt = pix_p_reg;
        end else if (is_e_d1_reg && pix_e_reg != 12'hF0F) begin
            rgb_nxt = pix_e_reg;
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
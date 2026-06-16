`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Moduł wyświetlacza HUD (Heads-Up Display).
 * Nakłada na samą górę gotowego obrazu paski życia obu graczy (lokalnego i zdalnego)
 * umieszczone w estetycznych ramkach w rogach ekranu.
 */

module draw_hud (
    input logic clk,
    input logic rst_n,
    vga_if.out out,
    vga_if.in in,
    input logic [7:0] my_hp,
    input logic [7:0] enemy_hp
);

/* Parametry rysowania (Stale pozycje na ekranie 1024x768) */
localparam int BAR_Y_START = 32;
localparam int BAR_Y_END = 48;
localparam int P1_X_START = 64;
localparam int P2_X_END = 960;
localparam int MAX_BAR_W = 400;
localparam int BORDER_W = 2;

logic [10:0] my_bar_w;
logic [10:0] enemy_bar_w;
logic [11:0] rgb_nxt;

/* Przeliczanie szerokosci (kombinacyjnie) */
always_comb begin
    my_bar_w = {3'b000, my_hp} << 1;
    enemy_bar_w = {3'b000, enemy_hp} << 1;
end

/* 1. BLOK SEKWENCYJNY (Synchronizacja sygnalow VGA z resetem asynchronicznym)*/

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= 11'h0;
        out.hcount <= 11'h0;
        out.vsync <= 1'b0;
        out.hsync <= 1'b0;
        out.vblnk <= 1'b0;
        out.hblnk <= 1'b0;
        out.rgb <= 12'h000;
    end else begin
        out.vcount <= in.vcount;
        out.hcount <= in.hcount;
        out.vsync <= in.vsync;
        out.hsync <= in.hsync;
        out.vblnk <= in.vblnk;
        out.hblnk <= in.hblnk;
        out.rgb <= rgb_nxt;
    end
end

/* 2. BLOK KOMBINACYJNY (Logika nakladania pikseli interfejsu)*/

always_comb begin
    rgb_nxt = in.rgb;

    if (!in.vblnk && !in.hblnk) begin
        if (in.vcount >= 11'(BAR_Y_START - BORDER_W) && in.vcount <= 11'(BAR_Y_END + BORDER_W) &&
            in.hcount >= 11'(P1_X_START - BORDER_W) && in.hcount <= 11'(P1_X_START + MAX_BAR_W + BORDER_W)) begin
            
            if (in.vcount >= 11'(BAR_Y_START) && in.vcount <= 11'(BAR_Y_END) && 
                in.hcount >= 11'(P1_X_START) && in.hcount < 11'(P1_X_START + MAX_BAR_W)) begin
                if (in.hcount < 11'(P1_X_START) + my_bar_w) begin
                    rgb_nxt = 12'h0F0;
                end else begin
                    rgb_nxt = 12'h444;
                end
            end else begin
                rgb_nxt = 12'hFFF;
            end

        end else if (in.vcount >= 11'(BAR_Y_START - BORDER_W) && in.vcount <= 11'(BAR_Y_END + BORDER_W) &&
                   in.hcount >= 11'(P2_X_END - MAX_BAR_W - BORDER_W) && in.hcount <= 11'(P2_X_END + BORDER_W)) begin
            
            if (in.vcount >= 11'(BAR_Y_START) && in.vcount <= 11'(BAR_Y_END) && 
                in.hcount > 11'(P2_X_END - MAX_BAR_W) && in.hcount <= 11'(P2_X_END)) begin
                if (in.hcount > 11'(P2_X_END) - enemy_bar_w) begin
                    rgb_nxt = 12'hF00;
                end else begin
                    rgb_nxt = 12'h444;
                end
            end else begin
                rgb_nxt = 12'hFFF;
            end
        end
    end
end

endmodule
/**
 * Copyright (C) 2026 AGH University of Science and Technology
 * MTM UEC2
 * Author: Tomasz Jesionek / Poprawki pod mapę 64x64
 *
 * Description:
 * Map drawing module tailored for 64x64 grid with 32x32px tiles.
 */

 module draw_map (
    input  logic        clk,
    input  logic        rst_n,
    output logic [11:0] map_addr,     // Zmiana z [9:0] na [11:0] - dopasowanie do map_rom
    vga_if.out          out,
    vga_if.in           in,
    input  logic [11:0] player_x,
    input  logic [11:0] player_y,
    input  logic        is_wall
);

logic signed [12:0] map_pixel_x;
logic signed [12:0] map_pixel_y;

// Logika kombinacyjna - przeliczanie pozycji i generowanie adresu kafelka
always_comb begin
    map_pixel_x = $signed({2'b0, in.hcount}) + $signed({1'b0, player_x}) - 13'sd512;
    map_pixel_y = $signed({2'b0, in.vcount}) + $signed({1'b0, player_y}) - 13'sd384;

    // Mapa ma teraz wymiary globalne 2048x2048 pikseli (64 kafelki * 32 piksele)
    if (map_pixel_x >= 13'sd0 && map_pixel_x < 13'sd2048 && map_pixel_y >= 13'sd0 && map_pixel_y < 13'sd2048) begin
        // ZMIANA: Pobieramy bity [10:5] (6 bitów na oś Y i 6 bitów na oś X).
        // Daje to przesunięcie o 5 bitów w lewo (dzielenie przez 32 piksele kafelka).
        // Po złączeniu (konkatenacji) otrzymujemy idealny 12-bitowy adres (0-4095).
        map_addr = {map_pixel_y[10:5], map_pixel_x[10:5]};
    end else begin
        map_addr = 12'd0;
    end
end

// Logika sekwencyjna - synchronizacja sygnałów sterujących VGA (Reset Asynchroniczny)
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= '0;
        out.hcount <= '0;
        out.vsync  <= '0;
        out.hsync  <= '0;
        out.vblnk  <= '0;
        out.hblnk  <= '0;
    end else begin
        out.vcount <= in.vcount;
        out.hcount <= in.hcount;
        out.vsync  <= in.vsync;
        out.hsync  <= in.hsync;
        out.vblnk  <= in.vblnk;
        out.hblnk  <= in.hblnk;
    end
end

// Logika kombinacyjna - nakładanie kolorów pikseli (RGB)
always_comb begin
    out.rgb = in.rgb;
    if (!out.vblnk && !out.hblnk) begin
        if (map_pixel_x >= 13'sd0 && map_pixel_x < 13'sd2048 && map_pixel_y >= 13'sd0 && map_pixel_y < 13'sd2048) begin
            if (is_wall) begin
                out.rgb = 12'h444; // Kolor ścian
            end else begin
                out.rgb = 12'hCCC; // Kolor podłogi
                
                // ZMIANA: Sprawdzamy bity [4:0], aby rysować siatkę pomocniczą 
                // dokładnie co 32 piksele (granice nowych kafelków).
                if (map_pixel_x[4:0] == 5'd0 || map_pixel_y[4:0] == 5'd0) begin
                    out.rgb = 12'h888;
                end
            end
        end
        
        // Celownik/środek ekranu (pozycja naszej postaci)
        if (out.hcount >= 11'd496 && out.hcount < 11'd528 && out.vcount >= 11'd368 && out.vcount < 11'd400) begin
            out.rgb = 12'h05F;
        end
    end
end

endmodule
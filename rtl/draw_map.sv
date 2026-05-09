`timescale 1 ns / 1 ps

module draw_map (
    input  logic        clk,
    input  logic        rst,

    // Interfejsy zgodne z Twoim stylem z labów
    vga_if.in           in,
    vga_if.out          out,

    input  logic [11:0] player_x,    
    input  logic [11:0] player_y,    
    output logic [9:0]  map_addr,    
    input  logic        is_wall
);

    logic signed [12:0] map_pixel_x, map_pixel_y;

    // Obliczanie pozycji na mapie (kamera)
    always_comb begin
        map_pixel_x = $signed({2'b0, in.hcount}) + $signed({1'b0, player_x}) - 13'd512;
        map_pixel_y = $signed({2'b0, in.vcount}) + $signed({1'b0, player_y}) - 13'd384;

        if (map_pixel_x >= 0 && map_pixel_x < 2048 && map_pixel_y >= 0 && map_pixel_y < 2048)
            map_addr = {map_pixel_y[10:6], map_pixel_x[10:6]}; 
        else
            map_addr = 10'd0;
    end

    // Przekazanie sygnałów sterujących (Pipeline) - tak jak w Twoim delay.sv z labów
    always_ff @(posedge clk) begin
        if (rst) begin
            out.vcount <= '0; out.hcount <= '0;
            out.vsync  <= '0; out.hsync  <= '0;
            out.vblnk  <= '0; out.hblnk  <= '0;
        end else begin
            out.vcount <= in.vcount; out.hcount <= in.hcount;
            out.vsync  <= in.vsync;  out.hsync  <= in.hsync;
            out.vblnk  <= in.vblnk;  out.hblnk  <= in.hblnk;
        end
    end

    // Logika rysowania (wykorzystujemy dane z wejścia i nakładamy mapę)
    always_comb begin
        out.rgb = in.rgb; // Podkład z poprzedniego modułu (zazwyczaj tło)

        if (!out.vblnk && !out.hblnk) begin
            // Jeśli jesteśmy w granicach mapy
            if (map_pixel_x >= 0 && map_pixel_x < 2048 && map_pixel_y >= 0 && map_pixel_y < 2048) begin
                if (is_wall) out.rgb = 12'h444; // Ściana
                else begin
                    out.rgb = 12'hCCC; // Podłoga
                    // Siatka kafelków
                    if (map_pixel_x[5:0] == 0 || map_pixel_y[5:0] == 0) out.rgb = 12'h888;
                end
            end
            
            // Rysowanie gracza (na środku ekranu)
            if (out.hcount >= 496 && out.hcount < 528 && out.vcount >= 368 && out.vcount < 400)
                out.rgb = 12'h05F;
        end
    end

endmodule
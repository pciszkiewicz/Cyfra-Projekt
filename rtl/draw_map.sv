`timescale 1ns / 1ps

module draw_map (
    input  logic        clk,
    input  logic        rst_n,
    output logic [11:0] map_addr,
    vga_if.out          out,
    vga_if.in           in,
    input  logic [15:0] player_x, 
    input  logic [15:0] player_y,
    input  logic        is_wall
);

    logic signed [15:0] map_pixel_x, map_pixel_y;
    logic               is_inside_map_stage1;
    logic [9:0]         sprite_addr;

    always_comb begin
        // Obliczanie współrzędnych ze środka ekranu
        map_pixel_x = signed'({1'b0, in.hcount}) + signed'({1'b0, player_x}) - 16'sd512;
        map_pixel_y = signed'({1'b0, in.vcount}) + signed'({1'b0, player_y}) - 16'sd384;

        is_inside_map_stage1 = (map_pixel_x >= 16'sd0) && (map_pixel_x < 16'sd2048) && 
                               (map_pixel_y >= 16'sd0) && (map_pixel_y < 16'sd2048);
                               
        if (is_inside_map_stage1) map_addr = {map_pixel_y[10:5], map_pixel_x[10:5]};
        else                      map_addr = 12'd0;
        
        // Adres dla tekstur 32x32px to 5 najmłodszych bitów pozycji
        sprite_addr = {map_pixel_y[4:0], map_pixel_x[4:0]};
    end

    (* rom_style = "block" *) logic [11:0] rom_wall  [1023:0];
    (* rom_style = "block" *) logic [11:0] rom_floor [1023:0];

    initial begin
        $readmemh("../../rtl/memory/wall_sprite.mem", rom_wall);
        $readmemh("../../rtl/memory/floor_sprite.mem", rom_floor);
    end

    // Rejestry opóźniające (Etap 1 -> 2) dopasowane do pamięci ROM
    logic [11:0] pix_wall, pix_floor, rgb_d1;
    logic        is_inside_d1;
    logic        hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic [10:0] hcount_d1, vcount_d1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_inside_d1 <= 1'b0;
            rgb_d1       <= 12'h0;
            // Dodane brakujące wartości dla resetu:
            pix_wall     <= 12'h0;
            pix_floor    <= 12'h0;
            hcount_d1    <= 11'h0; 
            vcount_d1    <= 11'h0;
            hsync_d1     <= 1'b0;  
            vsync_d1     <= 1'b0;
            hblnk_d1     <= 1'b0;  
            vblnk_d1     <= 1'b0;
        end else begin
            pix_wall     <= rom_wall[sprite_addr];
            pix_floor    <= rom_floor[sprite_addr];
            is_inside_d1 <= is_inside_map_stage1;
            rgb_d1       <= in.rgb;
            hcount_d1    <= in.hcount; 
            vcount_d1    <= in.vcount;
            hsync_d1     <= in.hsync;  
            vsync_d1     <= in.vsync;
            hblnk_d1     <= in.hblnk;  
            vblnk_d1     <= in.vblnk;
        end
    end

    // Logika wyboru koloru (Etap 2)
    logic [11:0] rgb_nxt;
    always_comb begin
        rgb_nxt = rgb_d1;
        if (!vblnk_d1 && !hblnk_d1 && is_inside_d1) begin
            if (is_wall) rgb_nxt = pix_wall;
            else         rgb_nxt = pix_floor;
            
            // Zabezpieczenie przezroczystości (nie dotyczy tła, ale dobra praktyka)
            if (rgb_nxt == 12'hF0F) rgb_nxt = 12'h000; 
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.vcount <= '0; out.hcount <= '0;
            out.vsync  <= '0; out.hsync  <= '0;
            out.vblnk  <= '0; out.hblnk  <= '0;
            out.rgb    <= '0;
        end else begin
            out.vcount <= vcount_d1; out.hcount <= hcount_d1;
            out.vsync  <= vsync_d1;  out.hsync  <= hsync_d1;
            out.vblnk  <= vblnk_d1;  out.hblnk  <= hblnk_d1;
            out.rgb    <= rgb_nxt;
        end
    end

endmodule
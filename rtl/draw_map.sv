module draw_map (
    input  logic        clk,
    input  logic        rst_n,
    output logic [13:0] map_addr,      // POPRAWKA: 14 bitów, żeby objąć 16384 kafelków
    vga_if.out          out,
    vga_if.in           in,
    input  logic [15:0] player_x,      // POPRAWKA: Zwiększono do 16 bitów 
    input  logic [15:0] player_y,      // żeby uniknąć ucinania współrzędnych gracza
    input  logic        is_wall
);

// POPRAWKA: Rozszerzono do 16 bitów by zapobiec przepełnieniu arytmetycznemu na końcu dużej mapy
logic signed [15:0] map_pixel_x, map_pixel_y;
logic               is_inside_map_stage1;

always_comb begin
    // POPRAWKA: Bezpieczne rzutowanie z powiększonym rozmiarem bitowym
    map_pixel_x = signed'({1'b0, in.hcount}) + signed'({1'b0, player_x}) - 16'sd512;
    map_pixel_y = signed'({1'b0, in.vcount}) + signed'({1'b0, player_y}) - 16'sd384;

    // POPRAWKA: Granice mapy zwiększone z 2048 na 4096
    is_inside_map_stage1 = (map_pixel_x >= 16'sd0) && (map_pixel_x < 16'sd4096) && 
                           (map_pixel_y >= 16'sd0) && (map_pixel_y < 16'sd4096);

    // POPRAWKA: Pobieranie 7 bitów X i 7 bitów Y (7+7=14 bitów adresu) zamiast 6+6.
    if (is_inside_map_stage1) map_addr = {map_pixel_y[11:5], map_pixel_x[11:5]};
    else                      map_addr = 14'd0;
end

// Zwiększenie rejestrów opóźniających dla pipeliningu
logic signed [15:0] map_pixel_x_d1, map_pixel_y_d1;
logic [10:0]        hcount_d1, vcount_d1;
logic               hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
logic [11:0]        rgb_d1;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        map_pixel_x_d1 <= '0; map_pixel_y_d1 <= '0;
        hcount_d1      <= '0; vcount_d1      <= '0;
        hsync_d1       <= '0; vsync_d1       <= '0;
        hblnk_d1       <= '0; vblnk_d1       <= '0;
        rgb_d1         <= '0;
    end else begin
        map_pixel_x_d1 <= map_pixel_x; map_pixel_y_d1 <= map_pixel_y;
        hcount_d1      <= in.hcount;   vcount_d1      <= in.vcount;
        hsync_d1       <= in.hsync;    vsync_d1       <= in.vsync;
        hblnk_d1       <= in.hblnk;    vblnk_d1       <= in.vblnk;
        rgb_d1         <= in.rgb;
    end
end

logic [11:0] rgb_nxt;
logic is_active_display, is_inside_map_stage3, is_grid_line, is_crosshair;

always_comb begin
    is_active_display    = (!vblnk_d1 && !hblnk_d1);
    
    // POPRAWKA: Granice mapy dla etapu 3 powiększone do 4096
    is_inside_map_stage3 = (map_pixel_x_d1 >= 16'sd0) && (map_pixel_x_d1 < 16'sd4096) && 
                           (map_pixel_y_d1 >= 16'sd0) && (map_pixel_y_d1 < 16'sd4096);
                           
    is_grid_line         = (map_pixel_x_d1[4:0] == 5'd0) || (map_pixel_y_d1[4:0] == 5'd0);
    is_crosshair         = (hcount_d1 >= 11'd496) && (hcount_d1 < 11'd528) && 
                           (vcount_d1 >= 11'd368) && (vcount_d1 < 11'd400);

    rgb_nxt = rgb_d1;
    
    if (is_active_display && is_crosshair)                        rgb_nxt = 12'h05F;
    else if (is_active_display && is_inside_map_stage3 && is_wall)      rgb_nxt = 12'h444; 
    else if (is_active_display && is_inside_map_stage3 && is_grid_line) rgb_nxt = 12'h888;
    else if (is_active_display && is_inside_map_stage3)                 rgb_nxt = 12'hCCC; 
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
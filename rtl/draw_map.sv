module draw_map (
    input  logic        clk,
    input  logic        rst_n,
    output logic [11:0] map_addr,
    vga_if.out          out,
    vga_if.in           in,
    input  logic [11:0] player_x,
    input  logic [11:0] player_y,
    input  logic        is_wall
);

logic signed [12:0] map_pixel_x, map_pixel_y;
logic               is_inside_map_stage1;

always_comb begin
    map_pixel_x = $signed({2'b0, in.hcount}) + $signed({1'b0, player_x}) - 13'sd512;
    map_pixel_y = $signed({2'b0, in.vcount}) + $signed({1'b0, player_y}) - 13'sd384;

    is_inside_map_stage1 = (map_pixel_x >= 13'sd0) && (map_pixel_x < 13'sd2048) && 
                           (map_pixel_y >= 13'sd0) && (map_pixel_y < 13'sd2048);

    if (is_inside_map_stage1) map_addr = {map_pixel_y[10:5], map_pixel_x[10:5]};
    else                      map_addr = 12'd0;
end

logic signed [12:0] map_pixel_x_d1, map_pixel_y_d1;
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
    is_inside_map_stage3 = (map_pixel_x_d1 >= 13'sd0) && (map_pixel_x_d1 < 13'sd2048) && 
                           (map_pixel_y_d1 >= 13'sd0) && (map_pixel_y_d1 < 13'sd2048);
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
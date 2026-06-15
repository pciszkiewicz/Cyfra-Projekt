`timescale 1 ns / 1 ps

module draw_map (
    input logic clk,
    input logic rst_n,
    output logic [11:0] map_addr,
    vga_if.out out,
    vga_if.in in,
    input logic [15:0] player_x,
    input logic [15:0] player_y,
    input logic is_wall
);

/* Local variables and signals */
logic signed [15:0] map_pixel_x, map_pixel_y;
logic is_inside_map_stage1;
logic [9:0] sprite_addr;

(* rom_style = "block" *) logic [11:0] rom_wall [1024];
(* rom_style = "block" *) logic [11:0] rom_floor [1024];

logic [11:0] pix_wall_reg, pix_wall_nxt;
logic [11:0] pix_floor_reg, pix_floor_nxt;
logic [11:0] rgb_d1_reg, rgb_d1_nxt;

logic is_inside_d1_reg, is_inside_d1_nxt;
logic hsync_d1_reg, hsync_d1_nxt;
logic vsync_d1_reg, vsync_d1_nxt;
logic hblnk_d1_reg, hblnk_d1_nxt;
logic vblnk_d1_reg, vblnk_d1_nxt;
logic [10:0] hcount_d1_reg, hcount_d1_nxt;
logic [10:0] vcount_d1_reg, vcount_d1_nxt;

logic [11:0] rgb_nxt;

/* Memory initialization */
initial begin
    $readmemh("../../rtl/memory/wall_sprite.mem", rom_wall);
    $readmemh("../../rtl/memory/floor_sprite.mem", rom_floor);
end

/* Module internal logic */
always_comb begin
    /* Obliczanie wspolrzednych ze srodka ekranu */
    map_pixel_x = signed'({1'b0, in.hcount}) + signed'({1'b0, player_x}) - 16'sd512;
    map_pixel_y = signed'({1'b0, in.vcount}) + signed'({1'b0, player_y}) - 16'sd384;

    is_inside_map_stage1 = (map_pixel_x >= 16'sd0) && (map_pixel_x < 16'sd2048) && 
                           (map_pixel_y >= 16'sd0) && (map_pixel_y < 16'sd2048);
                           
    if (is_inside_map_stage1) begin
        map_addr = {map_pixel_y[10:5], map_pixel_x[10:5]};
    end else begin
        map_addr = 12'd0;
    end
    
    /* Adres dla tekstur 32x32px to 5 najmlodszych bitow pozycji */
    sprite_addr = {map_pixel_y[4:0], map_pixel_x[4:0]};
end

always_comb begin
    pix_wall_nxt = rom_wall[sprite_addr];
    pix_floor_nxt = rom_floor[sprite_addr];
    
    is_inside_d1_nxt = is_inside_map_stage1;
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
        pix_wall_reg <= 12'h0;
        pix_floor_reg <= 12'h0;
        is_inside_d1_reg <= 1'b0;
        rgb_d1_reg <= 12'h0;
        hcount_d1_reg <= 11'h0;
        vcount_d1_reg <= 11'h0;
        hsync_d1_reg <= 1'b0;
        vsync_d1_reg <= 1'b0;
        hblnk_d1_reg <= 1'b0;
        vblnk_d1_reg <= 1'b0;
    end else begin
        pix_wall_reg <= pix_wall_nxt;
        pix_floor_reg <= pix_floor_nxt;
        is_inside_d1_reg <= is_inside_d1_nxt;
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

    if (!vblnk_d1_reg && !hblnk_d1_reg && is_inside_d1_reg) begin
        if (is_wall) begin
            rgb_nxt = pix_wall_reg;
        end else begin
            rgb_nxt = pix_floor_reg;
        end
        
        /* Zabezpieczenie przezroczystosci (nie dotyczy tla, ale dobra praktyka) */
        if (rgb_nxt == 12'hF0F) begin
            rgb_nxt = 12'h000;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= 11'h0;
        out.hcount <= 11'h0;
        out.vsync <= 1'b0;
        out.hsync <= 1'b0;
        out.vblnk <= 1'b0;
        out.hblnk <= 1'b0;
        out.rgb <= 12'h0;
    end else begin
        out.vcount <= vcount_d1_reg;
        out.hcount <= hcount_d1_reg;
        out.vsync <= vsync_d1_reg;
        out.hsync <= hsync_d1_reg;
        out.vblnk <= vblnk_d1_reg;
        out.hblnk <= hblnk_d1_reg;
        out.rgb <= rgb_nxt;
    end
end

endmodule
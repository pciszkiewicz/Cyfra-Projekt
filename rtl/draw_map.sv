/**
 * Copyright (C) 2026 AGH University of Science and Technology
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Map drawing module.
 */

 module draw_map (
    input  logic        clk,
    input  logic        rst_n,
    output logic [9:0]  map_addr,
    vga_if.out          out,
    vga_if.in           in,
    input  logic [11:0] player_x,
    input  logic [11:0] player_y,
    input  logic        is_wall
);

logic signed [12:0] map_pixel_x;
logic signed [12:0] map_pixel_y;

always_comb begin
    map_pixel_x = $signed({2'b0, in.hcount}) + $signed({1'b0, player_x}) - 13'sd512;
    map_pixel_y = $signed({2'b0, in.vcount}) + $signed({1'b0, player_y}) - 13'sd384;

    if (map_pixel_x >= 13'sd0 && map_pixel_x < 13'sd2048 && map_pixel_y >= 13'sd0 && map_pixel_y < 13'sd2048) begin
        map_addr = {map_pixel_y[10:6], map_pixel_x[10:6]}; 
    end else begin
        map_addr = 10'd0;
    end
end

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

always_comb begin
    out.rgb = in.rgb;

    if (!out.vblnk && !out.hblnk) begin
        if (map_pixel_x >= 13'sd0 && map_pixel_x < 13'sd2048 && map_pixel_y >= 13'sd0 && map_pixel_y < 13'sd2048) begin
            if (is_wall) begin
                out.rgb = 12'h444;
            end else begin
                out.rgb = 12'hCCC;
                if (map_pixel_x[5:0] == 6'd0 || map_pixel_y[5:0] == 6'd0) begin
                    out.rgb = 12'h888;
                end
            end
        end
        
        if (out.hcount >= 11'd496 && out.hcount < 11'd528 && out.vcount >= 11'd368 && out.vcount < 11'd400) begin
            out.rgb = 12'h05F;
        end
    end
end

endmodule
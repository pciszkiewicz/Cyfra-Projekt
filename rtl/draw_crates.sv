/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * Crate and loot rendering module inserted into the VGA pipeline.
 */

module draw_crates (
    input  logic        clk,
    input  logic        rst_n,
    vga_if.out          out,
    vga_if.in           in,
    input  logic [11:0] player_x,
    input  logic [11:0] player_y,
    input  logic [31:0] active_crates,
    input  logic [31:0] active_loot
);

logic [15:0] crate_x [32];
logic [15:0] crate_y [32];

genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : gen_crate_luts
        crate_lut u_crate_lut (
            .crate_id(i[4:0]),
            .crate_x(crate_x[i]),
            .crate_y(crate_y[i])
        );
    end
endgenerate

logic signed [12:0] map_pixel_x, map_pixel_y;

always_comb begin
    map_pixel_x = $signed({2'b0, in.hcount}) + $signed({1'b0, player_x}) - 13'sd512;
    map_pixel_y = $signed({2'b0, in.vcount}) + $signed({1'b0, player_y}) - 13'sd384;
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

logic is_crate, is_loot;
logic [11:0] rgb_nxt;
logic signed [12:0] dx, dy;

always_comb begin
    is_crate = 1'b0;
    is_loot  = 1'b0;
    
    for (int j = 0; j < 32; j = j + 1) begin
        dx = map_pixel_x_d1 - $signed({1'b0, crate_x[j]});
        dy = map_pixel_y_d1 - $signed({1'b0, crate_y[j]});
        
        if (dx[12:5] == 8'b0 && dy[12:5] == 8'b0) begin
            if (active_crates[j]) begin
                is_crate = 1'b1;
            end else if (active_loot[j]) begin
                if (dx >= 13'sd8 && dx < 13'sd24 && dy >= 13'sd8 && dy < 13'sd24) begin
                    is_loot = 1'b1;
                end
            end
        end
    end

    rgb_nxt = rgb_d1;
    if (!vblnk_d1 && !hblnk_d1) begin
        if (is_crate)      rgb_nxt = 12'h840; 
        else if (is_loot)  rgb_nxt = 12'hFD0; 
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
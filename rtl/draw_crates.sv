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

logic signed [12:0] map_pixel_x;
logic signed [12:0] map_pixel_y;
logic [11:0]        crate_x [32];
logic [11:0]        crate_y [32];
logic               is_crate;
logic               is_loot;
logic [11:0]        rgb_nxt;

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

always_comb begin
    map_pixel_x = $signed({2'b0, in.hcount}) + $signed({1'b0, player_x}) - 13'sd512;
    map_pixel_y = $signed({2'b0, in.vcount}) + $signed({1'b0, player_y}) - 13'sd384;

    is_crate = 1'b0;
    is_loot  = 1'b0;
    
    for (int j = 0; j < 32; j = j + 1) begin
        if (map_pixel_x >= $signed({1'b0, crate_x[j]}) &&
            map_pixel_x < $signed({1'b0, crate_x[j]} + 13'sd32) &&
            map_pixel_y >= $signed({1'b0, crate_y[j]}) &&
            map_pixel_y < $signed({1'b0, crate_y[j]} + 13'sd32)) begin
            
            if (active_crates[j]) begin
                is_crate = 1'b1;
            end else if (active_loot[j]) begin
                if (map_pixel_x >= $signed({1'b0, crate_x[j]} + 13'sd8) &&
                    map_pixel_x < $signed({1'b0, crate_x[j]} + 13'sd24) &&
                    map_pixel_y >= $signed({1'b0, crate_y[j]} + 13'sd8) &&
                    map_pixel_y < $signed({1'b0, crate_y[j]} + 13'sd24)) begin
                    is_loot = 1'b1;
                end
            end
        end
    end
end

always_comb begin
    rgb_nxt = in.rgb;
    if (!in.vblnk && !in.hblnk) begin
        if (is_crate) begin
            rgb_nxt = 12'h840; 
        end else if (is_loot) begin
            rgb_nxt = 12'hFD0; 
        end
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
        out.rgb    <= '0;
    end else begin
        out.vcount <= in.vcount;
        out.hcount <= in.hcount;
        out.vsync  <= in.vsync;
        out.hsync  <= in.hsync;
        out.vblnk  <= in.vblnk;
        out.hblnk  <= in.hblnk;
        out.rgb    <= rgb_nxt;
    end
end

endmodule
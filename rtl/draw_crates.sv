`timescale 1 ns / 1 ps

module draw_crates (
    input logic clk,
    input logic rst_n,
    vga_if.out out,
    vga_if.in in,
    input logic [11:0] player_x,
    input logic [11:0] player_y,
    input logic [31:0] active_crates,
    input logic [31:0] active_loot
);

/* Local variables and signals */
logic signed [15:0] screen_x, screen_y;
logic [15:0] crate_x [31:0];
logic [15:0] crate_y [31:0];

logic [4:0] crate_id_out;
logic crate_valid_out;
logic [15:0] diff_x, diff_y;
logic [9:0] sprite_addr;

(* rom_style = "block" *) logic [11:0] rom_crate [1024];
(* rom_style = "block" *) logic [11:0] rom_heal [1024];
(* rom_style = "block" *) logic [11:0] rom_dmg [1024];
(* rom_style = "block" *) logic [11:0] rom_speed [1024];

logic [11:0] pix_crate_reg, pix_crate_nxt;
logic [11:0] pix_heal_reg, pix_heal_nxt;
logic [11:0] pix_dmg_reg, pix_dmg_nxt;
logic [11:0] pix_speed_reg, pix_speed_nxt;

logic valid_d1_reg, valid_d1_nxt;
logic [4:0] id_d1_reg, id_d1_nxt;
logic hsync_d1_reg, hsync_d1_nxt;
logic vsync_d1_reg, vsync_d1_nxt;
logic hblnk_d1_reg, hblnk_d1_nxt;
logic vblnk_d1_reg, vblnk_d1_nxt;
logic [10:0] hcount_d1_reg, hcount_d1_nxt;
logic [10:0] vcount_d1_reg, vcount_d1_nxt;
logic [11:0] rgb_d1_reg, rgb_d1_nxt;

logic [11:0] rgb_nxt;

/* Memory initialization */
initial begin
    $readmemh("../../rtl/memory/crate_sprite.mem", rom_crate);
    $readmemh("../../rtl/memory/loot_heal.mem", rom_heal);
    $readmemh("../../rtl/memory/loot_dmg.mem", rom_dmg);
    $readmemh("../../rtl/memory/loot_speed.mem", rom_speed);
end

/* Submodules placement */
genvar i;
generate
for (i = 0; i < 32; ++i) begin
    crate_lut u_lut (
        .crate_x(crate_x[i]),
        .crate_y(crate_y[i]),
        .crate_id(5'(i))
    );
end
endgenerate

/* Module internal logic */
always_comb begin
    screen_x = signed'({1'b0, in.hcount}) + signed'({1'b0, player_x}) - 16'sd512;
    screen_y = signed'({1'b0, in.vcount}) + signed'({1'b0, player_y}) - 16'sd384;
end

always_comb begin
    crate_valid_out = 1'b0;
    crate_id_out = 5'd0;
    diff_x = 16'd0;
    diff_y = 16'd0;

    for (int j = 0; j < 32; ++j) begin
        if (screen_x >= signed'({1'b0, crate_x[j]}) &&
            screen_x < signed'({1'b0, crate_x[j]}) + 16'sd32 &&
            screen_y >= signed'({1'b0, crate_y[j]}) &&
            screen_y < signed'({1'b0, crate_y[j]}) + 16'sd32) begin
            
            crate_valid_out = 1'b1;
            crate_id_out = 5'(j);
            diff_x = screen_x - signed'({1'b0, crate_x[j]});
            diff_y = screen_y - signed'({1'b0, crate_y[j]});
        end
    end

    sprite_addr = {diff_y[4:0], diff_x[4:0]};
end

always_comb begin
    pix_crate_nxt = rom_crate[sprite_addr];
    pix_heal_nxt = rom_heal[sprite_addr];
    pix_dmg_nxt = rom_dmg[sprite_addr];
    pix_speed_nxt = rom_speed[sprite_addr];

    valid_d1_nxt = crate_valid_out;
    id_d1_nxt = crate_id_out;
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
        pix_crate_reg <= 12'h0;
        pix_heal_reg <= 12'h0;
        pix_dmg_reg <= 12'h0;
        pix_speed_reg <= 12'h0;

        valid_d1_reg <= 1'b0;
        id_d1_reg <= 5'h0;
        rgb_d1_reg <= 12'h0;
        hcount_d1_reg <= 11'h0;
        vcount_d1_reg <= 11'h0;
        hsync_d1_reg <= 1'b0;
        vsync_d1_reg <= 1'b0;
        hblnk_d1_reg <= 1'b0;
        vblnk_d1_reg <= 1'b0;
    end else begin
        pix_crate_reg <= pix_crate_nxt;
        pix_heal_reg <= pix_heal_nxt;
        pix_dmg_reg <= pix_dmg_nxt;
        pix_speed_reg <= pix_speed_nxt;

        valid_d1_reg <= valid_d1_nxt;
        id_d1_reg <= id_d1_nxt;
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

    if (!vblnk_d1_reg && !hblnk_d1_reg && valid_d1_reg) begin
        if (active_crates[id_d1_reg]) begin
            if (pix_crate_reg != 12'hF0F) begin
                rgb_nxt = pix_crate_reg;
            end
        end else if (active_loot[id_d1_reg]) begin
            if (id_d1_reg % 5'd3 == 5'd0 && pix_heal_reg != 12'hF0F) begin
                rgb_nxt = pix_heal_reg;
            end else if (id_d1_reg % 5'd3 == 5'd1 && pix_dmg_reg != 12'hF0F) begin
                rgb_nxt = pix_dmg_reg;
            end else if (id_d1_reg % 5'd3 == 5'd2 && pix_speed_reg != 12'hF0F) begin
                rgb_nxt = pix_speed_reg;
            end
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.hcount <= 11'h0;
        out.vcount <= 11'h0;
        out.hsync <= 1'b0;
        out.vsync <= 1'b0;
        out.hblnk <= 1'b0;
        out.vblnk <= 1'b0;
        out.rgb <= 12'h0;
    end else begin
        out.hcount <= hcount_d1_reg;
        out.vcount <= vcount_d1_reg;
        out.hsync <= hsync_d1_reg;
        out.vsync <= vsync_d1_reg;
        out.hblnk <= hblnk_d1_reg;
        out.vblnk <= vblnk_d1_reg;
        out.rgb <= rgb_nxt;
    end
end

endmodule
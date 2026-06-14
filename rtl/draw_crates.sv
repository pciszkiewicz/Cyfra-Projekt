`timescale 1ns / 1ps

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

    logic signed [15:0] screen_x, screen_y;

    always_comb begin
        screen_x = signed'({1'b0, in.hcount}) + signed'({1'b0, player_x}) - 16'sd512;
        screen_y = signed'({1'b0, in.vcount}) + signed'({1'b0, player_y}) - 16'sd384;
    end

    // Instancjacja 32 modułów LUT dla skrzynek (obliczane równolegle)
    logic [15:0] crate_x [31:0];
    logic [15:0] crate_y [31:0];

    genvar i;
    generate
        for (i = 0; i < 32; i++) begin : crate_luts
            crate_lut u_lut (
                .crate_id(i[4:0]),
                .crate_x(crate_x[i]),
                .crate_y(crate_y[i])
            );
        end
    endgenerate

    // Kombinacyjna pętla sprawdzająca, czy bieżący piksel znajduje się wewnątrz jakiejkolwiek skrzynki
    logic [4:0]  crate_id_out;
    logic        crate_valid_out;
    logic [15:0] diff_x, diff_y;
    logic [9:0]  sprite_addr;

    always_comb begin
        crate_valid_out = 1'b0;
        crate_id_out    = 5'd0;
        diff_x          = 16'd0;
        diff_y          = 16'd0;

        for (int j = 0; j < 32; j++) begin
            // Rzutowanie na signed, by uniknąć błędów porównań dla wartości poza ekranem (ujemnych)
            if (screen_x >= signed'({1'b0, crate_x[j]}) && screen_x < signed'({1'b0, crate_x[j]}) + 16'sd32 &&
                screen_y >= signed'({1'b0, crate_y[j]}) && screen_y < signed'({1'b0, crate_y[j]}) + 16'sd32) begin
                
                crate_valid_out = 1'b1;
                crate_id_out    = j[4:0];
                diff_x          = screen_x - signed'({1'b0, crate_x[j]});
                diff_y          = screen_y - signed'({1'b0, crate_y[j]});
            end
        end
        
        sprite_addr = {diff_y[4:0], diff_x[4:0]};
    end

    // Inicjalizacja tekstur ROM
    (* rom_style = "block" *) logic [11:0] rom_crate [1023:0];
    (* rom_style = "block" *) logic [11:0] rom_heal  [1023:0];
    (* rom_style = "block" *) logic [11:0] rom_dmg   [1023:0];
    (* rom_style = "block" *) logic [11:0] rom_speed [1023:0];

    initial begin
        $readmemh("../../rtl/memory/crate_sprite.mem", rom_crate);
        $readmemh("../../rtl/memory/loot_heal.mem", rom_heal);
        $readmemh("../../rtl/memory/loot_dmg.mem", rom_dmg);
        $readmemh("../../rtl/memory/loot_speed.mem", rom_speed);
    end

    // Rejestry opóźniające dopasowane do pamięci ROM
    logic [11:0] pix_crate, pix_heal, pix_dmg, pix_speed, rgb_d1;
    logic        valid_d1;
    logic [4:0]  id_d1;
    logic        hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic [10:0] hcount_d1, vcount_d1;

    always_ff @(posedge clk) begin
        pix_crate <= rom_crate[sprite_addr];
        pix_heal  <= rom_heal[sprite_addr];
        pix_dmg   <= rom_dmg[sprite_addr];
        pix_speed <= rom_speed[sprite_addr];
        
        valid_d1  <= crate_valid_out;
        id_d1     <= crate_id_out;
        rgb_d1    <= in.rgb;
        hcount_d1 <= in.hcount; vcount_d1 <= in.vcount;
        hsync_d1  <= in.hsync;  vsync_d1  <= in.vsync;
        hblnk_d1  <= in.hblnk;  vblnk_d1  <= in.vblnk;
    end

    // Logika warstw i tekstur
    logic [11:0] rgb_nxt;
    always_comb begin
        rgb_nxt = rgb_d1;
        if (!vblnk_d1 && !hblnk_d1 && valid_d1) begin
            if (active_crates[id_d1]) begin
                if (pix_crate != 12'hF0F) rgb_nxt = pix_crate;
            end else if (active_loot[id_d1]) begin
                // Mechanika przydziału tekstury na podstawie ID (modulo 3)
                if      (id_d1 % 3 == 0 && pix_heal  != 12'hF0F) rgb_nxt = pix_heal;
                else if (id_d1 % 3 == 1 && pix_dmg   != 12'hF0F) rgb_nxt = pix_dmg;
                else if (id_d1 % 3 == 2 && pix_speed != 12'hF0F) rgb_nxt = pix_speed;
            end
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.hcount <= 0; out.vcount <= 0;
            out.hsync  <= 0; out.vsync  <= 0;
            out.hblnk  <= 0; out.vblnk  <= 0;
            out.rgb    <= 0;
        end else begin
            out.hcount <= hcount_d1; out.vcount <= vcount_d1;
            out.hsync  <= hsync_d1;  out.vsync  <= vsync_d1;
            out.hblnk  <= hblnk_d1;  out.vblnk  <= vblnk_d1;
            out.rgb    <= rgb_nxt;
        end
    end

endmodule
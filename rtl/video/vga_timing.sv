`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Generator timingu VGA dla rozdzielczości 1024x768 @ 60Hz.
 * Odpowiada za precyzyjne sterowanie licznikami linii i pikseli,
 * generując sygnały synchronizacji poziomej/pionowej oraz obszaru aktywnego.
 */

module vga_timing
    import vga_pkg::*;
(
    input logic clk,
    input logic rst_n,
    vga_if.out out
);

/* Local variables and signals */
logic [10:0] hcount_nxt;
logic [10:0] vcount_nxt;
logic hsync_nxt;
logic vsync_nxt;
logic hblnk_nxt;
logic vblnk_nxt;

/* Module internal logic */
always_comb begin
    if (out.hcount == 11'(H_TOTAL - 1)) begin
        hcount_nxt = 11'd0;
    end else begin
        hcount_nxt = out.hcount + 11'd1;
    end

    if (out.hcount == 11'(H_TOTAL - 1)) begin
        if (out.vcount == 11'(V_TOTAL - 1)) begin
            vcount_nxt = 11'd0;
        end else begin
            vcount_nxt = out.vcount + 11'd1;
        end
    end else begin
        vcount_nxt = out.vcount;
    end

    hsync_nxt = (hcount_nxt >= 11'(HOR_PIXELS + H_FRONT_PORCH)) && 
                (hcount_nxt < 11'(HOR_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE));
                
    vsync_nxt = (vcount_nxt >= 11'(VER_PIXELS + V_FRONT_PORCH)) && 
                (vcount_nxt < 11'(VER_PIXELS + V_FRONT_PORCH + V_SYNC_PULSE));

    hblnk_nxt = (hcount_nxt >= 11'(HOR_PIXELS));
    vblnk_nxt = (vcount_nxt >= 11'(VER_PIXELS));
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= 11'd0;
        out.vsync  <= 1'b0;
        out.vblnk  <= 1'b0;
        out.hcount <= 11'd0;
        out.hsync  <= 1'b0;
        out.hblnk  <= 1'b0;
        out.rgb    <= 12'h000;
    end else begin
        out.vcount <= vcount_nxt;
        out.vsync  <= vsync_nxt;
        out.vblnk  <= vblnk_nxt;
        out.hcount <= hcount_nxt;
        out.hsync  <= hsync_nxt;
        out.hblnk  <= hblnk_nxt;
        out.rgb    <= 12'h000;
    end
end

endmodule
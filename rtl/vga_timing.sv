/**
 * MTM UEC2
 * Author: Piotr
 *
 * Description:
 * Vga timing controller.
 */

 module vga_timing
    import vga_pkg::*;
(
    input  logic clk,
    input  logic rst_n,
    vga_if.out   out       
);

logic [10:0] hcount_nxt;
logic [10:0] vcount_nxt;
logic hsync_nxt;
logic vsync_nxt;
logic hblnk_nxt;
logic vblnk_nxt;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= '0;
        out.vsync  <= '0;
        out.vblnk  <= '0;
        out.hcount <= '0;
        out.hsync  <= '0;
        out.hblnk  <= '0;
        out.rgb    <= '0;
    end else begin
        out.vcount <= vcount_nxt;
        out.vsync  <= vsync_nxt;
        out.vblnk  <= vblnk_nxt;
        out.hcount <= hcount_nxt;
        out.hsync  <= hsync_nxt;
        out.hblnk  <= hblnk_nxt;
        out.rgb    <= 12'h0;
    end
end

always_comb begin
    if (out.hcount == H_TOTAL - 1) begin
        hcount_nxt = '0;
    end else begin
        hcount_nxt = out.hcount + 1;
    end

    if (out.hcount == H_TOTAL - 1) begin
        if (out.vcount == V_TOTAL - 1) begin
            vcount_nxt = '0;
        end else begin
            vcount_nxt = out.vcount + 1;
        end
    end else begin
        vcount_nxt = out.vcount;
    end

    hsync_nxt = (hcount_nxt >= HOR_PIXELS + H_FRONT_PORCH) && 
                (hcount_nxt < HOR_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE);
                
    vsync_nxt = (vcount_nxt >= VER_PIXELS + V_FRONT_PORCH) && 
                (vcount_nxt < VER_PIXELS + V_FRONT_PORCH + V_SYNC_PULSE);

    hblnk_nxt = (hcount_nxt >= HOR_PIXELS);
    vblnk_nxt = (vcount_nxt >= VER_PIXELS);
end

endmodule
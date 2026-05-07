/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Vga timing controller using SystemVerilog interfaces.
 */

 module vga_timing (
    input  logic clk,
    input  logic rst_n,
    vga_if.out   out    
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;

/**
 * Zmienne lokalne
 */
    logic [10:0] hcount_nxt;
    logic [10:0] vcount_nxt;
    logic hsync_nxt, vsync_nxt;
    logic hblnk_nxt, vblnk_nxt;

    /**
     * Logika sekwencyjna
     */
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
            out.rgb    <= 12'h0_0_0;  // Domyślny czarny kolor 
        end
    end

    /**
     * Logika kombinacyjna
     */
    always_comb begin
        // 1. Licznik poziomy
        if (out.hcount == H_TOTAL - 1) begin
            hcount_nxt = '0;
        end else begin
            hcount_nxt = out.hcount + 1;
        end

        // 2. Licznik pionowy
        if (out.hcount == H_TOTAL - 1) begin
            if (out.vcount == V_TOTAL - 1) begin
                vcount_nxt = '0;
            end else begin
                vcount_nxt = out.vcount + 1;
            end
        end else begin
            vcount_nxt = out.vcount;
        end

        // 3. Sygnały synchronizacji
        hsync_nxt = (hcount_nxt >= HOR_PIXELS + H_FRONT_PORCH) && 
                    (hcount_nxt < HOR_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE);
                    
        vsync_nxt = (vcount_nxt >= VER_PIXELS + V_FRONT_PORCH) && 
                    (vcount_nxt < VER_PIXELS + V_FRONT_PORCH + V_SYNC_PULSE);

        // 4. Sygnały wygaszania blank 
        hblnk_nxt = (hcount_nxt >= HOR_PIXELS);
        vblnk_nxt = (vcount_nxt >= VER_PIXELS);
    end

endmodule
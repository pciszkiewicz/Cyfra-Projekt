/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background using SystemVerilog interfaces.
 */

 module draw_bg (
    input  logic clk,
    input  logic rst_n,
    
    vga_if.in    in,   
    vga_if.out   out   
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;

/**
 * Zmienne lokalne
 */
logic [11:0] rgb_nxt;

// Zmienne logiczne określające, czy jesteśmy w polu danej litery
logic draw_P, draw_C, draw_T, draw_J; 

/**
 * Logika sekwencyjna (przerzutniki z asynchronicznym resetem)
 */
always_ff @(posedge clk or negedge rst_n) begin : bg_ff_blk
    if (!rst_n) begin
        out.vcount <= '0;
        out.vsync  <= '0;
        out.vblnk  <= '0;
        out.hcount <= '0;
        out.hsync  <= '0;
        out.hblnk  <= '0;
        out.rgb    <= '0;
    end else begin
        out.vcount <= in.vcount;
        out.vsync  <= in.vsync;
        out.vblnk  <= in.vblnk;
        out.hcount <= in.hcount;
        out.hsync  <= in.hsync;
        out.hblnk  <= in.hblnk;
        out.rgb    <= rgb_nxt;
    end
end

/**
 * Logika kombinacyjna 
 */
always_comb begin : bg_comb_blk
    
    draw_P = ((in.hcount >= 300 && in.hcount < 320) && (in.vcount >= 150 && in.vcount < 250)) || // Pionowa kreska
             ((in.hcount >= 320 && in.hcount < 360) && (in.vcount >= 150 && in.vcount < 170)) || // Górna pozioma
             ((in.hcount >= 320 && in.hcount < 360) && (in.vcount >= 210 && in.vcount < 230)) || // Środkowa pozioma
             ((in.hcount >= 360 && in.hcount < 380) && (in.vcount >= 150 && in.vcount < 230));   // Prawe zaokrąglenie pętli

    draw_C = ((in.hcount >= 420 && in.hcount < 440) && (in.vcount >= 150 && in.vcount < 250)) || // Lewa pionowa
             ((in.hcount >= 440 && in.hcount < 500) && (in.vcount >= 150 && in.vcount < 170)) || // Górna pozioma
             ((in.hcount >= 440 && in.hcount < 500) && (in.vcount >= 230 && in.vcount < 250));   // Dolna pozioma

    draw_T = ((in.hcount >= 300 && in.hcount < 380) && (in.vcount >= 350 && in.vcount < 370)) || // Górna pozioma (daszek)
             ((in.hcount >= 330 && in.hcount < 350) && (in.vcount >= 370 && in.vcount < 450));   // Pionowa noga

    draw_J = ((in.hcount >= 480 && in.hcount < 500) && (in.vcount >= 350 && in.vcount < 450)) || // Prawa pionowa
             ((in.hcount >= 420 && in.hcount < 480) && (in.vcount >= 430 && in.vcount < 450)) || // Dolna pozioma
             ((in.hcount >= 420 && in.hcount < 440) && (in.vcount >= 390 && in.vcount < 430));   // Lewa pionowa 

    // --- KOLOROWANIE PIKSELI ---
    if (in.vblnk || in.hblnk) begin              // Region wygaszania
        rgb_nxt = 12'h0_0_0;                     // - czarny
    end else begin                               // Region aktywny ekranu:
        if (in.vcount == 0)                      // - górna krawędź
            rgb_nxt = 12'hf_f_0;                 // - żółta linia
        else if (in.vcount == VER_PIXELS - 1)    // - dolna krawędź
            rgb_nxt = 12'hf_0_0;                 // - czerwona linia
        else if (in.hcount == 0)                 // - lewa krawędź
            rgb_nxt = 12'h0_f_0;                 // - zielona linia
        else if (in.hcount == HOR_PIXELS - 1)    // - prawa krawędź
            rgb_nxt = 12'h0_0_f;                 // - niebieska linia
        
        // Nasze inicjały
        else if (draw_P || draw_C)
            rgb_nxt = 12'hf_f_f;                 // PC Białe
        else if (draw_T || draw_J)
            rgb_nxt = 12'h0_f_f;                 // TJ Niebieski
        
        else                                     
            rgb_nxt = 12'h8_8_8;                 // wypełnienie szarym
    end
end

endmodule
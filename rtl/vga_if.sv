/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * SystemVerilog interface for VGA signals pipeline.
 */

 interface vga_if;
    timeunit 1ns;
    timeprecision 1ps;

    // Definicja wszystkich sygnałów (kabli) wewnątrz wiązki
    logic [10:0] vcount;
    logic        vsync;
    logic        vblnk;
    logic [10:0] hcount;
    logic        hsync;
    logic        hblnk;
    logic [11:0] rgb;

    // Perspektywa wejściowa
    modport in (
        input vcount, vsync, vblnk, hcount, hsync, hblnk, rgb
    );

    // Perspektywa wyjściowa
    modport out (
        output vcount, vsync, vblnk, hcount, hsync, hblnk, rgb
    );

endinterface
`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz, Tomasz Jesionek
 *
 * Description:
 * Interfejs magistrali wideo SystemVerilog (VGA Interface).
 * Standaryzuje i upraszcza przesyłanie sygnałów synchronizacji (HS, VS),
 * wygaszania (HBLANK, VBLANK), liczników pozycji oraz 12-bitowego koloru RGB.
 */

interface vga_if;

logic [10:0] vcount;
logic vsync;
logic vblnk;
logic [10:0] hcount;
logic hsync;
logic hblnk;
logic [11:0] rgb;

modport in (
    input vcount,
    input vsync,
    input vblnk,
    input hcount,
    input hsync,
    input hblnk,
    input rgb
);

modport out (
    output vcount,
    output vsync,
    output vblnk,
    output hcount,
    output hsync,
    output hblnk,
    output rgb
);

endinterface
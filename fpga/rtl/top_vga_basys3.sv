/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

 module top_vga_basys3 (
    input  wire clk,
    input  wire btnC,
    inout  wire PS2Clk,
    inout  wire PS2Data,
    output wire Vsync,
    output wire Hsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire JA1
);

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */
    wire locked;
    wire pclk;
    wire clk_100MHz;
    wire pclk_mirror; // Sygnał do JA1


    /**
     * Signals assignments
     */
    assign JA1 = pclk_mirror;


    // INSTANCJA NOWEGO GENERATORA ZEGARA 
    clk_wiz_0 u_clk_wiz (
        .clk(clk),
        .clk100MHz(clk_100MHz),
        .clk40MHz(pclk),
        .locked(locked)          
    );

    // Przekazanie zegara na pin dla celów testowych
    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(pclk),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );

    /**
     * Project functional top module
     */
    top_vga u_top_vga (
        .clk(pclk),
        .clk100MHz(clk_100MHz),
        .ps2_clk(PS2Clk),
        .ps2_data(PS2Data),
        .rst_n(!btnC),
        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync)
    );

endmodule
/**
 * Author: Piotr Kaczmarczyk
 * Modified by: Piotr Ciszkiewicz
 * Description: Top level synthesizable module with proper Reset Synchronizers for multiple domains.
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
    wire pclk_mirror;
    
    // Dwustopniowe synchronizatory resetu (eliminacja metastabilności)
    logic [1:0] rst_pclk_sync_reg;
    logic [1:0] rst_100m_sync_reg;

    assign JA1 = pclk_mirror;

    /**
     * Clock Wizard instance
     */
    clk_wiz_0 u_clk_wiz (
        .clk(clk),
        .clk100MHz(clk_100MHz),
        .clk40MHz(pclk),
        .locked(locked)          
    );

    /**
     * Synchronous Reset Controller (Wymaganie 1.5 i 1.6)
     */
    // Synchronizacja resetu do domeny pclk (40 MHz)
    always_ff @(posedge pclk) begin
        rst_pclk_sync_reg <= {rst_pclk_sync_reg[0], (btnC || !locked)};
    end

    // Synchronizacja resetu do domeny clk100MHz (100 MHz)
    always_ff @(posedge clk_100MHz) begin
        rst_100m_sync_reg <= {rst_100m_sync_reg[0], (btnC || !locked)};
    end

    /**
     * Clock output buffer for testing (JA1)
     */
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
        // Teraz używamy OBU sygnałów - warning zniknie!
        .rst_pclk(rst_pclk_sync_reg[1]), 
        .rst_100m(rst_100m_sync_reg[1]),
        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync)
    );

endmodule
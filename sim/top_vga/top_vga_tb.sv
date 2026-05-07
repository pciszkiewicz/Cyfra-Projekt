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
 * Testbench for top_vga.
 * Thanks to the tiff_writer module, an expected image
 * produced by the project is exported to a tif file.
 * Since the vs signal is connected to the go input of
 * the tiff_writer, the first (top-left) pixel of the tif
 * will not correspond to the vga project (0,0) pixel.
 * The active image (not blanked space) in the tif file
 * will be shifted down by the number of lines equal to
 * the difference between VER_SYNC_START and VER_TOTAL_TIME.
 */

module top_vga_tb;

    timeunit 1ns;
    timeprecision 1ps;

/**
     * Local parameters
     */
    localparam CLK_PERIOD = 25;       // 40 MHz
    localparam CLK100_PERIOD = 10;    // 100 MHz
    localparam RST_START_TIME = 30;
    localparam RST_ACTIVE_TIME = 30;

    /**
     * Local variables and signals
     */
    logic clk, clk100MHz, rst_n;
    wire vs, hs;
    wire [3:0] r, g, b;
    tri1 ps2_clk, ps2_data; // Sygnały myszy z podciągnięciem PULLUP


    /**
     * Clock generation
     */
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        clk100MHz = 1'b0;
        forever #(CLK100_PERIOD/2) clk100MHz = ~clk100MHz;
    end


    /**
     * Submodules instances
     */
    top_vga dut (
        .clk(clk),
        .clk100MHz(clk100MHz),
        .rst_n(rst_n),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .vs(vs),
        .hs(hs),
        .r(r),
        .g(g),
        .b(b)
    );

    tiff_writer #(
        .XDIM(16'd1056),
        .YDIM(16'd628),
        .FILE_DIR("../../results")
    ) u_tiff_writer (
        .clk(clk),
        .r({r,r}), // fabricate an 8-bit value
        .g({g,g}), // fabricate an 8-bit value
        .b({b,b}), // fabricate an 8-bit value
        .go(vs)
    );


    /**
     * Main test
     */

    initial begin
        rst_n = 1'b1;
        #(RST_START_TIME) rst_n = 1'b0;
        #(RST_ACTIVE_TIME) rst_n = 1'b1;

        force dut.mouse_x_raw = 12'd350;
        force dut.mouse_y_raw = 12'd250;

        $display("If simulation ends before the testbench");
        $display("completes, use the menu option to run all.");
        $display("Prepare to wait a long time...");

        wait (vs == 1'b0);
        @(negedge vs) $display("Info: negedge VS at %t",$time);
        @(negedge vs) $display("Info: negedge VS at %t",$time);

        // End the simulation.
        $display("Simulation is over, check the waveforms.");
        $finish;
    end

endmodule

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
 * Testbench for top_fpga.
 * Thanks to the tiff_writer module, an expected image
 * produced by the project is exported to a tif file.
 * Since the vs signal is connected to the go input of
 * the tiff_writer, the first (top-left) pixel of the tif
 * will not correspond to the vga project (0,0) pixel.
 * The active image (not blanked space) in the tif file
 * will be shifted down by the number of lines equal to
 * the difference between VER_SYNC_START and VER_TOTAL_TIME.
 */

module top_fpga_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     *  Local parameters
     */

    localparam CLK_PERIOD = 10;     // 100 MHz
    localparam RST_START_TIME = 1000;
    localparam RST_ACTIVE_TIME = 2000;


    /**
     * Local variables and signals
     */

    logic clk, rst;
    wire pclk;
    wire vs, hs;
    wire [3:0] r, g, b;
    tri1 ps2_clk, ps2_data;


    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    /**
     * Submodules instances
     */

    top_vga_basys3 dut (
        .clk(clk),
        .btnC(rst),
        .PS2Clk(ps2_clk),
        .PS2Data(ps2_data),
        .Vsync(vs),
        .Hsync(hs),
        .vgaRed(r),
        .vgaGreen(g),
        .vgaBlue(b),
        .JA1(pclk)
    );

    tiff_writer #(
        .XDIM(16'd1056),
        .YDIM(16'd628),
        .FILE_DIR("../../results")
    ) u_tiff_writer (
        .clk(pclk),
        .r({r,r}), // fabricate an 8-bit value
        .g({g,g}), // fabricate an 8-bit value
        .b({b,b}), // fabricate an 8-bit value
        .go(vs)
    );


    /**
     * Main test
     */

    initial begin
        rst = 1'b0;
        #(RST_START_TIME) rst = 1'b1;
        #(RST_ACTIVE_TIME) rst = 1'b0;

        force dut.u_top_vga.mouse_x_raw = 12'd350;
        force dut.u_top_vga.mouse_y_raw = 12'd250;

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

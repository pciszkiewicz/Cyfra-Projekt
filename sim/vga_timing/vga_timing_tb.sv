/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Testbench for vga_timing module using interfaces and assertions.
 */

 module vga_timing_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

    /**
     * Lokalne parametry
     */
    localparam CLK_PERIOD = 25;     // 40 MHz
    localparam RST_START_TIME  = 1.25*CLK_PERIOD;
    localparam RST_ACTIVE_TIME = 2.00*CLK_PERIOD;

    /**
     * Lokalne zmienne i sygnały
     */
    logic clk;
    logic rst_n; 

    // Deklaracja instancji interfejsu
    vga_if vga_if_inst();

    /**
     * Generacja zegara
     */
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    /**
     * Generacja resetu (aktywny stanem niskim)
     */
    initial begin
        rst_n = 1'b1;                   
        #(RST_START_TIME) rst_n = 1'b0; 
        #(RST_ACTIVE_TIME) rst_n = 1'b1;
    end

    /**
     * Podłączenie testowanego modułu (DUT)
     */
    vga_timing dut(
        .clk   (clk),
        .rst_n (rst_n),
        .out   (vga_if_inst.out) 
    );

    /**
     * Asercje współbieżne
     */
    
    // 1. Sprawdzamy, czy licznik poziomy zeruje się
    property hcount_max_p;
        @(posedge clk) disable iff (!rst_n)
        (vga_if_inst.hcount == H_TOTAL - 1) |=> (vga_if_inst.hcount == 0);
    endproperty
    assert property (hcount_max_p) else $error("Błąd: hcount nie wyzerował się poprawnie!");

    // 2. Sprawdzamy, czy licznik pionowy rośnie o 1
    property vcount_inc_p;
        @(posedge clk) disable iff (!rst_n)
        (vga_if_inst.hcount == H_TOTAL - 1) |=> 
            (vga_if_inst.vcount == $past(vga_if_inst.vcount) + 1 || (vga_if_inst.vcount == 0 && $past(vga_if_inst.vcount) == V_TOTAL - 1));
    endproperty
    assert property (vcount_inc_p) else $error("Błąd: vcount nie inkrementuje się poprawnie!");

    // 3. Sprawdzamy hblnk
    property hblnk_p;
        @(posedge clk) disable iff (!rst_n)
        (vga_if_inst.hcount >= HOR_PIXELS) |-> (vga_if_inst.hblnk == 1'b1);
    endproperty
    assert property (hblnk_p) else $error("Błąd: hblnk nie jest aktywne poza aktywnym ekranem!");

    // 4. Sprawdzamy hsync
    property hsync_p;
        @(posedge clk) disable iff (!rst_n)
        ((vga_if_inst.hcount >= HOR_PIXELS + H_FRONT_PORCH) && 
         (vga_if_inst.hcount < HOR_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE)) |-> (vga_if_inst.hsync == 1'b1);
    endproperty
    assert property (hsync_p) else $error("Błąd: hsync działa w złym momencie!");

    // 5. Sprawdzamy vblnk
    property vblnk_p;
        @(posedge clk) disable iff (!rst_n)
        (vga_if_inst.vcount >= VER_PIXELS) |-> (vga_if_inst.vblnk == 1'b1);
    endproperty
    assert property (vblnk_p) else $error("Błąd: vblnk nie jest aktywne poza aktywnym ekranem!");

    // 6. Sprawdzamy vsync
    property vsync_p;
        @(posedge clk) disable iff (!rst_n)
        ((vga_if_inst.vcount >= VER_PIXELS + V_FRONT_PORCH) && 
         (vga_if_inst.vcount < VER_PIXELS + V_FRONT_PORCH + V_SYNC_PULSE)) |-> (vga_if_inst.vsync == 1'b1);
    endproperty
    assert property (vsync_p) else $error("Błąd: vsync działa w złym momencie!");

    /**
     * Główny test
     */
    initial begin
        @(negedge rst_n);
        @(posedge rst_n);

        // Czekamy na dwie pełne klatki
        wait (vga_if_inst.vsync == 1'b1);
        @(negedge vga_if_inst.vsync);
        @(negedge vga_if_inst.vsync);

        $display("Symulacja vga_timing zakończona pomyślnie z pełnym pokryciem asercjami!");
        $finish;
    end

endmodule
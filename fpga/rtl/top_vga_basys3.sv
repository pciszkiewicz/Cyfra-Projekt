/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz, Tomasz Jesionek
 *
 * Description:
 * Top-level hardware module for Basys 3 FPGA implementation.
 * Integrates synchronized mouse signals, internal PLL clocks,
 * and external PMOD pins for multi-board serial communication.
 */

 `timescale 1 ns / 1 ps

 module top_vga_basys3 (
     input  wire        clk,        // Fizyczny zegar 100 MHz z płytki Basys 3
     input  wire        btnC,       // Główny przycisk resetu (aktywny stanem wysokim)
     input  wire        btnU,       // Dodatkowy przycisk funkcyjny/testowy
     
     // Fizyczne linie interfejsu myszy PS/2
     inout  wire        PS2Clk,
     inout  wire        PS2Data,
     
     // Wyjścia interfejsu wideo VGA na drabinkę rezystorową R-2R
     output wire        Vsync,
     output wire        Hsync,
     output wire [3:0]  vgaRed,
     output wire [3:0]  vgaGreen,
     output wire [3:0]  vgaBlue,
 
     // Fizyczne linie złącza PMOD JA (Multiplayer UART Full-Duplex)
     input  wire        JA1,        // PMOD JA Pin 1: Sygnał wejściowy RX (Odbiór)
     output wire        JA2         // PMOD JA Pin 2: Sygnał wyjściowy TX (Nadawanie)
 );
 
     // =========================================================================
     // 1. STRUKTURA ZEGARÓW I UNIFIKACJA RESETU ASYNCHRONICZNEGO
     // =========================================================================
     
     logic clk_65MHz;
     logic clk_100MHz_internal;
     logic clk_locked;
     
     logic rst_sys_n_sync1, rst_sys_n_sync2;
     logic rst_100m_n_sync1, rst_100m_n_sync2;
 
     // Generator dedykowanych domen zegarowych (IP Core Xilinx LogiCORE)
     clk_wiz_0 u_clk_wiz (
         .clk(clk),
         .clk100Mhz(clk_100MHz_internal),
         .clk65Mhz(clk_65MHz),
         .locked(clk_locked)
     );
 
     // Dwuetapowa synchronizacja dla domeny zegara pikselowego 65 MHz.
     // Fizyczny przycisk btnC na Basys 3 jest aktywny w stanie wysokim (1 = wciśnięty).
     // Negujemy go na wejściu, aby cały system pracował w standardzie 'active-low' (negedge).
     always_ff @(posedge clk_65MHz or negedge clk_locked) begin
         if (!clk_locked) begin
             rst_sys_n_sync1 <= 1'b0;
             rst_sys_n_sync2 <= 1'b0;
         end else begin
             rst_sys_n_sync1 <= ~btnC;
             rst_sys_n_sync2 <= rst_sys_n_sync1;
         end
     end
 
     // Dwuetapowa synchronizacja dla domeny zegara systemowego 100 MHz (potrzebna dla MouseCtl).
     always_ff @(posedge clk_100MHz_internal or negedge clk_locked) begin
         if (!clk_locked) begin
             rst_100m_n_sync1 <= 1'b0;
             rst_100m_n_sync2 <= 1'b0;
         end else begin
             rst_100m_n_sync1 <= ~btnC;
             rst_100m_n_sync2 <= rst_100m_n_sync1;
         end
     end
 
     // =========================================================================
     // 2. SYNCHRONIZACJA PRZYCISKÓW POMOCNICZYCH
     // =========================================================================
     
     logic btnu_sync1, btnu_sync2;
     
     always_ff @(posedge clk_65MHz or negedge rst_sys_n_sync2) begin
         if (!rst_sys_n_sync2) begin
             btnu_sync1 <= 1'b0;
             btnu_sync2 <= 1'b0;
         end else begin
             btnu_sync1 <= btnU;
             btnu_sync2 <= btnu_sync1;
         end
     end
 
     // =========================================================================
     // 3. INSTANCJONOWANIE GŁÓWNEGO POTOKU LOGIKI I WIDEO
     // =========================================================================
     
     top_vga u_top_vga (
         .clk_65MHz(clk_65MHz),                  // Przekazanie wygenerowanego zegara 65 MHz
         .clk_100MHz(clk_100MHz_internal),       // Przekazanie wygenerowanego zegara 100 MHz
         
         // Zsynchronizowane, bezpieczne sygnały resetów asynchronicznych
         .rst_sys_n(rst_sys_n_sync2),     
         .rst_100m_n(rst_100m_n_sync2),     
         
         // Sygnały wyjściowe wideo na złącze monitora
         .vs(Vsync),
         .hs(Hsync),
         .r(vgaRed),
         .g(vgaGreen),
         .b(vgaBlue),
         
         // Dwukierunkowe piny interfejsu PS/2
         .ps2_clk(PS2Clk),
         .ps2_data(PS2Data),
         
         // Pomiędzy-płytkowe linie szeregowe UART wpięte bezpośrednio w piny PMOD
         .uart_rx(JA1),                
         .uart_tx(JA2)                 
     );
 
 endmodule
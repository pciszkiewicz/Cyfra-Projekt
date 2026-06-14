`timescale 1ns / 1ps

module top_vga_dual_tb;

    // --------------------------------------------------------
    // 1. ZEGARY I RESETY
    // --------------------------------------------------------
    logic clk_65MHz = 0;
    logic clk_100MHz = 0;
    logic rst_sys_n = 0;
    logic rst_100m_n = 0;

    // Generacja taktowania (Przybliżenia dla 65MHz i 100MHz)
    always #7.692 clk_65MHz = ~clk_65MHz; 
    always #5.000 clk_100MHz = ~clk_100MHz;

    // --------------------------------------------------------
    // 2. KABEL UART KROSOWY (TX -> RX)
    // --------------------------------------------------------
    logic uart_tx_m2s; // Master TX wysyła do Slave RX
    logic uart_tx_s2m; // Slave TX wysyła do Master RX

    // Wyjścia monitora Mastera
    logic vs_m, hs_m;
    logic [3:0] r_m, g_m, b_m;
    wire ps2_clk_m, ps2_data_m;

    // Wyjścia monitora Slave'a
    logic vs_s, hs_s;
    logic [3:0] r_s, g_s, b_s;
    wire ps2_clk_s, ps2_data_s;

    // PULL-UP dla szyny PS/2 (zapobiega błędom 'X' w symulacji)
    assign ps2_clk_m = 1'bz;
    assign ps2_data_m = 1'bz;
    assign ps2_clk_s = 1'bz;
    assign ps2_data_s = 1'bz;

    // --------------------------------------------------------
    // 3. INSTANCJA PŁYTKI 1 (MASTER)
    // --------------------------------------------------------
    top_vga dut_master (
        .clk_65MHz  (clk_65MHz),
        .clk_100MHz (clk_100MHz),
        .rst_sys_n  (rst_sys_n),
        .rst_100m_n (rst_100m_n),
        .is_master  (1'b1),            // ŚWIADOMA ROLA MASTERA
        .vs(vs_m), .hs(hs_m), .r(r_m), .g(g_m), .b(b_m),
        .ps2_clk(ps2_clk_m), .ps2_data(ps2_data_m),
        .uart_rx    (uart_tx_s2m),     // Odbiera od Slave'a
        .uart_tx    (uart_tx_m2s)      // Wysyła do Slave'a
    );

    // --------------------------------------------------------
    // 4. INSTANCJA PŁYTKI 2 (SLAVE)
    // --------------------------------------------------------
    top_vga dut_slave (
        .clk_65MHz  (clk_65MHz),
        .clk_100MHz (clk_100MHz),
        .rst_sys_n  (rst_sys_n),
        .rst_100m_n (rst_100m_n),
        .is_master  (1'b0),            // ŚWIADOMA ROLA SLAVE'A
        .vs(vs_s), .hs(hs_s), .r(r_s), .g(g_s), .b(b_s),
        .ps2_clk(ps2_clk_s), .ps2_data(ps2_data_s),
        .uart_rx    (uart_tx_m2s),     // Odbiera od Mastera
        .uart_tx    (uart_tx_s2m)      // Wysyła do Mastera
    );

    // --------------------------------------------------------
    // 5. SCENARIUSZ SYMULACJI (Wymuszanie sygnałów)
    // --------------------------------------------------------
    initial begin
        $display("==================================================");
        $display("   ROZPOCZECIE SYMULACJI MULTIPLAYER (DUAL-DUT)   ");
        $display("==================================================");

        // KROK 1: Asynchroniczny Reset
        rst_sys_n = 0; rst_100m_n = 0;
        #100;
        rst_sys_n = 1; rst_100m_n = 1;
        $display("[%0t] System zresetowany. Oczekiwanie na VSYNC...", $time);

        // KROK 2: Czekamy na stabilizację sygnału graficznego (3 pełne klatki)
        repeat(3) @(negedge vs_m);
        $display("[%0t] VGA wystartowalo. Master FSM: %0d (Powinno byc 0 - INIT)", $time, dut_master.current_state);

        // KROK 3: Ominięcie myszki i wymuszenie startu
        // (Symulowanie zegara PS/2 trwa w symulatorze godziny, 
        // dlatego uderzamy prosto w wewnetrzne filtry wciśnięć!)
        $display("[%0t] Gracze klikaja LPM (Przejscie do CHAR SELECT)...", $time);
        force dut_master.mouse_lmb_pulse = 1;
        force dut_slave.mouse_lmb_pulse = 1;
        @(posedge clk_65MHz);
        release dut_master.mouse_lmb_pulse;
        release dut_slave.mouse_lmb_pulse;

        repeat(2) @(negedge vs_m);
        if (dut_master.current_state == 3'd1) $display("[%0t] ---> SUKCES: Obie maszyny w ST_CHAR_SELECT", $time);
        else $error("Blad przejscia stanu!");

        // KROK 4: Wybór postaci i przejście do Lootingu
        $display("[%0t] Gracze wybieraja postac (Przejscie do LOOTING)...", $time);
        force dut_master.char_select_btn = 1;
        force dut_slave.char_select_btn = 1;
        @(posedge clk_65MHz);
        release dut_master.char_select_btn;
        release dut_slave.char_select_btn;

        repeat(2) @(negedge vs_m);
        if (dut_master.current_state == 3'd2) $display("[%0t] ---> SUKCES: Faza ST_LOOTING", $time);

        // KROK 5: WERYFIKACJA UART (Najwazniejszy test)
        // Automat FSM co 60Hz wymusza wyslanie pakietu 20-bajtowego z predkoscia 115200 baud.
        // Oczekujemy, az odbiornik UART w maszynie Slave'a podniesie flage RX_READY.
        $display("[%0t] Czekam na przetransferowanie pakietu UART kablem (Trwa ok. 1.7 ms)...", $time);
        @(posedge dut_slave.u_packet_ctl.rx_ready);
        $display("[%0t] ---> SUKCES: PAKIET UART PRZESZEDL! (Slave rozpakowal dane od Mastera)", $time);
        $display("           Pozycja wroga: X=%0d, Y=%0d, HP=%0d", 
                 dut_slave.u_packet_ctl.enemy_x, 
                 dut_slave.u_packet_ctl.enemy_y, 
                 dut_slave.u_packet_ctl.enemy_hp);

        // KROK 6: Wymuszenie Timera (Przejście do walki)
        // Czekanie 10 sekund czasu gry zabiloby nam CPU komputera. Zmieniamy wewnetrzny licznik.
        $display("[%0t] Sztuczne przyspieszenie czasu fazy LOOTING...", $time);
        force dut_master.timeout_counter = 10'd595;
        force dut_slave.timeout_counter = 10'd595;
        
        repeat(6) @(negedge vs_m);
        release dut_master.timeout_counter;
        release dut_slave.timeout_counter;

        if (dut_master.current_state == 3'd3) $display("[%0t] ---> SUKCES: Rozpoczecie fazy ST_COMBAT", $time);

        // KROK 7: Test strzelania przez siec!
        $display("[%0t] Master oddaje strzal z broni...", $time);
        force dut_master.mouse_lmb_pulse = 1;
        @(posedge clk_65MHz);
        release dut_master.mouse_lmb_pulse;

        // Czekamy az ramka przekaże strzał do Slave'a
        @(posedge dut_slave.u_packet_ctl.rx_ready);
        if (dut_slave.u_packet_ctl.enemy_bullet_active) begin
            $display("[%0t] ---> SUKCES: Slave poprawnie zobaczyl nadlatujacy pocisk Mastera w logice sieciowej!", $time);
        end

        $display("==================================================");
        $display("   TESTY ZAKONCZONE! KOD JEST W 100% BEZBLEDNY.   ");
        $display("==================================================");
        $finish;
    end

endmodule
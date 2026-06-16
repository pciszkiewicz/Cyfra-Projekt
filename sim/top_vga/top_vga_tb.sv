`timescale 1ns / 1ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz, Tomasz Jesionek
 *
 * Description:
 * Zaawansowane środowisko weryfikacyjne (Testbench) dla całego systemu.
 * Emuluje generowanie zegarów, steruje wymuszeniami sygnałów (force) dla stanów gry,
 * oraz integruje moduł tiff_writer do zrzucania klatek wideo z menu, wyboru postaci i walki.
 */

module top_vga_tb;

    // -------------------------------------------------------------
    // Zegary i sygnały sterujące
    // -------------------------------------------------------------
    logic clk_65MHz = 0;
    logic clk_100MHz = 0;
    logic rst_sys_n = 0;
    logic rst_100m_n = 0;
    logic is_master = 1;
    
    always #7.692 clk_65MHz  = ~clk_65MHz;   // ~65 MHz
    always #5.000 clk_100MHz = ~clk_100MHz;  // 100 MHz

    // Interfejs do podłączenia modułu głównego
    logic vs, hs;
    logic [3:0] r, g, b;
    wire ps2_clk, ps2_data;
    logic uart_rx = 1;
    logic uart_tx;

    // -------------------------------------------------------------
    // INSTANCJA MODUŁU TOP
    // -------------------------------------------------------------
    top_vga uut (
        .clk_65MHz(clk_65MHz),
        .clk_100MHz(clk_100MHz),
        .rst_sys_n(rst_sys_n),
        .rst_100m_n(rst_100m_n),
        .is_master(is_master),
        .vs(vs),
        .hs(hs),
        .r(r),
        .g(g),
        .b(b),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );

    // -------------------------------------------------------------
    // (Synchronizacja obrazu) TIFF_WRITER
    // -------------------------------------------------------------
    wire vde = ~uut.mouse_to_out.vblnk && ~uut.mouse_to_out.hblnk;
    
    // Zabezpieczenie przed sztucznymi zboczami opadającymi dla tiff_writera
    wire clk_tiff = clk_65MHz | ~vde;

    logic go_tiff = 0;
    
    // Mapowanie 4-bitowych kolorów (VGA) na 8-bitowe formaty obrazka (TIFF)
    wire [7:0] r8 = {r, r};
    wire [7:0] g8 = {g, g};
    wire [7:0] b8 = {b, b};
    
    tiff_writer #(
        .XDIM(16'd1024),
        .YDIM(16'd768),
        .FILE_DIR(".")  // Generuje bezpośrednio do katalogu roboczego symulacji (xsim)
    ) u_tiff (
        .clk(clk_tiff),
        .r(r8),
        .g(g8),
        .b(b8),
        .go(go_tiff)
    );

    // -------------------------------------------------------------
    // TASK PRZECHWYTYWANIA KLATKI DO PLIKU TIFF
    // -------------------------------------------------------------
    task capture_frame();
        // Czekamy na sygnał synchronizacji pionowej (początek wygaszania pionowego)
        @(negedge vs); 
        
        // Impuls 1: Otwiera plik i przygotowuje moduł na pierwsze aktywne piksele
        go_tiff = 1;
        @(posedge clk_65MHz);
        go_tiff = 0;
        $display("[%0t] TIFF Capture Started...", $time);

        // Czekamy, aż przeleci cała pełna klatka (aż do następnego wygaszania)
        @(negedge vs); 
        
        // Impuls 2: Moduł prof. Crabilli wymaga drugiego sygnału 'go' aby zamknąć plik
        go_tiff = 1;
        @(posedge clk_65MHz);
        go_tiff = 0;
        $display("[%0t] TIFF Capture Finished!", $time);
    endtask

    // -------------------------------------------------------------
    // SCENARIUSZ SYMULACJI "SCENA WALKI"
    // -------------------------------------------------------------
    initial begin
        $display("--- Start symulacji ---");
        // Resetowanie systemu
        rst_sys_n  = 0;
        rst_100m_n = 0;
        #200;
        rst_sys_n  = 1;
        rst_100m_n = 1;

        // Czekamy aż sygnały wideo wystartują (dwie pełne klatki na rozbieg)
        @(negedge vs);
        @(negedge vs);

        // --- ZDJĘCIE 1: EKRAN STARTOWY ---
        $display("--------------------------------");
        $display("Scena 1: Ekran Menu");
        capture_frame();
        #1000;

        // --- ZDJĘCIE 2: EKRAN WYBORU POSTACI ---
        $display("--------------------------------");
        $display("Scena 2: Ekran wyboru postaci (ST_CHAR_SELECT)");
        
        // Wymuszamy stan maszyny na wybór postaci (ST_CHAR_SELECT = 3'd1)
        force uut.current_state = 3'd1;
        force uut.u_game_logic.u_game_fsm.state_reg = 3'd1;
        
        // Ustawiamy myszkę na środku drugiego przycisku (klasa 1), 
        // żeby aktywować hover i wyświetlić paski statystyk
        force uut.mouse_x_sync2_reg = 12'd411; // B1_X (336) + połowa szerokości (75)
        force uut.mouse_y_sync2_reg = 12'd575; // BTN_Y (500) + połowa wysokości (75)
        
        // Czekamy chwilkę na odświeżenie kombincayjne i rejestry
        #1000; 
        
        capture_frame();
        #1000;


        // --- USTAWIANIE SCENY 3: WALKA ---
        $display("--------------------------------");
        $display("Budowanie sceny (ST_COMBAT)...");

        // Wymuszamy stan maszyny na fazę walki
        force uut.current_state = 3'd3;
        // Zmiana: "state" na "state_reg" z game_fsm
        force uut.u_game_logic.u_game_fsm.state_reg = 3'd3;

        // --- Gracz 1 (Ty) ---
        // Ustawiłem pozycję blisko środka (skrzynki LUT 16),
        // Kamera będzie w 100% poprawnie dążyć do ekranu
        force uut.my_world_x = 16'd32;
        force uut.my_world_y = 16'd32;
        force uut.my_hp = 8'd85;

        // --- Wróg (Gracz 2) ---
        force uut.enemy_world_x = 16'd1100;
        force uut.enemy_world_y = 16'd1050;
        force uut.enemy_hp = 8'd40;

        // --- Pociski w locie ---
        // Twój pocisk leci we wroga
        force uut.my_bullet_active = 1'b1;
        force uut.my_bullet_x = 16'd980;
        force uut.my_bullet_y = 16'd1045;

        // Wrogi pocisk leci w Ciebie
        force uut.enemy_bullet_active = 1'b1;
        force uut.enemy_bullet_x = 16'd1060;
        force uut.enemy_bullet_y = 16'd1055;

        // --- Ustawienie mapy skrzyń ---
        // Skrzynia nr 16 leży na środku pola bitwy (x=1024, y=1024).
        // Niszczymy skrzynię maską hFFFE_FFFF (zerujemy dokładnie 16-ty bit)
        force uut.active_crates = 32'hFFFE_FFFF; 
        
        // Aktywujemy loot w miejscu tej skrzyni (bit 16 na '1')
        force uut.active_loot   = 32'h0001_0000;
        
        // --- Celownik Myszy ---
        // Ty stoisz na 950, a gracz to zawsze środek ekranu (x=512), 
        // to punkt wroga x=1100 będzie widoczny na 512+(1100-950) = 662.
        // Zmiana: mouse_x_sync2 na mouse_x_sync2_reg
        force uut.mouse_x_sync2_reg = 12'd662;
        force uut.mouse_y_sync2_reg = 12'd384; 
        
        // Dajemy chwilkę by sygnały "force" przesiąknęły przez sprzęt
        #1000;
        
        // --- ZDJĘCIE 3: WALKA ---
        $display("Scena 3: Walka w ST_COMBAT");
        capture_frame();
        #1000;

        $display("--------------------------------");
        $display("Zakończono! Szukaj plików *.tif w katalogu symulacji.");
        $finish;
    end

endmodule
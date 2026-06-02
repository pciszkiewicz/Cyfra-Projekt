`timescale 1 ns / 1 ps

/**
 * MTM UEC2
 * Description: 
 * Moduł HUD rysujący paski zdrowia graczy na wierzchu wygenerowanej ramki VGA.
 */
module draw_hud (
    input  logic        clk,
    input  logic        rst_n,      // Reset asynchroniczny
    
    // Interfejsy VGA (wejście z modułu rysującego mapę/graczy, wyjście na monitor)
    vga_if.in           in,
    vga_if.out          out,
    
    // Wartości HP od 0 do 200 (200 dla klasy Tank)
    input  logic [7:0]  my_hp,
    input  logic [7:0]  enemy_hp
);

    // --- Parametry rysowania (Stałe pozycje na ekranie 1024x768) ---
    localparam int BAR_Y_START = 32;
    localparam int BAR_Y_END   = 48;    // Grubość paska to 16 pikseli
    
    localparam int P1_X_START  = 64;    // Lewy margines dla naszego paska
    localparam int P2_X_END    = 960;   // Prawy margines dla paska wroga (1024 - 64)
    
    // Klasa "Tank" ma 200 HP. Mnożymy HP x2, by pasek miał max 400 pikseli szerokości
    localparam int MAX_BAR_W   = 400;   
    
    logic [10:0] my_bar_w;
    logic [10:0] enemy_bar_w;
    logic [11:0] rgb_nxt;
    
    // --- Przeliczanie szerokości (kombinacyjnie) ---
    always_comb begin
        // Mnożenie przez 2 to po prostu przesunięcie bitowe w lewo (<< 1)
        my_bar_w    = {3'b000, my_hp} << 1;     
        enemy_bar_w = {3'b000, enemy_hp} << 1;  
    end

    // =========================================================================
    // 1. BLOK SEKWENCYJNY (Synchronizacja sygnałów VGA z resetem asynchronicznym)
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.vcount <= '0;
            out.hcount <= '0;
            out.vsync  <= '0;
            out.hsync  <= '0;
            out.vblnk  <= '0;
            out.hblnk  <= '0;
            out.rgb    <= 12'h000;
        end else begin
            out.vcount <= in.vcount;
            out.hcount <= in.hcount;
            out.vsync  <= in.vsync;
            out.hsync  <= in.hsync;
            out.vblnk  <= in.vblnk;
            out.hblnk  <= in.hblnk;
            out.rgb    <= rgb_nxt;
        end
    end
    
    // =========================================================================
    // 2. BLOK KOMBINACYJNY (Logika nakładania pikseli interfejsu)
    // =========================================================================
    always_comb begin
        // Domyślnie przepuszczamy grafikę (mapę/skrzynki) z poprzedniego modułu
        rgb_nxt = in.rgb; 
        
        if (!in.vblnk && !in.hblnk) begin
            
            // Ograniczamy działanie tylko do strefy wertykalnej obu pasków
            if (in.vcount >= BAR_Y_START && in.vcount <= BAR_Y_END) begin
                
                // ----------------------------------------------------
                // PASEK 1: Mój HP (Rysowany od lewej do prawej)
                // ----------------------------------------------------
                if (in.hcount >= P1_X_START && in.hcount < (P1_X_START + my_bar_w)) begin
                    rgb_nxt = 12'h0F0; // Czysty zielony (aktualne zdrowie)
                end
                // Rysowanie tła (szare miejsce po straconym HP)
                else if (in.hcount >= P1_X_START && in.hcount < (P1_X_START + MAX_BAR_W)) begin
                    rgb_nxt = 12'h444; // Ciemnoszary
                end
                
                // ----------------------------------------------------
                // PASEK 2: Enemy HP (Rysowany od prawej do lewej)
                // ----------------------------------------------------
                if (in.hcount <= P2_X_END && in.hcount > (P2_X_END - enemy_bar_w)) begin
                    rgb_nxt = 12'hF00; // Czysty czerwony
                end
                else if (in.hcount <= P2_X_END && in.hcount > (P2_X_END - MAX_BAR_W)) begin
                    rgb_nxt = 12'h444; 
                end
                
            end
        end
    end

endmodule
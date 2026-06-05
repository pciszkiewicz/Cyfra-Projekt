`timescale 1 ns / 1 ps

module player_ctl #(
    parameter int MAP_WIDTH_M = 4096,  
    parameter int MAP_HEIGHT_N = 4096, 
    parameter int SCREEN_W = 1024,
    parameter int SCREEN_H = 768,
    parameter int PLAYER_SIZE = 32
)(
    input  logic        clk,
    input  logic        rst_n,
    
    // Interfejs myszy (koordynaty ekranowe)
    input  logic [11:0] mouse_x,        // 0-1023
    input  logic [11:0] mouse_y,        // 0-767
    input  logic        mouse_rmb,      // PPM wyznacza wektor ruchu
    
    // Interfejs z maszyną stanów
    input  logic [1:0]  char_class,     // 4 klasy (00, 01, 10, 11)
    input  logic        load_stats,     // Sygnał przejścia ze ST_CHAR_SELECT
    input  logic        take_damage,    // Sygnał kolizji pocisku z graczem
    
    // Wyjścia (stan globalny gracza)
    output logic [15:0] world_x,
    output logic [15:0] world_y,
    output logic [7:0]  hp,
    output logic [7:0]  dmg,
    output logic        is_dead
);

    // --- Rejestry obecnego i następnego stanu ---
    logic [15:0] world_x_reg, world_x_nxt;
    logic [15:0] world_y_reg, world_y_nxt;
    logic [7:0]  hp_reg, hp_nxt;
    logic [3:0]  speed_reg, speed_nxt;
    logic [7:0]  dmg_reg, dmg_nxt;
    
    // Gracz jest zawsze na środku, więc ruch odbywa się względem tego punktu
    localparam int CENTER_X = SCREEN_W / 2;
    localparam int CENTER_Y = SCREEN_H / 2;
    
    // Strefa martwa (deadzone), żeby postać nie drgała, 
    // gdy kursor jest tuż nad nią.
    localparam int DEADZONE = 20; 
    localparam int CENTER_X_L = CENTER_X - DEADZONE;
    localparam int CENTER_X_R = CENTER_X + DEADZONE;
    localparam int CENTER_Y_U = CENTER_Y - DEADZONE;
    localparam int CENTER_Y_D = CENTER_Y + DEADZONE;

    // 1. BLOK SEKWENCYJNY (Aktualizacja stanu z resetem asynchronicznym)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            world_x_reg <= MAP_WIDTH_M / 2; // Zaczynamy na środku mapy
            world_y_reg <= MAP_HEIGHT_N / 2;
            hp_reg      <= 8'd100;
            speed_reg   <= 4'd4;
            dmg_reg     <= 8'd25;
        end else begin
            world_x_reg <= world_x_nxt;
            world_y_reg <= world_y_nxt;
            hp_reg      <= hp_nxt;
            speed_reg   <= speed_nxt;
            dmg_reg     <= dmg_nxt;
        end
    end

    // 2. BLOK KOMBINACYJNY (Logika ruchu i interakcji)
    always_comb begin
        // Domyślne przypisania (aby uniknąć inferred latches)
        world_x_nxt = world_x_reg;
        world_y_nxt = world_y_reg;
        hp_nxt      = hp_reg;
        speed_nxt   = speed_reg;
        dmg_nxt     = dmg_reg;
        
        // A. Ładowanie klas postaci podczas inicjalizacji/respawnu
        if (load_stats) begin
            case (char_class)
                2'b00: begin hp_nxt = 8'd100; speed_nxt = 4'd4; dmg_nxt = 8'd20; end // Balans
                2'b01: begin hp_nxt = 8'd200; speed_nxt = 4'd2; dmg_nxt = 8'd15; end // Tank
                2'b10: begin hp_nxt = 8'd75;  speed_nxt = 4'd6; dmg_nxt = 8'd15; end // Scout
                2'b11: begin hp_nxt = 8'd50;  speed_nxt = 4'd5; dmg_nxt = 8'd30; end // Glass Cannon
            endcase
            world_x_nxt = MAP_WIDTH_M / 2; 
            world_y_nxt = MAP_HEIGHT_N / 2;
        end
        
        // B. Obliczanie wektora ruchu (PPM wyznacza kierunek względem środka ekranu)
        else if (hp_reg > 0 && mouse_rmb) begin
            
            // Logika dla osi X z blokadą wyjścia poza obszar M
            if (mouse_x < CENTER_X_L) begin
                if (world_x_reg > speed_reg)
                    world_x_nxt = world_x_reg - speed_reg;
            end else if (mouse_x > CENTER_X_R) begin
                if (world_x_reg < MAP_WIDTH_M - PLAYER_SIZE)
                    world_x_nxt = world_x_reg + speed_reg;
            end
            
            // Logika dla osi Y z blokadą wyjścia poza obszar N
            if (mouse_y < CENTER_Y_U) begin
                if (world_y_reg > speed_reg)
                    world_y_nxt = world_y_reg - speed_reg;
            end else if (mouse_y > CENTER_Y_D) begin
                if (world_y_reg < MAP_HEIGHT_N - PLAYER_SIZE)
                    world_y_nxt = world_y_reg + speed_reg;
            end
        end
        
        // C. Logika otrzymywania obrażeń (tylko w trakcie gry)
        if (take_damage && hp_reg > 0 && !load_stats) begin
            // UWAGA: Tu w przyszłości można dodać blokadę otrzymywania 
            // obrażeń co każdy cykl zegara (np. mały timer "invulnerability").
            // Na ten moment zakładamy prosty spadek HP per "hit".
            if (hp_reg >= 8'd10) hp_nxt = hp_reg - 8'd10;
            else                 hp_nxt = 8'd0;
        end
    end
    
    // 3. PRZYPISANIA WYJŚĆ
    assign world_x = world_x_reg;
    assign world_y = world_y_reg;
    assign hp      = hp_reg;
    assign dmg     = dmg_reg;
    assign is_dead = (hp_reg == 8'd0);

endmodule
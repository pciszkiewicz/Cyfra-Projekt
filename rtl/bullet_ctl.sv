`timescale 1 ns / 1 ps

module bullet_ctl #(
    parameter int MAP_WIDTH_M  = 4096,
    parameter int MAP_HEIGHT_N = 4096,
    parameter int SCREEN_W     = 1024,
    parameter int SCREEN_H     = 768
)(
    input  logic        clk,
    input  logic        rst_n,           // Reset asynchroniczny

    // Sygnał zezwalający na ruch (np. impuls z odświeżania klatki 60Hz)
    input  logic        update_tick,     

    // Interfejs z myszką (LPM i koordynaty z ekranu)
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic        mouse_lmb,
    
    // Pozycja gracza (skąd wylatuje pocisk)
    input  logic [15:0] player_world_x,
    input  logic [15:0] player_world_y,

    // Sygnały kolizji z zewnętrznego modułu
    input  logic        hit_wall,
    input  logic        hit_enemy,
    input  logic        phase_combat,    // Pochodzi z game_fsm (czy jesteśmy w ST_COMBAT)

    // Wyjścia (stan pocisku w globalnym świecie)
    output logic [15:0] bullet_world_x,
    output logic [15:0] bullet_world_y,
    output logic        bullet_active
);

    localparam int CENTER_X = SCREEN_W / 2;
    localparam int CENTER_Y = SCREEN_H / 2;

    // --- Rejestry stanu pocisku i ich stany następne ---
    logic [15:0] bullet_x_reg, bullet_x_nxt;
    logic [15:0] bullet_y_reg, bullet_y_nxt;
    logic        active_reg, active_nxt;

    // Zarejestrowany wektor prędkości ze znakiem
    logic signed [7:0] vx_reg, vx_nxt;
    logic signed [7:0] vy_reg, vy_nxt;

    // --- Zmienne pomocnicze (logika kombinacyjna) ---
    logic signed [12:0] dx, dy;
    logic signed [12:0] abs_dx, abs_dy;
    logic [3:0]         shift_val;
    logic signed [7:0]  calc_vx, calc_vy;

    // 1. BLOK SEKWENCYJNY (Zapis do rejestrów z asynchronicznym resetem)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bullet_x_reg <= 16'h0;
            bullet_y_reg <= 16'h0;
            active_reg   <= 1'b0;
            vx_reg       <= 8'h0;
            vy_reg       <= 8'h0;
        end else begin
            bullet_x_reg <= bullet_x_nxt;
            bullet_y_reg <= bullet_y_nxt;
            active_reg   <= active_nxt;
            vx_reg       <= vx_nxt;
            vy_reg       <= vy_nxt;
        end
    end

    // 2. BLOK KOMBINACYJNY (Logika ruchu, strzału i kolizji)
    always_comb begin
        // Domyślne utrzymanie stanu
        bullet_x_nxt = bullet_x_reg;
        bullet_y_nxt = bullet_y_reg;
        active_nxt   = active_reg;
        vx_nxt       = vx_reg;
        vy_nxt       = vy_reg;

        // A. Wyznaczanie kierunku (delta X i delta Y od środka ekranu)
        dx = signed'({1'b0, mouse_x}) - signed'(CENTER_X);
        dy = signed'({1'b0, mouse_y}) - signed'(CENTER_Y);
        
        // Moduł (wartość bezwzględna) do znalezienia wiodącej wartości
        abs_dx = (dx < 0) ? -dx : dx;
        abs_dy = (dy < 0) ? -dy : dy;

        // B. Dynamiczne wyznaczanie dzielnika (przesunięcia bitowego)
        // Działa to jak sprzętowe szacowanie logarytmu przy podstawie 2.
        // Jeśli myszka jest daleko, dzielimy przez większą potęgę dwójki, 
        // aby prędkość maksymalna była mniej więcej stała.
        if (abs_dx > abs_dy) begin
            if      (abs_dx > 512) shift_val = 4'd6; // / 64
            else if (abs_dx > 256) shift_val = 4'd5; // / 32
            else if (abs_dx > 128) shift_val = 4'd4; // / 16
            else if (abs_dx > 64)  shift_val = 4'd3; // / 8
            else                   shift_val = 4'd2; // / 4
        end else begin
            if      (abs_dy > 512) shift_val = 4'd6;
            else if (abs_dy > 256) shift_val = 4'd5;
            else if (abs_dy > 128) shift_val = 4'd4;
            else if (abs_dy > 64)  shift_val = 4'd3;
            else                   shift_val = 4'd2;
        end

        // Aplikacja arytmetycznego przesunięcia bitowego w prawo (zachowuje znak)
        calc_vx = signed'(dx >>> shift_val);
        calc_vy = signed'(dy >>> shift_val);

        // C. Maszyna zachowań pocisku
        if (!active_reg) begin
            // Tworzenie pocisku, gdy LPM kliknięty w trakcie fazy walki
            if (mouse_lmb && phase_combat) begin
                active_nxt   = 1'b1;
                bullet_x_nxt = player_world_x;
                bullet_y_nxt = player_world_y;
                
                // Zabezpieczenie przed strzałem w punkt (0,0), dajemy domyślny wektor (np. w prawo)
                if (calc_vx == 0 && calc_vy == 0) begin
                    vx_nxt = 8'd10; 
                    vy_nxt = 8'd0;
                end else begin
                    vx_nxt = calc_vx;
                    vy_nxt = calc_vy;
                end
            end
        end else begin
            // Aktualizacja pozycji tylko podczas taktu odświeżania (update_tick)
            if (update_tick) begin
                bullet_x_nxt = unsigned'(signed'({1'b0, bullet_x_reg}) + vx_reg);
                bullet_y_nxt = unsigned'(signed'({1'b0, bullet_y_reg}) + vy_reg);
            end

            // Niszczenie pocisku: kolizja ze ścianą, wrogiem lub wylot poza całkowitą mapę MxN
            if (hit_wall || hit_enemy || 
                bullet_x_reg > MAP_WIDTH_M || bullet_y_reg > MAP_HEIGHT_N) begin
                active_nxt = 1'b0;
            end
        end
    end

    // 3. PRZYPISANIE WYJŚĆ
    assign bullet_world_x = bullet_x_reg;
    assign bullet_world_y = bullet_y_reg;
    assign bullet_active  = active_reg;

endmodule
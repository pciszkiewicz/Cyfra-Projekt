`timescale 1 ns / 1 ps

module cam_translation #(
    parameter int SCREEN_W = 1024,
    parameter int SCREEN_H = 768
)(
    input  logic        clk,
    input  logic        rst_n,              // Reset asynchroniczny
    
    // Pozycja gracza (środek kamery) w świecie globalnym
    input  logic [15:0] player_world_x,
    input  logic [15:0] player_world_y,
    
    // Pozycja dowolnego obiektu w świecie globalnym
    input  logic [15:0] obj_world_x,
    input  logic [15:0] obj_world_y,
    
    // Przeliczone współrzędne obiektu na ekranie monitora
    output logic [11:0] obj_screen_x,
    output logic [11:0] obj_screen_y,
    output logic        visible             // Sygnał informujący czy obiekt widać na ekranie
);

    // Wyznaczenie punktu środkowego ekranu na podstawie parametrów
    localparam int CENTER_X = SCREEN_W / 2;
    localparam int CENTER_Y = SCREEN_H / 2;

    // Rejestry stanu obecnego i następnego
    logic [11:0] screen_x_reg, screen_x_nxt;
    logic [11:0] screen_y_reg, screen_y_nxt;
    logic        visible_reg,  visible_nxt;

    // Zmienne pomocnicze ze znakiem (signed) do obliczeń relatywnych przesunięć.
    // Są niezbędne, ponieważ obiekty mogą znajdować się poza ekranem (wartości ujemne).
    logic signed [17:0] rel_x;
    logic signed [17:0] rel_y;

    // 1. BLOK SEKWENCYJNY (Zapis do rejestrów z asynchronicznym resetem)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            screen_x_reg <= 12'h0;
            screen_y_reg <= 12'h0;
            visible_reg  <= 1'b0;
        end else begin
            screen_x_reg <= screen_x_nxt;
            screen_y_reg <= screen_y_nxt;
            visible_reg  <= visible_nxt;
        end
    end

    // 2. BLOK KOMBINACYJNY (Logika przeliczania współrzędnych)
    always_comb begin
        // Rzutowanie na typ signed zapobiega problemom przy odejmowaniu bezznaku
        rel_x = signed'({2'b0, obj_world_x}) - signed'({2'b0, player_world_x}) + signed'(CENTER_X);
        rel_y = signed'({2'b0, obj_world_y}) - signed'({2'b0, player_world_y}) + signed'(CENTER_Y);

        // Przypisanie wyliczonej wartości do stanu następnego
        screen_x_nxt = unsigned'(rel_x[11:0]);
        screen_y_nxt = unsigned'(rel_y[11:0]);

        // Detekcja widoczności - czy obiekt mieści się w kadrze monitora 1024x768
        if (rel_x >= 0 && rel_x < SCREEN_W && rel_y >= 0 && rel_y < SCREEN_H) begin
            visible_nxt = 1'b1;
        end else begin
            visible_nxt = 1'b0;
        end
    end

    // 3. PRZYPISANIE WYJŚĆ
    assign obj_screen_x = screen_x_reg;
    assign obj_screen_y = screen_y_reg;
    assign visible      = visible_reg;

endmodule
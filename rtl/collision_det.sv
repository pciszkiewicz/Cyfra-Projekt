`timescale 1 ns / 1 ps

module collision_det #(
    parameter int PLAYER_SIZE = 32,
    parameter int BULLET_SIZE = 4
)(
    input  logic        clk,
    input  logic        rst_n,             // Reset asynchroniczny

    // Pozycja i status naszego pocisku
    input  logic [15:0] my_bullet_x,
    input  logic [15:0] my_bullet_y,
    input  logic        my_bullet_active,

    // Pozycja przeciwnika (odbierana z drugiego FPGA przez UART)
    input  logic [15:0] enemy_x,
    input  logic [15:0] enemy_y,

    // Interfejs do pamięci mapy (Port B w Dual-Port BRAM)
    // Port A jest używany przez moduł rysujący VGA!
    output logic [13:0] map_addr,          // Adres kafelka mapy (dla siatki 128x128)
    input  logic        map_data,          // Zwrócona wartość z pamięci: 1 = ściana, 0 = pusto

    // Wyjścia (flagi kolizji)
    output logic        hit_enemy,
    output logic        hit_wall
);

    // Rejestry stanu wyjściowego
    logic hit_enemy_reg, hit_enemy_nxt;
    logic hit_wall_reg,  hit_wall_nxt;

    // 1. BLOK SEKWENCYJNY (Zatrzaskiwanie wyników z resetem asynchronicznym)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hit_enemy_reg <= 1'b0;
            hit_wall_reg  <= 1'b0;
        end else begin
            hit_enemy_reg <= hit_enemy_nxt;
            hit_wall_reg  <= hit_wall_nxt;
        end
    end

    // =========================================================================
    // 2. BLOK KOMBINACYJNY (Logika obliczania kolizji)
    // =========================================================================
    always_comb begin
        // Domyślne wartości (czyszczenie flag, jeśli kolizja ustała/pocisk zniknął)
        hit_enemy_nxt = 1'b0;
        hit_wall_nxt  = 1'b0;

        if (my_bullet_active) begin
            // A. Kolizja AABB (Pocisk vs Przeciwnik)
            // Sprawdzamy, czy prostokąt pocisku nakłada się na prostokąt wroga.
            if ((my_bullet_x + BULLET_SIZE >= enemy_x) && 
                (my_bullet_x <= enemy_x + PLAYER_SIZE) &&
                (my_bullet_y + BULLET_SIZE >= enemy_y) && 
                (my_bullet_y <= enemy_y + PLAYER_SIZE)) begin
                
                hit_enemy_nxt = 1'b1;
            end

            // B. Kolizja ze ścianą (na podstawie danych z pamięci)
            // Jeśli pod adresem, w którym znajduje się pocisk, jest jedynka.
            if (map_data == 1'b1) begin
                hit_wall_nxt = 1'b1;
            end
        end
    end

    // =========================================================================
    // 3. SPRZĘTOWE ADRESOWANIE PAMIĘCI (Bit Slicing)
    // =========================================================================
    // Zakładamy mapę 4096x4096px oraz kafelki (ściany) o rozmiarze 32x32px.
    // Daje to siatkę 128 x 128 kafelków. 
    // Indeks X kafelka to: my_bullet_x / 32. 
    // Indeks Y kafelka to: my_bullet_y / 32.
    // Dzielenie przez 32 to ucięcie 5 najmłodszych bitów (od [4:0]). Bierzemy bity [11:5].
    //
    // Adres 1D w pamięci to: (Y_index * 128) + X_index.
    // Mnożenie przez 128 to przesunięcie w lewo o 7 bitów.
    // Zamiast mnożyć i dodawać, w sprzęcie robimy zwykłą konkatenację (złączenie) bitów:
    // {Y_index (7 bitów), X_index (7 bitów)} = 14 bitów adresu!
    
    assign map_addr = {my_bullet_y[11:5], my_bullet_x[11:5]};

    // 4. PRZYPISANIE WYJŚĆ
    assign hit_enemy = hit_enemy_reg;
    assign hit_wall  = hit_wall_reg;

endmodule
`timescale 1 ns / 1 ps

/**
 * MTM UEC2
 * Description: 
 * Moduł rysujący obiekty dynamiczne (przeciwnika i pociski) na podstawie
 * ich globalnych współrzędnych przetłumaczonych na ekran kamery.
 */
module draw_entities #(
    parameter int PLAYER_SIZE = 32,
    parameter int BULLET_SIZE = 4
)(
    input  logic        clk,
    input  logic        rst_n,

    // Interfejsy VGA
    vga_if.in           in,
    vga_if.out          out,

    // Pozycja naszej kamery (środek ekranu)
    input  logic [15:0] cam_world_x,
    input  logic [15:0] cam_world_y,

    // Dane przeciwnika
    input  logic [15:0] enemy_world_x,
    input  logic [15:0] enemy_world_y,
    input  logic [7:0]  enemy_hp,

    // Dane naszego pocisku
    input  logic [15:0] bullet_world_x,
    input  logic [15:0] bullet_world_y,
    input  logic        bullet_active
);

    // =========================================================================
    // 1. TRANSLACJA WSPÓŁRZĘDNYCH (Instancje modułu kamery)
    // =========================================================================
    logic [11:0] enemy_screen_x, enemy_screen_y;
    logic        enemy_visible;

    cam_translation u_cam_enemy (
        .clk(clk),
        .rst_n(rst_n),
        .player_world_x(cam_world_x),
        .player_world_y(cam_world_y),
        .obj_world_x(enemy_world_x),
        .obj_world_y(enemy_world_y),
        .obj_screen_x(enemy_screen_x),
        .obj_screen_y(enemy_screen_y),
        .visible(enemy_visible)
    );

    logic [11:0] bullet_screen_x, bullet_screen_y;
    logic        bullet_visible;

    cam_translation u_cam_bullet (
        .clk(clk),
        .rst_n(rst_n),
        .player_world_x(cam_world_x),
        .player_world_y(cam_world_y),
        .obj_world_x(bullet_world_x),
        .obj_world_y(bullet_world_y),
        .obj_screen_x(bullet_screen_x),
        .obj_screen_y(bullet_screen_y),
        .visible(bullet_visible)
    );

    // =========================================================================
    // 2. BLOK SEKWENCYJNY (Synchronizacja sygnałów VGA z resetem asynchronicznym)
    // =========================================================================
    logic [11:0] rgb_nxt;

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
    // 3. BLOK KOMBINACYJNY (Nakładanie pikseli obiektów na obraz)
    // =========================================================================
    always_comb begin
        // Domyślnie przepuszczamy to, co narysowały wcześniejsze moduły (np. mapa)
        rgb_nxt = in.rgb;

        if (!in.vblnk && !in.hblnk) begin
            
            // A. Rysowanie przeciwnika (Tylko jeśli żyje i mieści się w kamerze)
            if (enemy_hp > 0 && enemy_visible) begin
                if (in.hcount >= enemy_screen_x && in.hcount < (enemy_screen_x + PLAYER_SIZE) &&
                    in.vcount >= enemy_screen_y && in.vcount < (enemy_screen_y + PLAYER_SIZE)) begin
                    
                    rgb_nxt = 12'hF00; // Czerwony kwadrat
                end
            end

            // B. Rysowanie pocisku (Tylko jeśli aktywny i widoczny)
            // Zauważ, że pocisk sprawdzamy PO przeciwniku - dzięki temu pocisk będzie
            // rysowany "na wierzchu", przelatując nad graczem, a nie pod nim.
            if (bullet_active && bullet_visible) begin
                if (in.hcount >= bullet_screen_x && in.hcount < (bullet_screen_x + BULLET_SIZE) &&
                    in.vcount >= bullet_screen_y && in.vcount < (bullet_screen_y + BULLET_SIZE)) begin
                    
                    rgb_nxt = 12'hFF0; // Żółty pocisk
                end
            end
            
        end
    end

endmodule
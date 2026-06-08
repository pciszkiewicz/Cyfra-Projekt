`timescale 1 ns / 1 ps

/**
 * MTM UEC2
 * Description: 
 * Moduł rysujący obiekty dynamiczne (przeciwnika i pociski) na podstawie
 * ich globalnych współrzędnych przetłumaczonych na ekran kamery.
 */

 `timescale 1 ns / 1 ps

 module draw_entities #(
    parameter int PLAYER_SIZE = 32,
    parameter int BULLET_SIZE = 4,
    parameter int SCREEN_W    = 1024,
    parameter int SCREEN_H    = 768
)(
    input  logic        clk,
    input  logic        rst_n,

    vga_if.in           in,
    vga_if.out          out,

    input  logic [15:0] cam_world_x,
    input  logic [15:0] cam_world_y,

    input  logic [15:0] enemy_world_x,
    input  logic [15:0] enemy_world_y,
    input  logic [7:0]  enemy_hp,

    input  logic [15:0] bullet_world_x,
    input  logic [15:0] bullet_world_y,
    input  logic        bullet_active,
    
    // DODANE: Pocisk wroga
    input  logic [15:0] enemy_bullet_x,
    input  logic [15:0] enemy_bullet_y,
    input  logic        enemy_bullet_active
);

    // Stała pozycja lokalnego gracza na ekranie (zawsze na środku)
    localparam int P1_SCREEN_X = (SCREEN_W / 2) - (PLAYER_SIZE / 2);
    localparam int P1_SCREEN_Y = (SCREEN_H / 2) - (PLAYER_SIZE / 2);

    // =========================================================================
    // 1. TRANSLACJA WSPÓŁRZĘDNYCH
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

    // Translacja pocisku wroga
    logic [11:0] enemy_bullet_screen_x, enemy_bullet_screen_y;
    logic        enemy_bullet_visible;

    cam_translation u_cam_enemy_bullet (
        .clk(clk),
        .rst_n(rst_n),
        .player_world_x(cam_world_x),
        .player_world_y(cam_world_y),
        .obj_world_x(enemy_bullet_x),
        .obj_world_y(enemy_bullet_y),
        .obj_screen_x(enemy_bullet_screen_x),
        .obj_screen_y(enemy_bullet_screen_y),
        .visible(enemy_bullet_visible)
    );

    // =========================================================================
    // 2. BLOK SEKWENCYJNY (Pipeline)
    // =========================================================================
    logic [11:0] rgb_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.vcount <= '0; out.hcount <= '0;
            out.vsync  <= '0; out.hsync  <= '0;
            out.vblnk  <= '0; out.hblnk  <= '0;
            out.rgb    <= 12'h000;
        end else begin
            out.vcount <= in.vcount; out.hcount <= in.hcount;
            out.vsync  <= in.vsync;  out.hsync  <= in.hsync;
            out.vblnk  <= in.vblnk;  out.hblnk  <= in.hblnk;
            out.rgb    <= rgb_nxt;
        end
    end

    // =========================================================================
    // 3. BLOK KOMBINACYJNY (Nakładanie pikseli)
    // =========================================================================
    always_comb begin
        rgb_nxt = in.rgb;

        if (!in.vblnk && !in.hblnk) begin
            
            // A. Rysowanie LOKALNEGO GRACZA (zawsze na środku ekranu)
            if (in.hcount >= P1_SCREEN_X && in.hcount < (P1_SCREEN_X + PLAYER_SIZE) &&
                in.vcount >= P1_SCREEN_Y && in.vcount < (P1_SCREEN_Y + PLAYER_SIZE)) begin
                
                // Prosta obwódka dla gracza
                if (in.hcount < P1_SCREEN_X + 2 || in.hcount >= P1_SCREEN_X + PLAYER_SIZE - 2 ||
                    in.vcount < P1_SCREEN_Y + 2 || in.vcount >= P1_SCREEN_Y + PLAYER_SIZE - 2)
                    rgb_nxt = 12'hFFF; // Biała obwódka
                else
                    rgb_nxt = 12'h0F0; // Zielony rdzeń (My)
            end

            // B. Rysowanie PRZECIWNIKA (nadpisuje gracza w razie bliskiego kontaktu)
            else if (enemy_hp > 0 && enemy_visible) begin
                if (in.hcount >= enemy_screen_x && in.hcount < (enemy_screen_x + PLAYER_SIZE) &&
                    in.vcount >= enemy_screen_y && in.vcount < (enemy_screen_y + PLAYER_SIZE)) begin
                    
                    if (in.hcount < enemy_screen_x + 2 || in.hcount >= enemy_screen_x + PLAYER_SIZE - 2 ||
                        in.vcount < enemy_screen_y + 2 || in.vcount >= enemy_screen_y + PLAYER_SIZE - 2)
                        rgb_nxt = 12'hFFF; // Biała obwódka
                    else
                        rgb_nxt = 12'hF00; // Czerwony rdzeń (Wróg)
                end
            end

            // Rysowanie WŁASNEGO POCISKU
            if (bullet_active && bullet_visible) begin
                if (in.hcount >= bullet_screen_x && in.hcount < (bullet_screen_x + BULLET_SIZE) &&
                    in.vcount >= bullet_screen_y && in.vcount < (bullet_screen_y + BULLET_SIZE)) begin
                    rgb_nxt = 12'hFF0; // Żółty pocisk
                end
            end
            
            // Rysowanie POCISKU WROGA
            if (enemy_bullet_active && enemy_bullet_visible) begin
                if (in.hcount >= enemy_bullet_screen_x && in.hcount < (enemy_bullet_screen_x + BULLET_SIZE) &&
                    in.vcount >= enemy_bullet_screen_y && in.vcount < (enemy_bullet_screen_y + BULLET_SIZE)) begin
                    rgb_nxt = 12'hF80; // Pomarańczowy pocisk wroga
                end
            end
        end
    end
endmodule
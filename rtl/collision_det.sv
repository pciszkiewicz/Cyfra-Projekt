`timescale 1 ns / 1 ps

module collision_det #(
    parameter int PLAYER_SIZE = 32,
    parameter int BULLET_SIZE = 4
)(
    input  logic        clk,
    input  logic        rst_n,             

    input  logic [15:0] my_bullet_x,
    input  logic [15:0] my_bullet_y,
    input  logic        my_bullet_active,

    input  logic [15:0] enemy_x,
    input  logic [15:0] enemy_y,

    output logic [13:0] map_addr,          
    input  logic        map_data,     

    output logic        hit_enemy,
    output logic        hit_wall
);

    // --- STAGE 1: Adresowanie pamięci mapy (Kombinacyjne) ---
    assign map_addr = {my_bullet_y[11:5], my_bullet_x[11:5]};

    // --- PIPELINE: Rejestry opóźniające pocisk o 1 takt (czekanie na BRAM) ---
    logic        active_d1;
    logic [15:0] bx_d1, by_d1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active_d1 <= 1'b0;
            bx_d1     <= 16'h0;
            by_d1     <= 16'h0;
        end else begin
            active_d1 <= my_bullet_active;
            bx_d1     <= my_bullet_x;
            by_d1     <= my_bullet_y;
        end
    end

    // --- STAGE 2: Logika Kolizji ---
    logic hit_enemy_reg, hit_enemy_nxt;
    logic hit_wall_reg,  hit_wall_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hit_enemy_reg <= 1'b0;
            hit_wall_reg  <= 1'b0;
        end else begin
            hit_enemy_reg <= hit_enemy_nxt;
            hit_wall_reg  <= hit_wall_nxt;
        end
    end

    always_comb begin
        hit_enemy_nxt = 1'b0;
        hit_wall_nxt  = 1'b0;

        // Sprawdzamy kolizję używając OPÓŹNIONYCH koordynatów, bo map_data dopiero dotarło!
        if (active_d1) begin
            
            // A. Kolizja AABB (Pocisk vs Przeciwnik)
            if ((bx_d1 + BULLET_SIZE >= enemy_x) && 
                (bx_d1 <= enemy_x + PLAYER_SIZE) &&
                (by_d1 + BULLET_SIZE >= enemy_y) && 
                (by_d1 <= enemy_y + PLAYER_SIZE)) begin
                hit_enemy_nxt = 1'b1;
            end

            // B. Kolizja ze ścianą
            if (map_data == 1'b1) begin
                hit_wall_nxt = 1'b1;
            end
        end
    end

    assign hit_enemy = hit_enemy_reg;
    assign hit_wall  = hit_wall_reg;

endmodule
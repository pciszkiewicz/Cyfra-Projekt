`timescale 1 ns / 1 ps

module collision_det #(
    parameter int PLAYER_SIZE = 32,
    parameter int BULLET_SIZE = 4
) (
    input logic clk,
    input logic rst_n,
    output logic [11:0] map_addr,
    output logic hit_enemy,
    output logic hit_wall,
    input logic [15:0] my_bullet_x,
    input logic [15:0] my_bullet_y,
    input logic my_bullet_active,
    input logic [15:0] enemy_x,
    input logic [15:0] enemy_y,
    input logic map_data
);

/* Local variables and signals */
logic active_d1;
logic [15:0] bx_d1, by_d1;
logic hit_enemy_reg, hit_enemy_nxt;
logic hit_wall_reg, hit_wall_nxt;

/* Signals assignments */
assign map_addr = {my_bullet_y[10:5], my_bullet_x[10:5]};
assign hit_enemy = hit_enemy_reg;
assign hit_wall = hit_wall_reg;

/* Module internal logic */
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        active_d1 <= 1'b0;
        bx_d1 <= 16'h0;
        by_d1 <= 16'h0;
        hit_enemy_reg <= 1'b0;
        hit_wall_reg <= 1'b0;
    end else begin
        active_d1 <= my_bullet_active;
        bx_d1 <= my_bullet_x;
        by_d1 <= my_bullet_y;
        hit_enemy_reg <= hit_enemy_nxt;
        hit_wall_reg <= hit_wall_nxt;
    end
end

always_comb begin
    hit_enemy_nxt = 1'b0;
    hit_wall_nxt = 1'b0;

    /* Sprawdzamy kolizję uzywajac opoznionych koordynatow, bo map_data dopiero dotarlo */
    if (active_d1) begin
        if ((bx_d1 + 16'(BULLET_SIZE) >= enemy_x) &&
            (bx_d1 <= enemy_x + 16'(PLAYER_SIZE)) &&
            (by_d1 + 16'(BULLET_SIZE) >= enemy_y) &&
            (by_d1 <= enemy_y + 16'(PLAYER_SIZE))) begin
            hit_enemy_nxt = 1'b1;
        end

        if (map_data == 1'b1) begin
            hit_wall_nxt = 1'b1;
        end
    end
end

endmodule
`timescale 1 ns / 1 ps

module bullet_ctl #(
    parameter int MAP_WIDTH_M = 4096,
    parameter int MAP_HEIGHT_N = 4096,
    parameter int SCREEN_W = 1024,
    parameter int SCREEN_H = 768,
    parameter int PLAYER_SIZE = 32
) (
    input logic clk,
    input logic rst_n,
    output logic [15:0] bullet_world_x,
    output logic [15:0] bullet_world_y,
    output logic bullet_active,
    output logic [7:0] bullet_dmg,
    input logic update_tick,
    input logic [11:0] mouse_x,
    input logic [11:0] mouse_y,
    input logic mouse_lmb,
    input logic [15:0] player_world_x,
    input logic [15:0] player_world_y,
    input logic [7:0] player_dmg,
    input logic hit_wall,
    input logic hit_enemy,
    input logic phase_combat
);

localparam int CENTER_X = SCREEN_W / 2;
localparam int CENTER_Y = SCREEN_H / 2;

logic [15:0] bullet_x_reg, bullet_x_nxt;
logic [15:0] bullet_y_reg, bullet_y_nxt;
logic active_reg, active_nxt;

logic [7:0] bullet_dmg_reg, bullet_dmg_nxt;
logic [5:0] cooldown_reg, cooldown_nxt;

logic signed [7:0] vx_reg, vx_nxt;
logic signed [7:0] vy_reg, vy_nxt;

logic signed [12:0] dx, dy;
logic signed [12:0] abs_dx, abs_dy;
logic [3:0] shift_val;
logic signed [7:0] calc_vx, calc_vy;

assign bullet_world_x = bullet_x_reg;
assign bullet_world_y = bullet_y_reg;
assign bullet_active = active_reg;
assign bullet_dmg = bullet_dmg_reg;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bullet_x_reg <= 16'h0;
        bullet_y_reg <= 16'h0;
        active_reg <= 1'b0;
        vx_reg <= 8'sd0;
        vy_reg <= 8'sd0;
        bullet_dmg_reg <= 8'h0;
        cooldown_reg <= 6'h0;
    end else begin
        bullet_x_reg <= bullet_x_nxt;
        bullet_y_reg <= bullet_y_nxt;
        active_reg <= active_nxt;
        vx_reg <= vx_nxt;
        vy_reg <= vy_nxt;
        bullet_dmg_reg <= bullet_dmg_nxt;
        cooldown_reg <= cooldown_nxt;
    end
end

always_comb begin
    bullet_x_nxt = bullet_x_reg;
    bullet_y_nxt = bullet_y_reg;
    active_nxt = active_reg;
    vx_nxt = vx_reg;
    vy_nxt = vy_reg;
    bullet_dmg_nxt = bullet_dmg_reg;

    if (cooldown_reg > 6'd0 && update_tick) begin
        cooldown_nxt = cooldown_reg - 6'd1;
    end else begin
        cooldown_nxt = cooldown_reg;
    end

    dx = signed'({1'b0, mouse_x}) - signed'(CENTER_X);
    dy = signed'({1'b0, mouse_y}) - signed'(CENTER_Y);

    if (dx < 13'sd0) begin
        abs_dx = -dx;
    end else begin
        abs_dx = dx;
    end

    if (dy < 13'sd0) begin
        abs_dy = -dy;
    end else begin
        abs_dy = dy;
    end

    if (abs_dx > abs_dy) begin
        if (abs_dx > 13'sd512) begin
            shift_val = 4'd6;
        end else if (abs_dx > 13'sd256) begin
            shift_val = 4'd5;
        end else if (abs_dx > 13'sd128) begin
            shift_val = 4'd4;
        end else if (abs_dx > 13'sd64) begin
            shift_val = 4'd3;
        end else begin
            shift_val = 4'd2;
        end
    end else begin
        if (abs_dy > 13'sd512) begin
            shift_val = 4'd6;
        end else if (abs_dy > 13'sd256) begin
            shift_val = 4'd5;
        end else if (abs_dy > 13'sd128) begin
            shift_val = 4'd4;
        end else if (abs_dy > 13'sd64) begin
            shift_val = 4'd3;
        end else begin
            shift_val = 4'd2;
        end
    end

    calc_vx = signed'(dx >>> shift_val);
    calc_vy = signed'(dy >>> shift_val);

    if (mouse_lmb && phase_combat && cooldown_reg == 6'd0) begin
        active_nxt = 1'b1;
        bullet_dmg_nxt = player_dmg;
        cooldown_nxt = 6'd42;
        bullet_x_nxt = player_world_x + 16'(PLAYER_SIZE / 2);
        bullet_y_nxt = player_world_y + 16'(PLAYER_SIZE / 2);

        if (calc_vx == 8'sd0 && calc_vy == 8'sd0) begin
            vx_nxt = 8'sd10;
            vy_nxt = 8'sd0;
        end else begin
            vx_nxt = calc_vx;
            vy_nxt = calc_vy;
        end
    end else if (active_reg) begin
        if (update_tick) begin
            bullet_x_nxt = unsigned'(signed'({1'b0, bullet_x_reg}) + vx_reg);
            bullet_y_nxt = unsigned'(signed'({1'b0, bullet_y_reg}) + vy_reg);
        end

        if (hit_wall || hit_enemy || bullet_x_reg > 16'(MAP_WIDTH_M) || bullet_y_reg > 16'(MAP_HEIGHT_N)) begin
            active_nxt = 1'b0;
        end
    end
end

endmodule
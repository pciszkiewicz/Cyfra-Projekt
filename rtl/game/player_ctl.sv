`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * Jednostka sterowania i obsługi stanu gracza (Player Controller).
 * Odpowiada za inicjalizację statystyk na bazie wybranej klasy, ruch postaci 
 * względem pozycji myszy (strefa deadzone), aplikowanie bonusów oraz rejestrację obrażeń.
 */

module player_ctl #(
    parameter int MAP_WIDTH_M = 2048,
    parameter int MAP_HEIGHT_N = 2048,
    parameter int SCREEN_W = 1024,
    parameter int SCREEN_H = 768,
    parameter int PLAYER_SIZE = 32
) (
    input logic clk,
    input logic rst_n,
    output logic [15:0] next_x_out,
    output logic [15:0] next_y_out,
    output logic [15:0] world_x,
    output logic [15:0] world_y,
    output logic [7:0] hp,
    output logic [7:0] dmg,
    output logic is_dead,
    input logic is_master,
    input logic [11:0] mouse_x,
    input logic [11:0] mouse_y,
    input logic mouse_rmb,
    input logic [1:0] char_class,
    input logic load_stats,
    input logic update_tick,
    input logic take_dmg_en,
    input logic [7:0] take_dmg_val,
    input logic apply_heal,
    input logic apply_dmg_boost,
    input logic apply_speed_boost,
    input logic is_wall_ahead
);

/* Local parameters */
localparam int CENTER_X = SCREEN_W / 2;
localparam int CENTER_Y = SCREEN_H / 2;
localparam int DEADZONE = 20;

localparam int CENTER_X_L = CENTER_X - DEADZONE;
localparam int CENTER_X_R = CENTER_X + DEADZONE;
localparam int CENTER_Y_U = CENTER_Y - DEADZONE;
localparam int CENTER_Y_D = CENTER_Y + DEADZONE;

/* Local variables and signals */
logic [15:0] world_x_reg, world_x_nxt;
logic [15:0] world_y_reg, world_y_nxt;
logic [7:0] hp_reg, hp_nxt;
logic [7:0] dmg_reg, dmg_nxt;
logic [3:0] speed_reg, speed_nxt;

logic [15:0] req_x_reg, req_x_nxt;
logic [15:0] req_y_reg, req_y_nxt;
logic [2:0] move_pending_reg, move_pending_nxt;

logic [15:0] temp_x, temp_y;

/* Signals assignments */
assign next_x_out = req_x_reg;
assign next_y_out = req_y_reg;
assign world_x = world_x_reg;
assign world_y = world_y_reg;
assign hp = hp_reg;
assign dmg = dmg_reg;
assign is_dead = (hp_reg == 8'd0);

/* Module internal logic */
always_comb begin
    temp_x = world_x_reg;
    temp_y = world_y_reg;
    
    if ((mouse_x < 12'(CENTER_X_L)) && (temp_x > 16'(speed_reg))) begin
        temp_x = temp_x - 16'(speed_reg);
    end else if ((mouse_x > 12'(CENTER_X_R)) && ((temp_x + 16'(speed_reg)) <= 16'(MAP_WIDTH_M - PLAYER_SIZE))) begin
        temp_x = temp_x + 16'(speed_reg);
    end
    
    if ((mouse_y < 12'(CENTER_Y_U)) && (temp_y > 16'(speed_reg))) begin
        temp_y = temp_y - 16'(speed_reg);
    end else if ((mouse_y > 12'(CENTER_Y_D)) && ((temp_y + 16'(speed_reg)) <= 16'(MAP_HEIGHT_N - PLAYER_SIZE))) begin
        temp_y = temp_y + 16'(speed_reg);
    end
end

always_comb begin
    world_x_nxt = world_x_reg;
    world_y_nxt = world_y_reg;
    hp_nxt = hp_reg;
    dmg_nxt = dmg_reg;
    speed_nxt = speed_reg;
    req_x_nxt = req_x_reg;
    req_y_nxt = req_y_reg;
    move_pending_nxt = move_pending_reg;

    if (load_stats) begin
        case (char_class)
            2'b00: begin
                hp_nxt = 8'd100;
                speed_nxt = 4'd4;
                dmg_nxt = 8'd25;
            end 
            2'b01: begin
                hp_nxt = 8'd200;
                speed_nxt = 4'd2;
                dmg_nxt = 8'd15;
            end 
            2'b10: begin
                hp_nxt = 8'd75;
                speed_nxt = 4'd6;
                dmg_nxt = 8'd10;
            end 
            2'b11: begin
                hp_nxt = 8'd50;
                speed_nxt = 4'd3;
                dmg_nxt = 8'd50;
            end
            default: begin
                hp_nxt = 8'd100;
                speed_nxt = 4'd4;
                dmg_nxt = 8'd25;
            end
        endcase

        if (is_master) begin
            world_x_nxt = 16'd128;
            world_y_nxt = 16'd128;
        end else begin
            world_x_nxt = 16'd1888;
            world_y_nxt = 16'd1888;
        end
        
        move_pending_nxt = 3'b000;
    end else begin
        if (take_dmg_en && (hp_reg > 8'd0)) begin
            if (hp_reg >= take_dmg_val) begin
                hp_nxt = hp_reg - take_dmg_val;
            end else begin
                hp_nxt = 8'd0;
            end
        end
        
        if (apply_heal && (hp_reg > 8'd0)) begin
            if (hp_reg < (8'd255 - 8'd25)) begin
                hp_nxt = hp_reg + 8'd25;
            end else begin
                hp_nxt = 8'd255;
            end
        end
        
        if (apply_dmg_boost) begin
            dmg_nxt = dmg_reg + 8'd5;
        end
        
        if (apply_speed_boost && (speed_reg < 4'd8)) begin
            speed_nxt = speed_reg + 4'd1;
        end

        if (update_tick && (hp_reg > 8'd0) && mouse_rmb) begin
            req_x_nxt = temp_x;
            req_y_nxt = temp_y;
            move_pending_nxt[0] = 1'b1;
        end else begin
            move_pending_nxt[0] = 1'b0;
        end
        
        move_pending_nxt[1] = move_pending_reg[0];
        move_pending_nxt[2] = move_pending_reg[1];
        
        if (move_pending_reg[2]) begin
            if (!is_wall_ahead) begin 
                world_x_nxt = req_x_reg;
                world_y_nxt = req_y_reg;
            end
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        world_x_reg <= 16'd0;
        world_y_reg <= 16'd0;
        hp_reg <= 8'd0;
        dmg_reg <= 8'd25;
        speed_reg <= 4'd4;
        req_x_reg <= 16'd0;
        req_y_reg <= 16'd0;
        move_pending_reg <= 3'b000;
    end else begin
        world_x_reg <= world_x_nxt;
        world_y_reg <= world_y_nxt;
        hp_reg <= hp_nxt;
        dmg_reg <= dmg_nxt;
        speed_reg <= speed_nxt;
        req_x_reg <= req_x_nxt;
        req_y_reg <= req_y_nxt;
        move_pending_reg <= move_pending_nxt;
    end
end

endmodule
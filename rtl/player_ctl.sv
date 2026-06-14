`timescale 1 ns / 1 ps

module player_ctl #(
    parameter int MAP_WIDTH_M = 2048,  // Poprawione na wymiary 64x64
    parameter int MAP_HEIGHT_N = 2048, // Poprawione na wymiary 64x64
    parameter int SCREEN_W = 1024,
    parameter int SCREEN_H = 768,
    parameter int PLAYER_SIZE = 32
)(
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic [11:0] mouse_x,        
    input  logic [11:0] mouse_y,        
    input  logic        mouse_rmb,      
    
    input  logic [1:0]  char_class,     
    input  logic        load_stats,     
    input  logic        update_tick,  
    
    input  logic        take_dmg_en,  
    input  logic [7:0]  take_dmg_val, 
    
    input  logic        apply_heal,
    input  logic        apply_dmg_boost,
    input  logic        apply_speed_boost,

    input  logic        is_wall_ahead,
    
    output logic [15:0] next_x_out,
    output logic [15:0] next_y_out,

    output logic [15:0] world_x,
    output logic [15:0] world_y,
    output logic [7:0]  hp,
    output logic [7:0]  dmg,            
    output logic        is_dead
);

    localparam int CENTER_X = SCREEN_W / 2;
    localparam int CENTER_Y = SCREEN_H / 2;
    localparam int DEADZONE = 20;

    localparam int CENTER_X_L = CENTER_X - DEADZONE;
    localparam int CENTER_X_R = CENTER_X + DEADZONE;
    localparam int CENTER_Y_U = CENTER_Y - DEADZONE;
    localparam int CENTER_Y_D = CENTER_Y + DEADZONE;

    logic [15:0] world_x_reg, world_y_reg;
    logic [7:0]  hp_reg, dmg_reg;
    logic [3:0]  speed_reg;

    logic [15:0] req_x, req_y;
    logic [2:0]  move_pending; // Rejestr 3-stopniowy dla BRAM

    logic [15:0] temp_x, temp_y;
    always_comb begin
        temp_x = world_x_reg;
        temp_y = world_y_reg;
        if (mouse_x < CENTER_X_L && temp_x > speed_reg) temp_x = temp_x - speed_reg;
        else if (mouse_x > CENTER_X_R && temp_x < MAP_WIDTH_M - PLAYER_SIZE) temp_x = temp_x + speed_reg;
        
        if (mouse_y < CENTER_Y_U && temp_y > speed_reg) temp_y = temp_y - speed_reg;
        else if (mouse_y > CENTER_Y_D && temp_y < MAP_HEIGHT_N - PLAYER_SIZE) temp_y = temp_y + speed_reg;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            world_x_reg <= MAP_WIDTH_M / 2;
            world_y_reg <= MAP_HEIGHT_N / 2;
            hp_reg      <= 8'd100;
            dmg_reg     <= 8'd25;
            speed_reg   <= 4'd4;
            req_x       <= MAP_WIDTH_M / 2;
            req_y       <= MAP_HEIGHT_N / 2;
            move_pending <= 3'b0;
        end else begin
            if (load_stats) begin
                case (char_class)
                    2'b00: begin hp_reg <= 8'd100; speed_reg <= 4'd4; dmg_reg <= 8'd25; end 
                    2'b01: begin hp_reg <= 8'd200; speed_reg <= 4'd2; dmg_reg <= 8'd15; end 
                    2'b10: begin hp_reg <= 8'd75;  speed_reg <= 4'd6; dmg_reg <= 8'd10; end 
                    2'b11: begin hp_reg <= 8'd50;  speed_reg <= 4'd3; dmg_reg <= 8'd50; end 
                endcase
                world_x_reg <= MAP_WIDTH_M / 2;
                world_y_reg <= MAP_HEIGHT_N / 2;
                move_pending <= 3'b0;
            end else begin
                if (take_dmg_en && hp_reg > 0) begin
                    if (hp_reg >= take_dmg_val) hp_reg <= hp_reg - take_dmg_val;
                    else                        hp_reg <= 8'd0;
                end
                
                if (apply_heal && hp_reg > 0) begin
                    if (hp_reg < 255 - 25) hp_reg <= hp_reg + 25;
                    else                   hp_reg <= 255;
                end
                if (apply_dmg_boost) dmg_reg <= dmg_reg + 5;
                if (apply_speed_boost && speed_reg < 15) speed_reg <= speed_reg + 1;

                if (update_tick && hp_reg > 0 && mouse_rmb) begin
                    req_x <= temp_x;
                    req_y <= temp_y;
                    move_pending[0] <= 1'b1;
                end else begin
                    move_pending[0] <= 1'b0;
                end
                
                move_pending[1] <= move_pending[0];
                move_pending[2] <= move_pending[1]; // Trzeci stopień dający czas BRAMowi na odpowiedź
                
                if (move_pending[2]) begin
                    if (!is_wall_ahead) begin 
                        world_x_reg <= req_x;
                        world_y_reg <= req_y;
                    end
                end
            end
        end
    end

    assign next_x_out = req_x;
    assign next_y_out = req_y;
    assign world_x = world_x_reg;
    assign world_y = world_y_reg;
    assign hp      = hp_reg;
    assign dmg     = dmg_reg;
    assign is_dead = (hp_reg == 8'd0);

endmodule
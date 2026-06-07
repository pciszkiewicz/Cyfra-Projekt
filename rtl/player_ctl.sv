`timescale 1 ns / 1 ps

module player_ctl #(
    parameter int MAP_WIDTH_M = 4096,  
    parameter int MAP_HEIGHT_N = 4096, 
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
    
    input  logic        take_dmg_en,  
    input  logic [7:0]  take_dmg_val, 
    
    output logic [15:0] world_x,
    output logic [15:0] world_y,
    output logic [7:0]  hp,
    output logic [7:0]  dmg,            
    output logic        is_dead
);

    logic [15:0] world_x_reg, world_x_nxt;
    logic [15:0] world_y_reg, world_y_nxt;
    logic [7:0]  hp_reg, hp_nxt;
    logic [7:0]  dmg_reg, dmg_nxt;      
    logic [3:0]  speed_reg, speed_nxt;

    localparam int CENTER_X = SCREEN_W / 2;
    localparam int CENTER_Y = SCREEN_H / 2;
    localparam int DEADZONE = 20; 
    localparam int CENTER_X_L = CENTER_X - DEADZONE;
    localparam int CENTER_X_R = CENTER_X + DEADZONE;
    localparam int CENTER_Y_U = CENTER_Y - DEADZONE;
    localparam int CENTER_Y_D = CENTER_Y + DEADZONE;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            world_x_reg <= MAP_WIDTH_M / 2;
            world_y_reg <= MAP_HEIGHT_N / 2;
            hp_reg      <= 8'd100;
            dmg_reg     <= 8'd25;           
            speed_reg   <= 4'd4;
        end else begin
            world_x_reg <= world_x_nxt;
            world_y_reg <= world_y_nxt;
            hp_reg      <= hp_nxt;
            dmg_reg     <= dmg_nxt;         
            speed_reg   <= speed_nxt;
        end
    end

    always_comb begin
        world_x_nxt = world_x_reg;
        world_y_nxt = world_y_reg;
        hp_nxt      = hp_reg;
        dmg_nxt     = dmg_reg;              
        speed_nxt   = speed_reg;

        if (load_stats) begin
            case (char_class)
                2'b00: begin hp_nxt = 8'd100; speed_nxt = 4'd4; dmg_nxt = 8'd25; end 
                2'b01: begin hp_nxt = 8'd200; speed_nxt = 4'd2; dmg_nxt = 8'd15; end 
                2'b10: begin hp_nxt = 8'd75;  speed_nxt = 4'd6; dmg_nxt = 8'd10; end 
                2'b11: begin hp_nxt = 8'd50;  speed_nxt = 4'd3; dmg_nxt = 8'd50; end 
            endcase
            world_x_nxt = MAP_WIDTH_M / 2;
            world_y_nxt = MAP_HEIGHT_N / 2;
        end
        else if (hp_reg > 0 && mouse_rmb) begin
            if (mouse_x < CENTER_X_L) begin
                if (world_x_reg > speed_reg) world_x_nxt = world_x_reg - speed_reg;
            end else if (mouse_x > CENTER_X_R) begin
                if (world_x_reg < MAP_WIDTH_M - PLAYER_SIZE) world_x_nxt = world_x_reg + speed_reg;
            end
            
            if (mouse_y < CENTER_Y_U) begin
                if (world_y_reg > speed_reg) world_y_nxt = world_y_reg - speed_reg;
            end else if (mouse_y > CENTER_Y_D) begin
                if (world_y_reg < MAP_HEIGHT_N - PLAYER_SIZE) world_y_nxt = world_y_reg + speed_reg;
            end
        end
        
        if (take_dmg_en && hp_reg > 0 && !load_stats) begin
            if (hp_reg >= take_dmg_val) hp_nxt = hp_reg - take_dmg_val;
            else                           hp_nxt = 8'd0;
        end
    end
    
    assign world_x = world_x_reg;
    assign world_y = world_y_reg;
    assign hp      = hp_reg;
    assign dmg     = dmg_reg;               
    assign is_dead = (hp_reg == 8'd0);

endmodule
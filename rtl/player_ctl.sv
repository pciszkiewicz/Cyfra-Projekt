/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * Player control module handling movement and collision detection.
 */

module player_ctl (
    input  logic        clk,
    input  logic        rst_n,
    output logic [9:0]  map_addr,
    output logic [11:0] player_x,
    output logic [11:0] player_y,
    output logic [11:0] cam_x,
    output logic [11:0] cam_y,
    input  logic [10:0] vcount,
    input  logic [10:0] hcount,
    input  logic [9:0]  mouse_x,
    input  logic [9:0]  mouse_y,
    input  logic        mouse_rmb,
    input  logic        is_wall
);

localparam logic [11:0] CENTER_X = 10'd512;
localparam logic [11:0] CENTER_Y = 10'd384;
localparam logic [11:0] MAP_LIMIT_X = 12'd1536;
localparam logic [11:0] MAP_LIMIT_Y = 12'd1664;
localparam logic [11:0] MAX_CAM_X   = 12'd1024;
localparam logic [11:0] MAX_CAM_Y   = 12'd1280;

logic [11:0] speed;
logic [11:0] px_reg, px_nxt, py_reg, py_nxt;
logic [11:0] target_x_reg, target_x_nxt;
logic [11:0] target_y_reg, target_y_nxt;
logic        frame_tick;

assign frame_tick = (vcount == 11'd0 && hcount == 11'd0);

always_comb begin
    case(class_id)
        2'd0: speed = 12'd2;
        2'd1: speed = 12'd4;
        2'd2: speed = 12'd6;
        2'd3: speed = 12'd3;
        default: speed = 12'd4;
    endcase
end

always_comb begin
    cam_x = (px_reg < CENTER_X) ? 12'd0 : ((px_reg > MAP_LIMIT_X) ? MAX_CAM_X : (px_reg - CENTER_X));
    cam_y = (px_reg < CENTER_Y) ? 12'd0 : ((px_reg > MAP_LIMIT_Y) ? MAX_CAM_Y : (px_reg - CENTER_Y));
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        px_reg <= 12'd160;
        py_reg <= 12'd992;
        target_x_reg <= 12'd160;
        target_y_reg <= 12'd992;
    end else begin
        px_reg <= px_nxt;
        py_reg <= py_nxt;
        target_x_reg <= target_x_nxt;
        target_y_reg <= target_y_nxt;
    end
end

always_comb begin
    px_nxt = px_reg;
    py_nxt = py_reg;
    target_x_nxt = target_x_reg;
    target_y_nxt = target_y_reg;
    
    // map_addr wystawiony teraz, is_wall przyjdzie w następnym takcie
    map_addr = {py_reg[10:6], px_reg[10:6]}; 

    if (mouse_rmb) begin
            target_x_nxt = {2'b00, mouse_x} + cam_x;
            target_y_nxt = {2'b00, mouse_y} + cam_y;
        end

        if (frame_tick && !is_wall) begin
            if (target_x_reg > px_reg + speed)      px_nxt = px_reg + speed;
            else if (target_x_reg < px_reg - speed) px_nxt = px_reg - speed;
            else                                    px_nxt = target_x_reg;

            if (target_y_reg > py_reg + speed)      py_nxt = py_reg + speed;
            else if (target_y_reg < py_reg - speed) py_nxt = py_reg - speed;
            else                                    py_nxt = target_y_reg;
        end else if (is_wall) begin
            target_x_nxt = px_reg;
            target_y_nxt = py_reg;
        end
    end

assign map_addr = {py_reg[10:6], px_reg[10:6]};
assign player_x = px_reg;
assign player_y = py_reg;

endmodule
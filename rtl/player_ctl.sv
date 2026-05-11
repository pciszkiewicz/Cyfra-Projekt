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
    input  logic [10:0] vcount,
    input  logic [10:0] hcount,
    input  logic [9:0]  mouse_x,
    input  logic [9:0]  mouse_y,
    input  logic        mouse_rmb,
    input  logic        is_wall
);

localparam logic [11:0] SPEED    = 12'd4;
localparam logic [9:0]  CENTER_X = 10'd512;
localparam logic [9:0]  CENTER_Y = 10'd384;

logic [11:0] px_reg, px_nxt, py_reg, py_nxt;
logic        frame_tick;

assign frame_tick = (vcount == 11'd0 && hcount == 11'd0);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        px_reg <= 12'd160;
        py_reg <= 12'd992;
    end else begin
        px_reg <= px_nxt;
        py_reg <= py_nxt;
    end
end

always_comb begin
    px_nxt = px_reg;
    py_nxt = py_reg;
    
    // map_addr wystawiony teraz, is_wall przyjdzie w następnym takcie
    map_addr = {py_reg[10:6], px_reg[10:6]}; 

    if (frame_tick && mouse_rmb && !is_wall) begin
        if (mouse_x > CENTER_X + 10'd20)      px_nxt = px_reg + SPEED;
        else if (mouse_x < CENTER_X - 10'd20) px_nxt = px_reg - SPEED;

        if (mouse_y > CENTER_Y + 10'd20)      py_nxt = py_reg + SPEED;
        else if (mouse_y < CENTER_Y - 10'd20) py_nxt = py_reg - SPEED;
    end
end

assign player_x = px_reg;
assign player_y = py_reg;

endmodule
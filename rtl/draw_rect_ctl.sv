`timescale 1ns / 1ps

module draw_rect_ctl (
    input  logic clk,
    input  logic rst_n,
    input  logic mouse_right,     
    input  logic [11:0] mouse_xpos,
    input  logic [11:0] mouse_ypos,
    input  logic vsync,
    output logic [11:0] xpos,
    output logic [11:0] ypos
);

    // Rejestry pozycji gracza i celu
    logic [11:0] player_x, player_y;
    logic [11:0] target_x, target_y;
    
    // Rejestry do wykrywania zboczy
    logic right_click_prev;
    logic vsync_prev;

    // Prędkość postaci 
    logic [3:0] player_speed; 
    assign player_speed = 4'd3; // 3 piksele na klatkę

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            player_x <= 12'd400; // Środek ekranu 800x600
            player_y <= 12'd300;
            target_x <= 12'd400;
            target_y <= 12'd300;
            right_click_prev <= 1'b0;
            vsync_prev <= 1'b0;
        end else begin
            right_click_prev <= mouse_right;
            vsync_prev <= vsync;

            // Ustawienie nowego celu po wciśnięciu PPM (wykrycie zbocza narastającego)
            if (mouse_right && !right_click_prev) begin
                target_x <= mouse_xpos;
                target_y <= mouse_ypos;
            end

            // Ruch postaci (wykonuje się tylko raz na klatkę obrazu, gdy vsync idzie w górę)
            if (vsync && !vsync_prev) begin
                
                // Ruch w osi X
                if (player_x < target_x) begin
                    if (target_x - player_x <= player_speed) player_x <= target_x;
                    else player_x <= player_x + player_speed;
                end else if (player_x > target_x) begin
                    if (player_x - target_x <= player_speed) player_x <= target_x;
                    else player_x <= player_x - player_speed;
                end
                
                // Ruch w osi Y
                if (player_y < target_y) begin
                    if (target_y - player_y <= player_speed) player_y <= target_y;
                    else player_y <= player_y + player_speed;
                end else if (player_y > target_y) begin
                    if (player_y - target_y <= player_speed) player_y <= target_y;
                    else player_y <= player_y - player_speed;
                end
            end
        end
    end

    // Przypisanie do wyjść
    assign xpos = player_x;
    assign ypos = player_y;

endmodule
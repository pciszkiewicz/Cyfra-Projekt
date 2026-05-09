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

    // Zasada MTM: Parametry dużymi literami
    localparam PLAYER_START_X = 12'd512;
    localparam PLAYER_START_Y = 12'd384;
    localparam PLAYER_SPEED   = 12'd3;

    // Zasada MTM: Sygnały kombinacyjne z sufiksem _nxt
    logic [11:0] player_x, player_x_nxt;
    logic [11:0] player_y, player_y_nxt;
    logic [11:0] target_x, target_x_nxt;
    logic [11:0] target_y, target_y_nxt;
    
    logic right_click_prev, right_click_prev_nxt;
    logic vsync_prev, vsync_prev_nxt;

    // 1. Blok sekwencyjny - WYŁĄCZNIE reset synchroniczny i przepisywanie _nxt
    always_ff @(posedge clk) begin : seq_blk
        if (!rst_n) begin
            player_x <= PLAYER_START_X;
            player_y <= PLAYER_START_Y;
            target_x <= PLAYER_START_X;
            target_y <= PLAYER_START_Y;
            right_click_prev <= 1'b0;
            vsync_prev <= 1'b0;
        end else begin
            player_x <= player_x_nxt;
            player_y <= player_y_nxt;
            target_x <= target_x_nxt;
            target_y <= target_y_nxt;
            right_click_prev <= right_click_prev_nxt;
            vsync_prev <= vsync_prev_nxt;
        end
    end

    // 2. Blok kombinacyjny - wyliczanie logiki
    always_comb begin : comb_blk
        // Domyślne przypisania zapobiegające powstawaniu zatrzasków (latches)
        player_x_nxt = player_x;
        player_y_nxt = player_y;
        target_x_nxt = target_x;
        target_y_nxt = target_y;
        right_click_prev_nxt = mouse_right;
        vsync_prev_nxt = vsync;

        // Reakcja na kliknięcie PPM
        if (mouse_right && !right_click_prev) begin
            target_x_nxt = mouse_xpos;
            target_y_nxt = mouse_ypos;
        end

        // Ruch postaci aktualizowany co klatkę (zbocze narastające vsync)
        if (vsync && !vsync_prev) begin
            
            // Ruch w osi X
            if (player_x < target_x) begin
                if (target_x - player_x <= PLAYER_SPEED) player_x_nxt = target_x;
                else player_x_nxt = player_x + PLAYER_SPEED;
            end else if (player_x > target_x) begin
                if (player_x - target_x <= PLAYER_SPEED) player_x_nxt = target_x;
                else player_x_nxt = player_x - PLAYER_SPEED;
            end
            
            // Ruch w osi Y
            if (player_y < target_y) begin
                if (target_y - player_y <= PLAYER_SPEED) player_y_nxt = target_y;
                else player_y_nxt = player_y + PLAYER_SPEED;
            end else if (player_y > target_y) begin
                if (player_y - target_y <= PLAYER_SPEED) player_y_nxt = target_y;
                else player_y_nxt = player_y - PLAYER_SPEED;
            end
        end
    end

    assign xpos = player_x;
    assign ypos = player_y;

endmodule
`timescale 1ns / 1ps

module draw_rect_ctl #(
    parameter int TICK_LIMIT = 666665 
)(
    input  logic clk,
    input  logic rst_n,
    input  logic mouse_left,
    input  logic [11:0] mouse_xpos,
    input  logic [11:0] mouse_ypos,
    output logic [11:0] xpos,
    output logic [11:0] ypos
);

    import vga_pkg::*;

    localparam int LOGO_HEIGHT = 64;
    localparam int BOTTOM_WALL = 600 - LOGO_HEIGHT;
    
    // Poprawna stała grawitacji
    localparam signed [23:0] GRAVITY = 24'h00_5733; 

    // Rejestry dla osi Y (pozycja i prędkość z ułamkami)
    logic signed [23:0] y_pos_q, y_pos_nxt;
    logic signed [23:0] y_vel_q, y_vel_nxt;

    // Rejestry dla osi X 
    logic [11:0] x_pos_q, x_pos_nxt;

    // Generator impulsu 60 Hz
    logic [19:0] tick_cnt;
    logic physics_tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_cnt <= '0;
            physics_tick <= 1'b0;
        end else begin
            if (tick_cnt == TICK_LIMIT) begin
                tick_cnt <= '0;
                physics_tick <= 1'b1;
            end else begin
                tick_cnt <= tick_cnt + 1'b1;
                physics_tick <= 1'b0;
            end
        end
    end

    // Rejestry stanu (Pamięć pozycji)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_pos_q <= '0;
            y_vel_q <= '0;
            x_pos_q <= '0;
        end else begin
            y_pos_q <= y_pos_nxt;
            y_vel_q <= y_vel_nxt;
            x_pos_q <= x_pos_nxt;
        end
    end

    // Logika fizyki
    always_comb begin
        y_pos_nxt = y_pos_q;
        y_vel_nxt = y_vel_q;
        x_pos_nxt = x_pos_q;

        if (mouse_left == 1'b0) begin
            // Logo podąża za myszą
            y_pos_nxt = {mouse_ypos, 12'b0};
            y_vel_nxt = '0;
            x_pos_nxt = mouse_xpos;
        end else if (physics_tick) begin
            // Krok symulacji (swobodny spadek)
            
            y_vel_nxt = y_vel_q + GRAVITY;
            y_pos_nxt = y_pos_q + y_vel_nxt;

            // Kolizja z dnem
            if (y_pos_nxt[23:12] >= BOTTOM_WALL) begin
                y_pos_nxt = {BOTTOM_WALL[11:0], 12'b0};
                // 48-bitowe rzutowanie chroniące przed błędem overflow
                y_vel_nxt = -( (y_vel_nxt * 48'sd819) >>> 10 ); 
            end

            // Zabezpieczenie przed ucieczką górą
            if (y_pos_nxt < 0) begin
                y_pos_nxt = 0;
                y_vel_nxt = -( (y_vel_nxt * 48'sd819) >>> 10 );
            end
        end
    end

    assign xpos = x_pos_q; 
    assign ypos = y_pos_q[23:12];

endmodule
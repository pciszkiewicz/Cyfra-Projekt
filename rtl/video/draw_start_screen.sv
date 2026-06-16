`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Moduł renderujący ekran startowy (menu główne) gry.
 * Zawiera zakodowaną wektorowo geometrię logo UEC2 oraz przycisku START
 * reagującego zmianą koloru na pozycję kursora myszy (efekt hover).
 */

module draw_start_screen (
    input logic clk,
    input logic rst_n,
    vga_if.out out,
    input logic [2:0] current_state,
    input logic [11:0] mouse_x,
    input logic [11:0] mouse_y,
    input logic mouse_left,
    vga_if.in in
);

/* Local variables and signals */
logic is_char_u, is_char_e, is_char_c, is_char_2, is_logo;
logic is_char_s, is_char_t1, is_char_a, is_char_r, is_char_t2, is_start_text;
logic is_button_area, mouse_over_button;
logic [11:0] button_color, rgb_nxt;

/* Module internal logic */
always_comb begin
    is_char_u = (in.hcount >= 11'd382 && in.hcount < 11'd392 && in.vcount >= 11'd200 && in.vcount < 11'd270) || 
                (in.hcount >= 11'd422 && in.hcount < 11'd432 && in.vcount >= 11'd200 && in.vcount < 11'd270) || 
                (in.hcount >= 11'd392 && in.hcount < 11'd422 && in.vcount >= 11'd260 && in.vcount < 11'd270);

    is_char_e = (in.hcount >= 11'd452 && in.hcount < 11'd462 && in.vcount >= 11'd200 && in.vcount < 11'd270) || 
                (in.hcount >= 11'd462 && in.hcount < 11'd502 && in.vcount >= 11'd200 && in.vcount < 11'd210) || 
                (in.hcount >= 11'd462 && in.hcount < 11'd492 && in.vcount >= 11'd230 && in.vcount < 11'd240) || 
                (in.hcount >= 11'd462 && in.hcount < 11'd502 && in.vcount >= 11'd260 && in.vcount < 11'd270);

    is_char_c = (in.hcount >= 11'd522 && in.hcount < 11'd532 && in.vcount >= 11'd200 && in.vcount < 11'd270) || 
                (in.hcount >= 11'd532 && in.hcount < 11'd572 && in.vcount >= 11'd200 && in.vcount < 11'd210) || 
                (in.hcount >= 11'd532 && in.hcount < 11'd572 && in.vcount >= 11'd260 && in.vcount < 11'd270);

    is_char_2 = (in.hcount >= 11'd592 && in.hcount < 11'd642 && in.vcount >= 11'd200 && in.vcount < 11'd210) || 
                (in.hcount >= 11'd632 && in.hcount < 11'd642 && in.vcount >= 11'd210 && in.vcount < 11'd230) || 
                (in.hcount >= 11'd592 && in.hcount < 11'd642 && in.vcount >= 11'd230 && in.vcount < 11'd240) || 
                (in.hcount >= 11'd592 && in.hcount < 11'd602 && in.vcount >= 11'd240 && in.vcount < 11'd260) || 
                (in.hcount >= 11'd592 && in.hcount < 11'd642 && in.vcount >= 11'd260 && in.vcount < 11'd270);

    is_logo = is_char_u | is_char_e | is_char_c | is_char_2;

    is_char_s = (in.hcount >= 11'd430 && in.hcount < 11'd450 && in.vcount >= 11'd465 && in.vcount < 11'd470) ||
                (in.hcount >= 11'd430 && in.hcount < 11'd435 && in.vcount >= 11'd470 && in.vcount < 11'd485) ||
                (in.hcount >= 11'd430 && in.hcount < 11'd450 && in.vcount >= 11'd485 && in.vcount < 11'd490) ||
                (in.hcount >= 11'd445 && in.hcount < 11'd450 && in.vcount >= 11'd490 && in.vcount < 11'd505) ||
                (in.hcount >= 11'd430 && in.hcount < 11'd450 && in.vcount >= 11'd505 && in.vcount < 11'd510);

    is_char_t1 = (in.hcount >= 11'd460 && in.hcount < 11'd480 && in.vcount >= 11'd465 && in.vcount < 11'd470) ||
                 (in.hcount >= 11'd467 && in.hcount < 11'd473 && in.vcount >= 11'd470 && in.vcount < 11'd510);

    is_char_a = (in.hcount >= 11'd490 && in.hcount < 11'd495 && in.vcount >= 11'd470 && in.vcount < 11'd510) ||
                (in.hcount >= 11'd505 && in.hcount < 11'd510 && in.vcount >= 11'd470 && in.vcount < 11'd510) ||
                (in.hcount >= 11'd495 && in.hcount < 11'd505 && in.vcount >= 11'd465 && in.vcount < 11'd470) ||
                (in.hcount >= 11'd495 && in.hcount < 11'd505 && in.vcount >= 11'd485 && in.vcount < 11'd490);

    is_char_r = (in.hcount >= 11'd520 && in.hcount < 11'd525 && in.vcount >= 11'd465 && in.vcount < 11'd510) ||
                (in.hcount >= 11'd525 && in.hcount < 11'd540 && in.vcount >= 11'd465 && in.vcount < 11'd470) ||
                (in.hcount >= 11'd535 && in.hcount < 11'd540 && in.vcount >= 11'd470 && in.vcount < 11'd485) ||
                (in.hcount >= 11'd525 && in.hcount < 11'd540 && in.vcount >= 11'd485 && in.vcount < 11'd490) ||
                (in.hcount >= 11'd535 && in.hcount < 11'd540 && in.vcount >= 11'd490 && in.vcount < 11'd510);

    is_char_t2 = (in.hcount >= 11'd550 && in.hcount < 11'd570 && in.vcount >= 11'd465 && in.vcount < 11'd470) ||
                 (in.hcount >= 11'd557 && in.hcount < 11'd563 && in.vcount >= 11'd470 && in.vcount < 11'd510);

    is_start_text = is_char_s | is_char_t1 | is_char_a | is_char_r | is_char_t2;

    is_button_area = (in.hcount >= 11'd412 && in.hcount < 11'd612 && in.vcount >= 11'd450 && in.vcount < 11'd510);
    mouse_over_button = (mouse_x >= 12'd412 && mouse_x < 12'd612 && mouse_y >= 12'd450 && mouse_y < 12'd510);

    if (mouse_over_button && mouse_left) begin
        button_color = 12'h0F0;
    end else if (mouse_over_button) begin
        button_color = 12'hF80;
    end else begin
        button_color = 12'hF00;
    end

    if (current_state == 3'd0) begin
        if (is_start_text) begin
            rgb_nxt = 12'hFFF;
        end else if (is_button_area) begin
            rgb_nxt = button_color;
        end else if (is_logo) begin
            rgb_nxt = 12'hFFF;
        end else begin
            rgb_nxt = 12'h333;
        end
    end else begin
        rgb_nxt = in.rgb;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= 11'h0;
        out.hcount <= 11'h0;
        out.vsync <= 1'b0;
        out.hsync <= 1'b0;
        out.vblnk <= 1'b0;
        out.hblnk <= 1'b0;
        out.rgb <= 12'h0;
    end else begin
        out.vcount <= in.vcount;
        out.hcount <= in.hcount;
        out.vsync <= in.vsync;
        out.hsync <= in.hsync;
        out.vblnk <= in.vblnk;
        out.hblnk <= in.hblnk;
        out.rgb <= rgb_nxt;
    end
end

endmodule
`timescale 1 ns / 1 ps

module draw_start_screen (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [2:0] current_state,
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic        mouse_left,
    vga_if.in          in,
    vga_if.out         out
);

    logic is_char_u, is_char_e, is_char_c, is_char_2, is_logo;
    logic is_char_s, is_char_t1, is_char_a, is_char_r, is_char_t2, is_start_text;
    logic is_button_area, mouse_over_button;
    logic [11:0] button_color, rgb_nxt;

    always_comb begin
        is_char_u = (in.hcount >= 382 && in.hcount < 392 && in.vcount >= 200 && in.vcount < 270) || 
                    (in.hcount >= 422 && in.hcount < 432 && in.vcount >= 200 && in.vcount < 270) || 
                    (in.hcount >= 392 && in.hcount < 422 && in.vcount >= 260 && in.vcount < 270);

        is_char_e = (in.hcount >= 452 && in.hcount < 462 && in.vcount >= 200 && in.vcount < 270) || 
                    (in.hcount >= 462 && in.hcount < 502 && in.vcount >= 200 && in.vcount < 210) || 
                    (in.hcount >= 462 && in.hcount < 492 && in.vcount >= 230 && in.vcount < 240) || 
                    (in.hcount >= 462 && in.hcount < 502 && in.vcount >= 260 && in.vcount < 270);

        is_char_c = (in.hcount >= 522 && in.hcount < 532 && in.vcount >= 200 && in.vcount < 270) || 
                    (in.hcount >= 532 && in.hcount < 572 && in.vcount >= 200 && in.vcount < 210) || 
                    (in.hcount >= 532 && in.hcount < 572 && in.vcount >= 260 && in.vcount < 270);

        is_char_2 = (in.hcount >= 592 && in.hcount < 642 && in.vcount >= 200 && in.vcount < 210) || 
                    (in.hcount >= 632 && in.hcount < 642 && in.vcount >= 210 && in.vcount < 230) || 
                    (in.hcount >= 592 && in.hcount < 642 && in.vcount >= 230 && in.vcount < 240) || 
                    (in.hcount >= 592 && in.hcount < 602 && in.vcount >= 240 && in.vcount < 260) || 
                    (in.hcount >= 592 && in.hcount < 642 && in.vcount >= 260 && in.vcount < 270);

        is_logo = is_char_u | is_char_e | is_char_c | is_char_2;

        is_char_s = (in.hcount >= 430 && in.hcount < 450 && in.vcount >= 465 && in.vcount < 470) ||
                    (in.hcount >= 430 && in.hcount < 435 && in.vcount >= 470 && in.vcount < 485) ||
                    (in.hcount >= 430 && in.hcount < 450 && in.vcount >= 485 && in.vcount < 490) ||
                    (in.hcount >= 445 && in.hcount < 450 && in.vcount >= 490 && in.vcount < 505) ||
                    (in.hcount >= 430 && in.hcount < 450 && in.vcount >= 505 && in.vcount < 510);

        is_char_t1 = (in.hcount >= 460 && in.hcount < 480 && in.vcount >= 465 && in.vcount < 470) ||
                     (in.hcount >= 467 && in.hcount < 473 && in.vcount >= 470 && in.vcount < 510);

        is_char_a = (in.hcount >= 490 && in.hcount < 495 && in.vcount >= 470 && in.vcount < 510) ||
                    (in.hcount >= 505 && in.hcount < 510 && in.vcount >= 470 && in.vcount < 510) ||
                    (in.hcount >= 495 && in.hcount < 505 && in.vcount >= 465 && in.vcount < 470) ||
                    (in.hcount >= 495 && in.hcount < 505 && in.vcount >= 485 && in.vcount < 490);

        is_char_r = (in.hcount >= 520 && in.hcount < 525 && in.vcount >= 465 && in.vcount < 510) ||
                    (in.hcount >= 525 && in.hcount < 540 && in.vcount >= 465 && in.vcount < 470) ||
                    (in.hcount >= 535 && in.hcount < 540 && in.vcount >= 470 && in.vcount < 485) ||
                    (in.hcount >= 525 && in.hcount < 540 && in.vcount >= 485 && in.vcount < 490) ||
                    (in.hcount >= 535 && in.hcount < 540 && in.vcount >= 490 && in.vcount < 510);

        is_char_t2 = (in.hcount >= 550 && in.hcount < 570 && in.vcount >= 465 && in.vcount < 470) ||
                     (in.hcount >= 557 && in.hcount < 563 && in.vcount >= 470 && in.vcount < 510);

        is_start_text = is_char_s | is_char_t1 | is_char_a | is_char_r | is_char_t2;

        is_button_area = (in.hcount >= 412 && in.hcount < 612 && in.vcount >= 450 && in.vcount < 510);
        mouse_over_button = (mouse_x >= 412 && mouse_x < 612 && mouse_y >= 450 && mouse_y < 510);

        if (mouse_over_button && mouse_left)
            button_color = 12'h0F0;
        else if (mouse_over_button)
            button_color = 12'hF80;
        else
            button_color = 12'hF00;

        if (current_state == 2'd0) begin
            if (is_start_text)      rgb_nxt = 12'hFFF;
            else if (is_button_area) rgb_nxt = button_color;
            else if (is_logo)        rgb_nxt = 12'hFFF;
            else                   rgb_nxt = 12'h333;
        end else begin
            rgb_nxt = in.rgb;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.vcount <= '0;
            out.hcount <= '0;
            out.vsync  <= '0;
            out.hsync  <= '0;
            out.vblnk  <= '0;
            out.hblnk  <= '0;
            out.rgb    <= '0;
        end else begin
            out.vcount <= in.vcount;
            out.hcount <= in.hcount;
            out.vsync  <= in.vsync;
            out.hsync  <= in.hsync;
            out.vblnk  <= in.vblnk;
            out.hblnk  <= in.hblnk;
            out.rgb    <= rgb_nxt;
        end
    end

endmodule
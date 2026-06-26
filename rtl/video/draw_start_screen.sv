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
    input logic is_master,
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
logic is_txt_g, is_txt_r, is_txt_a, is_txt_c, is_txt_z, is_txt_1, is_txt_2, is_gracz_text;
logic is_button_area, is_button_border, mouse_over_button;
logic [11:0] button_color, bg_color, rgb_nxt;

/* Module internal logic */
always_comb begin
    // --- 1. ORYGINALNE LOGO UEC2 ---
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

    // --- 2. NAPIS START ---
    is_char_s = (in.hcount >= 11'd442 && in.hcount < 11'd462 && in.vcount >= 11'd458 && in.vcount < 11'd463) ||
                (in.hcount >= 11'd442 && in.hcount < 11'd447 && in.vcount >= 11'd463 && in.vcount < 11'd478) ||
                (in.hcount >= 11'd442 && in.hcount < 11'd462 && in.vcount >= 11'd478 && in.vcount < 11'd483) ||
                (in.hcount >= 11'd457 && in.hcount < 11'd462 && in.vcount >= 11'd483 && in.vcount < 11'd498) ||
                (in.hcount >= 11'd442 && in.hcount < 11'd462 && in.vcount >= 11'd498 && in.vcount < 11'd503);

    is_char_t1 = (in.hcount >= 11'd472 && in.hcount < 11'd492 && in.vcount >= 11'd458 && in.vcount < 11'd463) ||
                 (in.hcount >= 11'd479 && in.hcount < 11'd485 && in.vcount >= 11'd463 && in.vcount < 11'd503);

    is_char_a = (in.hcount >= 11'd502 && in.hcount < 11'd507 && in.vcount >= 11'd463 && in.vcount < 11'd503) ||
                (in.hcount >= 11'd517 && in.hcount < 11'd522 && in.vcount >= 11'd463 && in.vcount < 11'd503) ||
                (in.hcount >= 11'd507 && in.hcount < 11'd517 && in.vcount >= 11'd458 && in.vcount < 11'd463) ||
                (in.hcount >= 11'd507 && in.hcount < 11'd517 && in.vcount >= 11'd478 && in.vcount < 11'd483);

    is_char_r = (in.hcount >= 11'd532 && in.hcount < 11'd537 && in.vcount >= 11'd458 && in.vcount < 11'd503) ||
                (in.hcount >= 11'd537 && in.hcount < 11'd552 && in.vcount >= 11'd458 && in.vcount < 11'd463) ||
                (in.hcount >= 11'd547 && in.hcount < 11'd552 && in.vcount >= 11'd463 && in.vcount < 11'd478) ||
                (in.hcount >= 11'd537 && in.hcount < 11'd552 && in.vcount >= 11'd478 && in.vcount < 11'd483) ||
                (in.hcount >= 11'd547 && in.hcount < 11'd552 && in.vcount >= 11'd483 && in.vcount < 11'd503);

    is_char_t2 = (in.hcount >= 11'd562 && in.hcount < 11'd582 && in.vcount >= 11'd458 && in.vcount < 11'd463) ||
                 (in.hcount >= 11'd569 && in.hcount < 11'd575 && in.vcount >= 11'd463 && in.vcount < 11'd503);

    is_start_text = is_char_s | is_char_t1 | is_char_a | is_char_r | is_char_t2;

    // --- 3. NAPIS GRACZ 1 (Master) / GRACZ 2 (Slave) ---
    is_txt_g = (in.hcount >= 11'd458 && in.hcount < 11'd470 && in.vcount >= 11'd540 && in.vcount < 11'd543) || 
               (in.hcount >= 11'd458 && in.hcount < 11'd470 && in.vcount >= 11'd552 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd458 && in.hcount < 11'd461 && in.vcount >= 11'd540 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd467 && in.hcount < 11'd470 && in.vcount >= 11'd548 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd464 && in.hcount < 11'd470 && in.vcount >= 11'd548 && in.vcount < 11'd551);   

    is_txt_r = (in.hcount >= 11'd474 && in.hcount < 11'd477 && in.vcount >= 11'd540 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd474 && in.hcount < 11'd486 && in.vcount >= 11'd540 && in.vcount < 11'd543) || 
               (in.hcount >= 11'd483 && in.hcount < 11'd486 && in.vcount >= 11'd540 && in.vcount < 11'd548) || 
               (in.hcount >= 11'd474 && in.hcount < 11'd486 && in.vcount >= 11'd546 && in.vcount < 11'd549) || 
               (in.hcount >= 11'd483 && in.hcount < 11'd486 && in.vcount >= 11'd549 && in.vcount < 11'd555);   

    is_txt_a = (in.hcount >= 11'd490 && in.hcount < 11'd493 && in.vcount >= 11'd540 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd499 && in.hcount < 11'd502 && in.vcount >= 11'd540 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd490 && in.hcount < 11'd502 && in.vcount >= 11'd540 && in.vcount < 11'd543) || 
               (in.hcount >= 11'd490 && in.hcount < 11'd502 && in.vcount >= 11'd547 && in.vcount < 11'd550);   

    is_txt_c = (in.hcount >= 11'd506 && in.hcount < 11'd509 && in.vcount >= 11'd540 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd506 && in.hcount < 11'd518 && in.vcount >= 11'd540 && in.vcount < 11'd543) || 
               (in.hcount >= 11'd506 && in.hcount < 11'd518 && in.vcount >= 11'd552 && in.vcount < 11'd555);   

    is_txt_z = (in.hcount >= 11'd522 && in.hcount < 11'd534 && in.vcount >= 11'd540 && in.vcount < 11'd543) || 
               (in.hcount >= 11'd522 && in.hcount < 11'd534 && in.vcount >= 11'd552 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd528 && in.hcount < 11'd531 && in.vcount >= 11'd543 && in.vcount < 11'd548) || 
               (in.hcount >= 11'd525 && in.hcount < 11'd528 && in.vcount >= 11'd548 && in.vcount < 11'd552);   

    is_txt_1 = (in.hcount >= 11'd556 && in.hcount < 11'd559 && in.vcount >= 11'd540 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd553 && in.hcount < 11'd556 && in.vcount >= 11'd542 && in.vcount < 11'd545) || 
               (in.hcount >= 11'd550 && in.hcount < 11'd562 && in.vcount >= 11'd552 && in.vcount < 11'd555);   

    is_txt_2 = (in.hcount >= 11'd550 && in.hcount < 11'd562 && in.vcount >= 11'd540 && in.vcount < 11'd543) || 
               (in.hcount >= 11'd559 && in.hcount < 11'd562 && in.vcount >= 11'd543 && in.vcount < 11'd548) || 
               (in.hcount >= 11'd550 && in.hcount < 11'd562 && in.vcount >= 11'd546 && in.vcount < 11'd549) || 
               (in.hcount >= 11'd550 && in.hcount < 11'd553 && in.vcount >= 11'd549 && in.vcount < 11'd555) || 
               (in.hcount >= 11'd550 && in.hcount < 11'd562 && in.vcount >= 11'd552 && in.vcount < 11'd555);   

    is_gracz_text = is_txt_g | is_txt_r | is_txt_a | is_txt_c | is_txt_z | (is_master ? is_txt_1 : is_txt_2);

    // --- 4. GEOMETRIA PRZYCISKU ---
    is_button_area = (in.hcount >= 11'd412 && in.hcount < 11'd612 && in.vcount >= 11'd450 && in.vcount < 11'd510);
    is_button_border = is_button_area && 
                       (in.hcount < 11'd416 || in.hcount >= 11'd608 || 
                        in.vcount < 11'd454 || in.vcount >= 11'd506);

    mouse_over_button = (mouse_x >= 12'd412 && mouse_x < 12'd612 && mouse_y >= 12'd450 && mouse_y < 12'd510);

    // Dynamiczny algorytmiczny gradient
    bg_color[11:8] = in.hcount[9:6];         
    bg_color[7:4]  = 4'h2;                   
    bg_color[3:0]  = in.vcount[9:6] + 4'h3;  

    if (mouse_over_button && mouse_left) begin
        button_color = 12'h0F0;
    end else if (mouse_over_button) begin
        button_color = 12'hF80;
    end else begin
        button_color = 12'hF00;
    end

    // --- 5. MULTIPLEKSER KOLORÓW NA EKRANIE ---
    if (current_state == 3'd0) begin
        if (is_start_text) begin
            rgb_nxt = 12'hFFF;               // Biały tekst "START"
        end else if (is_button_border) begin
            rgb_nxt = 12'hAAA;               // Szare obramowanie przycisku
        end else if (is_button_area) begin
            rgb_nxt = button_color;          // Czerwony / Pomarańczowy / Zielony zależnie od myszki
        end else if (is_logo) begin
            rgb_nxt = 12'hFD0;               // Złote logo UEC2 (zamiast dotychczasowego białego)
        end else if (is_gracz_text) begin
            rgb_nxt = is_master ? 12'h0DF : 12'h0D0; // Master = jasnoniebieski, Slave = zielony
        end else begin
            rgb_nxt = bg_color;              // Kolorowy gradient w tle
        end
    end else begin
        rgb_nxt = in.rgb;
    end
end

/* Oryginalny blok przerzutników sterujący sygnałami interfejsu */
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= 11'h0;
        out.hcount <= 11'h0;
        out.vsync  <= 1'b0;
        out.hsync  <= 1'b0;
        out.vblnk  <= 1'b0;
        out.hblnk  <= 1'b0;
        out.rgb    <= 12'h0;
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
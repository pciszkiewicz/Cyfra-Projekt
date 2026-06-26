`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Moduł renderujący ekran końcowy (Game Over) gry.
 * Zawiera zakodowaną wektorowo geometrię napisu "GRACZ 1 WYGRYWA" oraz 
 * "GRACZ 2 WYGRYWA". Dodano mniejszy napis "LPM - POWROT DO MENU".
 * Wyświetla odpowiedni komunikat na podstawie sygnału winner_id.
 */

module draw_game_over (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [2:0] current_state,
    input  logic [1:0] winner_id,
    vga_if.in          in,
    vga_if.out         out
);

/* Local variables and signals */
logic is_txt_g, is_txt_r, is_txt_a, is_txt_c, is_txt_z, is_txt_1, is_txt_2;
logic is_txt_w, is_txt_y, is_txt_g2, is_txt_r2, is_txt_y2, is_txt_w2, is_txt_a2;

logic is_gracz_text, is_wygrywa_text, is_lpm_text;
logic is_player_1_win, is_player_2_win;
logic [11:0] rgb_nxt;

/* Module internal logic */
always_comb begin
    // --- 1. SŁOWO "GRACZ" ---
    is_txt_g = (in.hcount >= 11'd420 && in.hcount < 11'd440 && in.vcount >= 11'd340 && in.vcount < 11'd345) || 
               (in.hcount >= 11'd420 && in.hcount < 11'd440 && in.vcount >= 11'd360 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd420 && in.hcount < 11'd425 && in.vcount >= 11'd340 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd435 && in.hcount < 11'd440 && in.vcount >= 11'd352 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd430 && in.hcount < 11'd440 && in.vcount >= 11'd352 && in.vcount < 11'd357);   

    is_txt_r = (in.hcount >= 11'd450 && in.hcount < 11'd455 && in.vcount >= 11'd340 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd450 && in.hcount < 11'd470 && in.vcount >= 11'd340 && in.vcount < 11'd345) || 
               (in.hcount >= 11'd465 && in.hcount < 11'd470 && in.vcount >= 11'd340 && in.vcount < 11'd355) || 
               (in.hcount >= 11'd450 && in.hcount < 11'd470 && in.vcount >= 11'd350 && in.vcount < 11'd355) || 
               (in.hcount >= 11'd465 && in.hcount < 11'd470 && in.vcount >= 11'd355 && in.vcount < 11'd365);   

    is_txt_a = (in.hcount >= 11'd480 && in.hcount < 11'd485 && in.vcount >= 11'd340 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd495 && in.hcount < 11'd500 && in.vcount >= 11'd340 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd480 && in.hcount < 11'd500 && in.vcount >= 11'd340 && in.vcount < 11'd345) || 
               (in.hcount >= 11'd480 && in.hcount < 11'd500 && in.vcount >= 11'd350 && in.vcount < 11'd355);   

    is_txt_c = (in.hcount >= 11'd510 && in.hcount < 11'd515 && in.vcount >= 11'd340 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd510 && in.hcount < 11'd530 && in.vcount >= 11'd340 && in.vcount < 11'd345) || 
               (in.hcount >= 11'd510 && in.hcount < 11'd530 && in.vcount >= 11'd360 && in.vcount < 11'd365);   

    is_txt_z = (in.hcount >= 11'd540 && in.hcount < 11'd560 && in.vcount >= 11'd340 && in.vcount < 11'd345) || 
               (in.hcount >= 11'd540 && in.hcount < 11'd560 && in.vcount >= 11'd360 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd550 && in.hcount < 11'd555 && in.vcount >= 11'd345 && in.vcount < 11'd352) || 
               (in.hcount >= 11'd545 && in.hcount < 11'd550 && in.vcount >= 11'd352 && in.vcount < 11'd360);   

    // --- 2. CYFRY 1 i 2 ---
    is_txt_1 = (in.hcount >= 11'd590 && in.hcount < 11'd595 && in.vcount >= 11'd340 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd585 && in.hcount < 11'd590 && in.vcount >= 11'd345 && in.vcount < 11'd350) || 
               (in.hcount >= 11'd580 && in.hcount < 11'd605 && in.vcount >= 11'd360 && in.vcount < 11'd365);   

    is_txt_2 = (in.hcount >= 11'd580 && in.hcount < 11'd600 && in.vcount >= 11'd340 && in.vcount < 11'd345) || 
               (in.hcount >= 11'd595 && in.hcount < 11'd600 && in.vcount >= 11'd345 && in.vcount < 11'd352) || 
               (in.hcount >= 11'd580 && in.hcount < 11'd600 && in.vcount >= 11'd350 && in.vcount < 11'd355) || 
               (in.hcount >= 11'd580 && in.hcount < 11'd585 && in.vcount >= 11'd355 && in.vcount < 11'd365) || 
               (in.hcount >= 11'd580 && in.hcount < 11'd600 && in.vcount >= 11'd360 && in.vcount < 11'd365);   

    is_gracz_text = is_txt_g | is_txt_r | is_txt_a | is_txt_c | is_txt_z;

    // --- 3. SŁOWO "WYGRYWA" ---
    is_txt_w = (in.hcount >= 11'd410 && in.hcount < 11'd415 && in.vcount >= 11'd390 && in.vcount < 11'd415) ||
               (in.hcount >= 11'd420 && in.hcount < 11'd425 && in.vcount >= 11'd390 && in.vcount < 11'd415) ||
               (in.hcount >= 11'd430 && in.hcount < 11'd435 && in.vcount >= 11'd390 && in.vcount < 11'd415) ||
               (in.hcount >= 11'd410 && in.hcount < 11'd435 && in.vcount >= 11'd410 && in.vcount < 11'd415);

    is_txt_y = (in.hcount >= 11'd445 && in.hcount < 11'd450 && in.vcount >= 11'd390 && in.vcount < 11'd400) ||
               (in.hcount >= 11'd460 && in.hcount < 11'd465 && in.vcount >= 11'd390 && in.vcount < 11'd400) ||
               (in.hcount >= 11'd445 && in.hcount < 11'd465 && in.vcount >= 11'd400 && in.vcount < 11'd405) ||
               (in.hcount >= 11'd450 && in.hcount < 11'd455 && in.vcount >= 11'd405 && in.vcount < 11'd415);

    is_txt_g2 = (in.hcount >= 11'd475 && in.hcount < 11'd495 && in.vcount >= 11'd390 && in.vcount < 11'd395) || 
                (in.hcount >= 11'd475 && in.hcount < 11'd495 && in.vcount >= 11'd410 && in.vcount < 11'd415) || 
                (in.hcount >= 11'd475 && in.hcount < 11'd480 && in.vcount >= 11'd390 && in.vcount < 11'd415) || 
                (in.hcount >= 11'd490 && in.hcount < 11'd495 && in.vcount >= 11'd402 && in.vcount < 11'd415) || 
                (in.hcount >= 11'd485 && in.hcount < 11'd495 && in.vcount >= 11'd402 && in.vcount < 11'd407);

    is_txt_r2 = (in.hcount >= 11'd505 && in.hcount < 11'd510 && in.vcount >= 11'd390 && in.vcount < 11'd415) || 
                (in.hcount >= 11'd505 && in.hcount < 11'd525 && in.vcount >= 11'd390 && in.vcount < 11'd395) || 
                (in.hcount >= 11'd520 && in.hcount < 11'd525 && in.vcount >= 11'd390 && in.vcount < 11'd405) || 
                (in.hcount >= 11'd505 && in.hcount < 11'd525 && in.vcount >= 11'd400 && in.vcount < 11'd405) || 
                (in.hcount >= 11'd520 && in.hcount < 11'd525 && in.vcount >= 11'd405 && in.vcount < 11'd415);

    is_txt_y2 = (in.hcount >= 11'd535 && in.hcount < 11'd540 && in.vcount >= 11'd390 && in.vcount < 11'd400) ||
                (in.hcount >= 11'd550 && in.hcount < 11'd555 && in.vcount >= 11'd390 && in.vcount < 11'd400) ||
                (in.hcount >= 11'd535 && in.hcount < 11'd555 && in.vcount >= 11'd400 && in.vcount < 11'd405) ||
                (in.hcount >= 11'd540 && in.hcount < 11'd545 && in.vcount >= 11'd405 && in.vcount < 11'd415);

    is_txt_w2 = (in.hcount >= 11'd565 && in.hcount < 11'd570 && in.vcount >= 11'd390 && in.vcount < 11'd415) ||
                (in.hcount >= 11'd575 && in.hcount < 11'd580 && in.vcount >= 11'd390 && in.vcount < 11'd415) ||
                (in.hcount >= 11'd585 && in.hcount < 11'd590 && in.vcount >= 11'd390 && in.vcount < 11'd415) ||
                (in.hcount >= 11'd565 && in.hcount < 11'd590 && in.vcount >= 11'd410 && in.vcount < 11'd415);

    is_txt_a2 = (in.hcount >= 11'd600 && in.hcount < 11'd605 && in.vcount >= 11'd390 && in.vcount < 11'd415) || 
                (in.hcount >= 11'd615 && in.hcount < 11'd620 && in.vcount >= 11'd390 && in.vcount < 11'd415) || 
                (in.hcount >= 11'd600 && in.hcount < 11'd620 && in.vcount >= 11'd390 && in.vcount < 11'd395) || 
                (in.hcount >= 11'd600 && in.hcount < 11'd620 && in.vcount >= 11'd400 && in.vcount < 11'd405);

    is_wygrywa_text = is_txt_w | is_txt_y | is_txt_g2 | is_txt_r2 | is_txt_y2 | is_txt_w2 | is_txt_a2;

    // --- 4. NAPIS "LPM - POWROT DO MENU" ---
    is_lpm_text = 
        // L
        (in.hcount >= 11'd310 && in.hcount < 11'd314 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd314 && in.hcount < 11'd322 && in.vcount >= 11'd496 && in.vcount < 11'd500) ||
        // P
        (in.hcount >= 11'd330 && in.hcount < 11'd334 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd334 && in.hcount < 11'd338 && ((in.vcount >= 11'd480 && in.vcount < 11'd484) || (in.vcount >= 11'd488 && in.vcount < 11'd492))) ||
        (in.hcount >= 11'd338 && in.hcount < 11'd342 && in.vcount >= 11'd480 && in.vcount < 11'd492) ||
        // M
        (in.hcount >= 11'd350 && in.hcount < 11'd354 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd358 && in.hcount < 11'd362 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd354 && in.hcount < 11'd358 && in.vcount >= 11'd484 && in.vcount < 11'd488) ||
        // -
        (in.hcount >= 11'd390 && in.hcount < 11'd402 && in.vcount >= 11'd488 && in.vcount < 11'd492) ||
        // P
        (in.hcount >= 11'd430 && in.hcount < 11'd434 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd434 && in.hcount < 11'd438 && ((in.vcount >= 11'd480 && in.vcount < 11'd484) || (in.vcount >= 11'd488 && in.vcount < 11'd492))) ||
        (in.hcount >= 11'd438 && in.hcount < 11'd442 && in.vcount >= 11'd480 && in.vcount < 11'd492) ||
        // O
        (in.hcount >= 11'd450 && in.hcount < 11'd454 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd458 && in.hcount < 11'd462 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd454 && in.hcount < 11'd458 && ((in.vcount >= 11'd480 && in.vcount < 11'd484) || (in.vcount >= 11'd496 && in.vcount < 11'd500))) ||
        // W
        (in.hcount >= 11'd470 && in.hcount < 11'd474 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd478 && in.hcount < 11'd482 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd474 && in.hcount < 11'd478 && in.vcount >= 11'd492 && in.vcount < 11'd500) ||
        // R
        (in.hcount >= 11'd490 && in.hcount < 11'd494 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd494 && in.hcount < 11'd498 && ((in.vcount >= 11'd480 && in.vcount < 11'd484) || (in.vcount >= 11'd488 && in.vcount < 11'd492))) ||
        (in.hcount >= 11'd498 && in.hcount < 11'd502 && ((in.vcount >= 11'd480 && in.vcount < 11'd492) || (in.vcount >= 11'd492 && in.vcount < 11'd500))) ||
        // O
        (in.hcount >= 11'd510 && in.hcount < 11'd514 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd518 && in.hcount < 11'd522 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd514 && in.hcount < 11'd518 && ((in.vcount >= 11'd480 && in.vcount < 11'd484) || (in.vcount >= 11'd496 && in.vcount < 11'd500))) ||
        // T
        (in.hcount >= 11'd530 && in.hcount < 11'd542 && in.vcount >= 11'd480 && in.vcount < 11'd484) ||
        (in.hcount >= 11'd534 && in.hcount < 11'd538 && in.vcount >= 11'd484 && in.vcount < 11'd500) ||
        // D
        (in.hcount >= 11'd570 && in.hcount < 11'd574 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd574 && in.hcount < 11'd578 && ((in.vcount >= 11'd480 && in.vcount < 11'd484) || (in.vcount >= 11'd496 && in.vcount < 11'd500))) ||
        (in.hcount >= 11'd578 && in.hcount < 11'd582 && in.vcount >= 11'd484 && in.vcount < 11'd496) ||
        // O
        (in.hcount >= 11'd590 && in.hcount < 11'd594 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd598 && in.hcount < 11'd602 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd594 && in.hcount < 11'd598 && ((in.vcount >= 11'd480 && in.vcount < 11'd484) || (in.vcount >= 11'd496 && in.vcount < 11'd500))) ||
        // M
        (in.hcount >= 11'd630 && in.hcount < 11'd634 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd638 && in.hcount < 11'd642 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd634 && in.hcount < 11'd638 && in.vcount >= 11'd484 && in.vcount < 11'd488) ||
        // E
        (in.hcount >= 11'd650 && in.hcount < 11'd654 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd654 && in.hcount < 11'd662 && ((in.vcount >= 11'd480 && in.vcount < 11'd484) || (in.vcount >= 11'd488 && in.vcount < 11'd492) || (in.vcount >= 11'd496 && in.vcount < 11'd500))) ||
        // N
        (in.hcount >= 11'd670 && in.hcount < 11'd674 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd678 && in.hcount < 11'd682 && in.vcount >= 11'd480 && in.vcount < 11'd500) ||
        (in.hcount >= 11'd674 && in.hcount < 11'd678 && in.vcount >= 11'd484 && in.vcount < 11'd496) ||
        // U
        (in.hcount >= 11'd690 && in.hcount < 11'd694 && in.vcount >= 11'd480 && in.vcount < 11'd496) ||
        (in.hcount >= 11'd698 && in.hcount < 11'd702 && in.vcount >= 11'd480 && in.vcount < 11'd496) ||
        (in.hcount >= 11'd690 && in.hcount < 11'd702 && in.vcount >= 11'd496 && in.vcount < 11'd500);

    // --- 5. MULTIPLEKSER KOLORÓW NA EKRANIE ---
    if (current_state == 3'd5 && (!in.vblnk) && (!in.hblnk)) begin
        
        is_player_1_win = (winner_id == 2'd1) && (is_gracz_text | is_txt_1 | is_wygrywa_text);
        is_player_2_win = (winner_id == 2'd2) && (is_gracz_text | is_txt_2 | is_wygrywa_text);

        if (is_player_1_win) begin
            rgb_nxt = 12'h0DF; // Kolor wygranej Gracza 1
        end 
        else if (is_player_2_win) begin
            rgb_nxt = 12'h0D0; // Kolor wygranej Gracza 2
        end 
        else if (is_lpm_text) begin
            rgb_nxt = 12'hFFF; // Biały kolor instrukcji powrotu
        end
        else begin
            rgb_nxt = 12'h111; // Tło Game Over
        end

    end else begin
        rgb_nxt = in.rgb; 
    end
end

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
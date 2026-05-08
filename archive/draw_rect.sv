`timescale 1ns / 1ps

module draw_rect #(
    parameter int WIDTH  = 48,
    parameter int HEIGHT = 64
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [11:0] xpos,
    input  logic [11:0] ypos,
    vga_if.in    in,
    vga_if.out   out,
    output logic [11:0] pixel_addr,
    input  logic [11:0] rgb_pixel
);

    // Logika kombinacyjna wejścia 
    logic is_inside;
    logic [11:0] x_diff_full, y_diff_full;

    always_comb begin
        x_diff_full = in.hcount - xpos;
        y_diff_full = in.vcount - ypos;

        // Sprawdzamy, czy aktualnie rysowany piksel mieści się w naszym obiekcie
        if ((in.hcount >= xpos) && (in.hcount < xpos + WIDTH) &&
            (in.vcount >= ypos) && (in.vcount < ypos + HEIGHT)) begin
            is_inside = 1'b1;
            pixel_addr = {y_diff_full[5:0], x_diff_full[5:0]};
        end else begin
            is_inside = 1'b0;
            pixel_addr = '0;
        end
    end

    // Kompensacja 1 taktu opóźnienia dla odczytu z pamięci ROM
    logic is_inside_d1;
    logic [5:0] x_diff_d1, y_diff_d1;
    
    logic [10:0] hcount_d1, vcount_d1;
    logic vsync_d1, vblnk_d1, hsync_d1, hblnk_d1;
    logic [11:0] rgb_bg_d1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_inside_d1 <= 1'b0;
            x_diff_d1    <= '0;
            y_diff_d1    <= '0;
            
            hcount_d1    <= '0;
            vcount_d1    <= '0;
            vsync_d1     <= 1'b0;
            vblnk_d1     <= 1'b0;
            hsync_d1     <= 1'b0;
            hblnk_d1     <= 1'b0;
            rgb_bg_d1    <= '0;
        end else begin
            is_inside_d1 <= is_inside;
            x_diff_d1    <= x_diff_full[5:0];
            y_diff_d1    <= y_diff_full[5:0];
            
            // Przesunięcie sygnałów synchronizacji i tła
            hcount_d1    <= in.hcount;
            vcount_d1    <= in.vcount;
            vsync_d1     <= in.vsync;
            vblnk_d1     <= in.vblnk;
            hsync_d1     <= in.hsync;
            hblnk_d1     <= in.hblnk;
            rgb_bg_d1    <= in.rgb;
        end
    end

    // Logika MUX koloru i Rejestry Wyjściowe
    logic [11:0] rgb_nxt;

    // Kombinacyjny wybór koloru na podstawie zsynchronizowanych danych
    always_comb begin
        if (is_inside_d1) begin
            if (y_diff_d1 == 0)             rgb_nxt = 12'h0_F_0; // Zielona góra
            else if (y_diff_d1 == HEIGHT-1) rgb_nxt = 12'hF_0_0; // Czerwony dół
            else if (x_diff_d1 == 0)        rgb_nxt = 12'hF_F_0; // Żółty lewy
            else if (x_diff_d1 == WIDTH-1)  rgb_nxt = 12'h0_0_F; // Niebieski prawy
            else                            rgb_nxt = rgb_pixel; // Środek: grafika z ROM
        end else begin
            rgb_nxt = rgb_bg_d1; // Tło 
        end
    end

    // Wyjścia interfejsu ściśle zarejestrowane
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.hcount <= '0;
            out.vcount <= '0;
            out.vsync  <= 1'b0;
            out.vblnk  <= 1'b0;
            out.hsync  <= 1'b0;
            out.hblnk  <= 1'b0;
            out.rgb    <= '0;
        end else begin
            out.hcount <= hcount_d1;
            out.vcount <= vcount_d1;
            out.vsync  <= vsync_d1;
            out.vblnk  <= vblnk_d1;
            out.hsync  <= hsync_d1;
            out.hblnk  <= hblnk_d1;
            out.rgb    <= rgb_nxt;
        end
    end

endmodule
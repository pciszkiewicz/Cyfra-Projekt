`timescale 1 ns / 1 ps

// Moduł sterujący ruchem gracza na mapie za pomocą myszki
module player_ctl (
    input  logic        clk,
    input  logic        rst,
    input  logic        frame_tick, // Impuls (1 cykl zegara) np. z VGA co klatkę (60Hz) dla płynnego ruchu
    input  logic [9:0]  mouse_x,    // Pozycja myszy na ekranie X (od 0 do 1023)
    input  logic [9:0]  mouse_y,    // Pozycja myszy na ekranie Y (od 0 do 767)
    input  logic        mouse_rmb,  // Prawy przycisk myszy (PPM)

    output logic [11:0] player_x,   // Globalna pozycja X gracza na mapie (0 - 2047)
    output logic [11:0] player_y    // Globalna pozycja Y gracza na mapie (0 - 2047)
);

    // Parametry ruchu
    localparam CENTER_X = 10'd512;
    localparam CENTER_Y = 10'd384;
    localparam DEADZONE = 10'd20; // Strefa martwa (aby postać nie drżała, gdy mysz jest idealnie na środku)
    localparam SPEED    = 12'd4;  // Prędkość poruszania się (piksele na klatkę)

    // Pozycja startowa Gracza 1 (zgodnie z mapą: wiersz 15, kolumna 2 -> wyśrodkowane)
    // X = 2 * 64 + 32 = 160
    // Y = 15 * 64 + 32 = 992
    localparam START_X = 12'd160;
    localparam START_Y = 12'd992;

    logic [11:0] player_x_reg, player_x_nxt;
    logic [11:0] player_y_reg, player_y_nxt;

    // Część sekwencyjna (Rejestry)
    always_ff @(posedge clk) begin
        if (rst) begin
            player_x_reg <= START_X;
            player_y_reg <= START_Y;
        end else begin
            player_x_reg <= player_x_nxt;
            player_y_reg <= player_y_nxt;
        end
    end

    // Część kombinacyjna (Logika ruchu)
    always_comb begin
        // Domyślnie pozycja się nie zmienia
        player_x_nxt = player_x_reg;
        player_y_nxt = player_y_reg;

        // Poruszamy się tylko, gdy wciśnięty jest PPM i otrzymujemy impuls nowej klatki obrazu
        if (mouse_rmb && frame_tick) begin
            // Ruch w osi X
            if (mouse_x > (CENTER_X + DEADZONE)) begin
                player_x_nxt = player_x_reg + SPEED;
            end else if (mouse_x < (CENTER_X - DEADZONE)) begin
                player_x_nxt = player_x_reg - SPEED;
            end

            // Ruch w osi Y
            if (mouse_y > (CENTER_Y + DEADZONE)) begin
                player_y_nxt = player_y_reg + SPEED;
            end else if (mouse_y < (CENTER_Y - DEADZONE)) begin
                player_y_nxt = player_y_reg - SPEED;
            end
        end
    end

    // Wyjścia modułu
    assign player_x = player_x_reg;
    assign player_y = player_y_reg;

endmodule
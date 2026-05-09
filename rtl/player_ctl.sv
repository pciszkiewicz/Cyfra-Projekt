`timescale 1 ns / 1 ps

module player_ctl (
    input  logic        clk,
    input  logic        rst,
    input  logic        frame_tick,
    input  logic [9:0]  mouse_x,
    input  logic [9:0]  mouse_y,
    input  logic        mouse_rmb,

    // Interfejs do sprawdzania kolizji
    output logic [9:0]  map_addr,    
    input  logic        is_wall,     

    output logic [11:0] player_x,
    output logic [11:0] player_y
);

    localparam SPEED = 12'd4;
    localparam CENTER_X = 10'd512;
    localparam CENTER_Y = 10'd384;
    localparam START_X = 12'd160;  // Twoje wartości startowe
    localparam START_Y = 12'd992;  //

    logic [11:0] px_reg, py_reg;
    logic [11:0] test_x, test_y;

    // 1. Logika wyboru kafelka do sprawdzenia (Kombinacyjna)
    // Sprawdzamy kafelek, na który CHCEMY wejść
    always_comb begin
        test_x = px_reg;
        test_y = py_reg;

        if (mouse_rmb) begin
            if (mouse_x > CENTER_X + 20)      test_x = px_reg + SPEED + 16;
            else if (mouse_x < CENTER_X - 20) test_x = px_reg - SPEED - 16;
            
            if (mouse_y > CENTER_Y + 20)      test_y = py_reg + SPEED + 16;
            else if (mouse_y < CENTER_Y - 20) test_y = py_reg - SPEED - 16;
        end
        
        // Adres dla map_rom (Y[10:6], X[10:6])
        map_addr = {test_y[10:6], test_x[10:6]}; 
    end

    // 2. Logika ruchu (Sekwencyjna)
    // Tu is_wall odnosi się do adresu wystawionego w poprzednim takcie
    always_ff @(posedge clk) begin
        if (rst) begin
            px_reg <= START_X;
            py_reg <= START_Y;
        end else if (frame_tick && mouse_rmb) begin
            // Jeśli pamięć ROM mówi, że tam NIE MA ściany, wykonaj ruch
            if (!is_wall) begin
                 // Ruch X
                 if (mouse_x > CENTER_X + 20)      px_reg <= px_reg + SPEED;
                 else if (mouse_x < CENTER_X - 20) px_reg <= px_reg - SPEED;

                 // Ruch Y
                 if (mouse_y > CENTER_Y + 20)      py_reg <= py_reg + SPEED;
                 else if (mouse_y < CENTER_Y - 20) py_reg <= py_reg - SPEED;
            end
        end
    end

    assign player_x = px_reg;
    assign player_y = py_reg;

endmodule
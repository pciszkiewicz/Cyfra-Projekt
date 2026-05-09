`timescale 1 ns / 1 ps

// Pamięć przechowująca układ ścian na naszej mapie 32x32
module map_rom (
    input  logic       clk,
    input  logic [9:0] addr,     // 10-bitowy adres: [9:5] to Y kafelka, [4:0] to X kafelka
    output logic       is_wall   // Wyjście: 1 = ściana, 0 = podłoga
);

    // Deklaracja pamięci: 1024 elementy, każdy po 1 bit
    logic [0:0] rom_memory [0:1023];

    // Wczytanie układu mapy
    initial begin
        $readmemb("map_walls.mem", rom_memory);
    end

    // Synchroniczny odczyt (wymagane by użyć bloków BRAM w Basys 3)
    always_ff @(posedge clk) begin
        is_wall <= rom_memory[addr];
    end

endmodule
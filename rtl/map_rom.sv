/**
 * MTM UEC2
 * Author: Tomasz Jesionek / Poprawki pod mapę 64x64
 *
 * Description:
 * ROM memory storing the wall layout for a 64x64 map.
 * Initialized from an external .mem file.
 */

 module map_rom (
    input  logic        clk,
    input  logic [11:0] addr_a,      // Zmiana z [9:0] na [11:0] dla 4096 kafelków
    output logic        is_wall_a,
    input  logic [11:0] addr_b,      // Zmiana z [9:0] na [11:0] dla 4096 kafelków
    output logic        is_wall_b
);

// Zmiana rozmiaru tablicy z 1024 na 4096 (64 kafelki * 64 kafelki)
logic rom_memory [4096];

initial begin
    $readmemb("map_walls.mem", rom_memory);
end

always_ff @(posedge clk) begin
    is_wall_a <= rom_memory[addr_a];
    is_wall_b <= rom_memory[addr_b];
end

endmodule
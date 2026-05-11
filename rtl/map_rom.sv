/**
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * ROM memory storing the wall layout for a 32x32 map.
 * Initialized from an external .mem file.
 */

 module map_rom (
    input  logic        clk,
    input  logic [9:0]  addr_a,
    output logic        is_wall_a,
    input  logic [9:0]  addr_b,
    output logic        is_wall_b
);

logic rom_memory [1024];

initial begin
    $readmemb("map_walls.mem", rom_memory);
end

always_ff @(posedge clk) begin
    is_wall_a <= rom_memory[addr_a];
    is_wall_b <= rom_memory[addr_b];
end

endmodule
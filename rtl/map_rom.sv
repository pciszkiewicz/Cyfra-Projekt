`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek / Poprawki pod mape 64x64
 *
 * Description:
 * ROM memory storing the wall layout for a 64x64 map.
 * Initialized from an external .mem file.
 */
module map_rom (
    input logic clk,
    input logic rst_n,
    output logic is_wall_a,
    output logic is_wall_b,
    input logic [11:0] addr_a,
    input logic [11:0] addr_b
);

/* Local variables and signals */
/* Zmiana rozmiaru tablicy z 1024 na 4096 (64 kafelki * 64 kafelki) */
(* rom_style = "block" *) logic [0:0] rom_memory [4096];

/* Memory initialization */
initial begin
    $readmemb("../../rtl/memory/map_walls.mem", rom_memory);
end

/* Module internal logic */
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        is_wall_a <= 1'b0;
        is_wall_b <= 1'b0;
    end else begin
        is_wall_a <= rom_memory[addr_a];
        is_wall_b <= rom_memory[addr_b];
    end
end

endmodule
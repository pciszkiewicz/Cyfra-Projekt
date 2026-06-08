/**
 * Copyright (C) 2026 AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * ROM memory storing 256 different crate layouts (32-bit masks).
 * Initialized from an external .mem file.
 */

 module crates_rom (
    input  logic        clk,
    output logic [31:0] data_out,
    input  logic [7:0]  addr
);

(* rom_style = "block" *) logic [31:0] rom_memory [256];

initial begin
    $readmemb("crates_data.mem", rom_memory);
end

always_ff @(posedge clk) begin
    data_out <= rom_memory[addr];
end

endmodule
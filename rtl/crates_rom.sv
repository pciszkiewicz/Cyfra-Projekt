`timescale 1 ns / 1 ps

/*
 * Copyright (C) 2026 AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * ROM memory storing 256 different crate layouts (32-bit masks).
 * Initialized from an external .mem file.
 */
module crates_rom (
    input logic clk,
    input logic rst_n,
    output logic [31:0] data_out,
    input logic [7:0] addr
);

/* Local variables and signals */
(* rom_style = "block" *) logic [31:0] rom_memory [256];

/* Memory initialization */
initial begin
    $readmemb("../../rtl/memory/crates_data.mem", rom_memory);
end

/* Module internal logic */
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_out <= 32'h0;
    end else begin
        data_out <= rom_memory[addr];
    end
end

endmodule
`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * Generator liczb pseudolosowych oparty na rejestrze przesuwnym z liniowym sprzężeniem zwrotnym.
 * (16-bit LFSR). Wykorzystywany do losowania indeksu konfiguracji skrzyń przy starcie gry.
 */

module lfsr #(
    parameter logic [15:0] SEED = 16'hACE1
) (
    input logic clk,
    input logic rst_n,
    output logic [15:0] rand_out,
    input logic en
);

/* Local variables and signals */
logic [15:0] lfsr_reg;
logic [15:0] lfsr_reg_nxt;
logic feedback;

/* Signals assignments */
assign rand_out = lfsr_reg;

/* Module internal logic */
always_comb begin
    feedback = lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10];
    
    lfsr_reg_nxt = lfsr_reg;
    
    if (en) begin
        lfsr_reg_nxt = {lfsr_reg[14:0], feedback};
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        lfsr_reg <= SEED;
    end else begin
        lfsr_reg <= lfsr_reg_nxt;
    end
end

endmodule
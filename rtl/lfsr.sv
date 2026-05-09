`timescale 1 ns / 1 ps

// Moduł generatora pseudolosowego LFSR
// Służy do generowania losowego adresu dla pamięci układu skrzynek
module lfsr #(
    parameter SEED = 16'hACE1 // Wartość początkowa - ziarno (nie może być 0!)
)(
    input  logic        clk,      // Zegar systemowy
    input  logic        rst,      // Synchroniczny reset
    input  logic        en,       // Sygnał zezwolenia na przesuwanie (u nas 1'b1)
    output logic [15:0] rand_out  // Wyjściowa losowa wartość 16-bitowa
);

    logic [15:0] lfsr_reg;
    logic        feedback;

    // Funkcja sprzężenia zwrotnego (XOR) dla 16-bitowego LFSR
    // Wielomian: x^16 + x^14 + x^13 + x^11 + 1
    assign feedback = lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10];

    always_ff @(posedge clk) begin
        if (rst) begin
            lfsr_reg <= SEED;
        end else if (en) begin
            // Przesuwamy w lewo i na najmłodszy bit wrzucamy wynik XOR
            lfsr_reg <= {lfsr_reg[14:0], feedback};
        end
    end

    // Przypisanie do wyjścia
    assign rand_out = lfsr_reg;

endmodule
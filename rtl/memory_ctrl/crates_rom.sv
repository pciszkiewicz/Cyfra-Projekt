`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Pamięć ROM zawierająca prekonfigurowane układy (rozmieszczenie) skrzyń na mapie.
 * Adresowana za pomocą wartości z generatora LFSR, zapewniając losowość mapy przy każdym starcie.
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
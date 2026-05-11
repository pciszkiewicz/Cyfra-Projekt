/**
 * Autorzy: 
 * Opis: Pamięć ROM przechowująca 256 różnych układów skrzynek (maski 32-bitowe).
 * Inicjalizowana z pliku zewnętrznego .mem.
 */

 module crates_rom (
    input  logic        clk,
    input  logic [7:0]  addr,     /* 8-bitowy adres z generatora LFSR */
    output logic [31:0] data_out  /* 32-bitowa maska skrzynek dla FSM */
);

    /* Deklaracja pamięci: 256 elementów, każdy po 32 bity */
    logic [31:0] rom_memory [0:255];

    /* * Wczytanie zawartości pamięci. 
     * Użycie bloku 'initial' jest tutaj dopuszczalne jako wyjątek dla pamięci ROM.
     */
    initial begin : load_crates_data
        $readmemb("crates_data.mem", rom_memory);
    end

    /* Odczyt synchroniczny - wymagany dla poprawnej inferencji BRAM w FPGA */
    always_ff @(posedge clk) begin
        data_out <= rom_memory[addr];
    end

endmodule
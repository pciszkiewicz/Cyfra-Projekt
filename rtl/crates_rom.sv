`timescale 1 ns / 1 ps

module crates_rom (
    input  logic        clk,
    input  logic [7:0]  addr,     // 8-bitowy adres z naszego generatora LFSR
    output logic [31:0] data_out  // 32-bitowa maska skrzynek wyciągnięta z pamięci
);

    // Deklaracja pamięci: 256 elementów, każdy po 32 bity
    logic [31:0] rom_memory [0:255];

    // Wczytanie zawartości pamięci z pliku podczas startu układu
    initial begins
        $readmemb("crates_data.mem", rom_memory);
    end

    // Odczyt synchroniczny (najlepsza praktyka w FPGA, by użyć pamięci Block RAM)
    always_ff @(posedge clk) begin
        data_out <= rom_memory[addr];
    end

endmodules
`timescale 1 ns / 1 ps

// Moduł spinający całą główną logikę decyzyjną gry
module game_logic_top (
    input  logic        clk,
    input  logic        rst,
    input  logic        start_btn,       // Przycisk rozpoczynający grę
    input  logic        phase_timeout,   // Sygnał końca czasu na zbieranie
    input  logic [31:0] crates_hit_mask, // Sygnał z informacją o zestrzelonych skrzynkach

    output logic [31:0] active_crates,   // Wypuszczamy info, które skrzynki mają się rysować
    output logic [1:0]  current_state    // Wypuszczamy info o aktualnej fazie gry
);

    // Wewnętrzne "kabelki" (sygnały) do łączenia modułów
    logic [15:0] lfsr_out;
    logic [31:0] rom_data_out;
    logic [7:0]  rom_addr;

    // 1. Instancja generatora losowego (LFSR)
    lfsr #(
        .SEED(16'hACE1)
    ) u_lfsr (
        .clk(clk),
        .rst(rst),
        .en(1'b1),            // Cały czas włączony, generuje losowy szum w tle
        .rand_out(lfsr_out)
    );

    // 2. Instancja pamięci ROM z naszymi układami skrzynek
    crates_rom u_crates_rom (
        .clk(clk),
        .addr(rom_addr),
        .data_out(rom_data_out)
    );

    // 3. Instancja Głównej Maszyny Stanów (FSM)
    game_fsm u_game_fsm (
        .clk(clk),
        .rst(rst),
        .start_btn(start_btn),
        .phase_timeout(phase_timeout),
        .lfsr_val(lfsr_out[7:0]), // Do maszyny podajemy 8 dolnych bitów z LFSR
        .rom_data(rom_data_out),
        .crates_hit_mask(crates_hit_mask),
        .rom_addr(rom_addr),
        .active_crates(active_crates),
        .current_state(current_state)
    );

endmodule
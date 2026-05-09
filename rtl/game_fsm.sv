`timescale 1 ns / 1 ps

module game_fsm (
    input  logic        clk,
    input  logic        rst,             // Synchroniczny reset
    input  logic        start_btn,       // Przycisk startu (przejście z ekranu startowego)
    input  logic        phase_timeout,   // Sygnał końca fazy lootowania
    input  logic [7:0]  lfsr_val,        // 8-bitowa losowa wartość z LFSR
    input  logic [31:0] rom_data,        // 32-bitowy układ skrzynek odczytany z ROM
    input  logic [31:0] crates_hit_mask, // Maska trafień (bit 1 oznacza zniszczenie)
    
    output logic [7:0]  rom_addr,        // Adres wysyłany do pamięci ROM
    output logic [31:0] active_crates,   // Aktualny stan skrzynek (dla modułu rysującego)
    output logic [1:0]  current_state    // Informacja o fazie gry
);

    // Definicje stanów maszyny (parametry)
    typedef enum logic [1:0] {
        ST_INIT    = 2'd0,
        ST_LOOTING = 2'd1,
        ST_COMBAT  = 2'd2,
        ST_END     = 2'd3
    } state_t;

    state_t state, state_nxt;
    logic [31:0] active_crates_reg, active_crates_nxt;

    // Część sekwencyjna (rejestry) - zapamiętywanie stanu
    always_ff @(posedge clk) begin
        if (rst) begin
            state             <= ST_INIT;
            active_crates_reg <= 32'b0;
        end else begin
            state             <= state_nxt;
            active_crates_reg <= active_crates_nxt;
        end
    end

    // Część kombinacyjna maszyny stanów (logika przejść)
    always_comb begin
        // Przypisania domyślne (unikamy powstawania latchy)
        state_nxt         = state;
        active_crates_nxt = active_crates_reg;
        
        // LFSR działa cały czas w tle. Podajemy jego wartość jako adres ROM.
        // Pamięć w każdym takcie przygotowuje jeden losowy układ 32-bitowy na wejściu 'rom_data'.
        rom_addr          = lfsr_val; 

        case (state)
            ST_INIT: begin
                if (start_btn) begin
                    state_nxt = ST_LOOTING;
                    // Wczytujemy układ skrzynek z ROM w momencie rozpoczęcia gry
                    active_crates_nxt = rom_data;
                end
            end

            ST_LOOTING: begin
                // Reakcja na strzały: niszczenie skrzynek.
                // Używamy operacji AND z zanegowaną maską trafień (jeśli na maskę wejdzie '1', bit zostaje wyzerowany).
                active_crates_nxt = active_crates_reg & ~crates_hit_mask;

                if (phase_timeout) begin
                    state_nxt         = ST_COMBAT;
                    active_crates_nxt = 32'b0; // Na czas fazy walki skrzynki znikają
                end
            end

            ST_COMBAT: begin
                // Logika przejścia do ST_END (np. po śmierci gracza) znajdzie się tu w przyszłości
            end

            ST_END: begin
                if (start_btn) begin
                     state_nxt = ST_INIT;
                end
            end
            
            // Domyślny stan bezpieczeństwa
            default: begin
                state_nxt = ST_INIT;
            end
        endcase
    end

    // Wyprowadzenie sygnałów na zewnątrz
    assign current_state = state;
    assign active_crates = active_crates_reg;

endmodule
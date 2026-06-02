`timescale 1 ns / 1 ps

module uart_rx #(
    parameter int CLK_FREQ  = 65_000_000, 
    parameter int BAUD_RATE = 115200
)(
    input  logic       clk,
    input  logic       rst_n,      // Reset asynchroniczny
    
    input  logic       rx,         // Linia wejściowa (z pinu PMOD)
    
    output logic [7:0] rx_data,    // Otrzymany bajt
    output logic       rx_ready    // Impuls (1 takt zegara), gdy dane są gotowe
);

    localparam int BAUD_TIMER_MAX = CLK_FREQ / BAUD_RATE;
    
    typedef enum logic [1:0] {
        ST_IDLE  = 2'd0,
        ST_START = 2'd1,
        ST_DATA  = 2'd2,
        ST_STOP  = 2'd3
    } state_t;

    state_t state_reg, state_nxt;
    
    logic [15:0] timer_reg, timer_nxt;
    logic [2:0]  bit_idx_reg, bit_idx_nxt;
    logic [7:0]  data_reg, data_nxt;
    logic        ready_reg, ready_nxt;
    
    // Podwójny rejestr synchronizujący wejście asynchroniczne (zapobiega metastabilności)
    logic rx_sync1, rx_sync2;

    // --- BLOK SEKWENCYJNY (Asynchroniczny Reset + Synchronizator) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg   <= ST_IDLE;
            timer_reg   <= '0;
            bit_idx_reg <= '0;
            data_reg    <= '0;
            ready_reg   <= 1'b0;
            rx_sync1    <= 1'b1;
            rx_sync2    <= 1'b1;
        end else begin
            state_reg   <= state_nxt;
            timer_reg   <= timer_nxt;
            bit_idx_reg <= bit_idx_nxt;
            data_reg    <= data_nxt;
            ready_reg   <= ready_nxt;
            rx_sync1    <= rx;
            rx_sync2    <= rx_sync1; // Sygnał bezpieczny do użycia w maszynie stanów
        end
    end

    // --- BLOK KOMBINACYJNY (Logika Odbioru) ---
    always_comb begin
        state_nxt   = state_reg;
        timer_nxt   = timer_reg;
        bit_idx_nxt = bit_idx_reg;
        data_nxt    = data_reg;
        ready_nxt   = 1'b0; // Impuls gotowości jest domyślnie zerowany

        case (state_reg)
            ST_IDLE: begin
                // Wykrycie opadającego zbocza (Bit Startu)
                if (rx_sync2 == 1'b0) begin
                    timer_nxt = '0;
                    state_nxt = ST_START;
                end
            end

            ST_START: begin
                // Odczekanie do POŁOWY czasu trwania bitu startu
                if (timer_reg == (BAUD_TIMER_MAX / 2) - 1) begin
                    if (rx_sync2 == 1'b0) begin // Potwierdzenie, że to faktycznie start, a nie szpilka zakłóceń
                        timer_nxt   = '0;
                        bit_idx_nxt = '0;
                        state_nxt   = ST_DATA;
                    end else begin
                        state_nxt   = ST_IDLE; // Fałszywy alarm
                    end
                end else begin
                    timer_nxt = timer_reg + 1;
                end
            end

            ST_DATA: begin
                if (timer_reg == BAUD_TIMER_MAX - 1) begin
                    timer_nxt = '0;
                    data_nxt[bit_idx_reg] = rx_sync2; // Próbkowanie bitu
                    
                    if (bit_idx_reg == 3'd7) begin
                        state_nxt = ST_STOP;
                    end else begin
                        bit_idx_nxt = bit_idx_reg + 1;
                    end
                end else begin
                    timer_nxt = timer_reg + 1;
                end
            end

            ST_STOP: begin
                if (timer_reg == BAUD_TIMER_MAX - 1) begin
                    ready_nxt = 1'b1; // Wystawienie flagi nowej danej
                    state_nxt = ST_IDLE;
                end else begin
                    timer_nxt = timer_reg + 1;
                end
            end
        endcase
    end

    assign rx_data  = data_reg;
    assign rx_ready = ready_reg;

endmodule
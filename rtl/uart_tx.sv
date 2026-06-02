`timescale 1 ns / 1 ps

module uart_tx #(
    // Parametry domyślne (np. dla zegara pikselowego VGA 65 MHz)
    parameter int CLK_FREQ  = 65_000_000, 
    parameter int BAUD_RATE = 115200
)(
    input  logic       clk,
    input  logic       rst_n,      // Reset asynchroniczny
    
    input  logic       tx_start,   // Impuls rozpoczynający transmisję
    input  logic [7:0] tx_data,    // Bajt do wysłania
    
    output logic       tx,         // Linia wyjściowa (do pinu PMOD)
    output logic       tx_busy     // Flaga: 1 = nadajnik zajęty
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
    logic        tx_reg, tx_nxt;

    // --- BLOK SEKWENCYJNY (Asynchroniczny Reset) ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg   <= ST_IDLE;
            timer_reg   <= '0;
            bit_idx_reg <= '0;
            data_reg    <= '0;
            tx_reg      <= 1'b1; // Linia UART w stanie spoczynku ma stan wysoki
        end else begin
            state_reg   <= state_nxt;
            timer_reg   <= timer_nxt;
            bit_idx_reg <= bit_idx_nxt;
            data_reg    <= data_nxt;
            tx_reg      <= tx_nxt;
        end
    end

    // --- BLOK KOMBINACYJNY (Logika Stanów) ---
    always_comb begin
        state_nxt   = state_reg;
        timer_nxt   = timer_reg;
        bit_idx_nxt = bit_idx_reg;
        data_nxt    = data_reg;
        tx_nxt      = tx_reg;

        case (state_reg)
            ST_IDLE: begin
                tx_nxt = 1'b1;
                if (tx_start) begin
                    data_nxt  = tx_data;
                    timer_nxt = '0;
                    state_nxt = ST_START;
                end
            end

            ST_START: begin
                tx_nxt = 1'b0; // Bit startu to stan niski
                if (timer_reg == BAUD_TIMER_MAX - 1) begin
                    timer_nxt   = '0;
                    bit_idx_nxt = '0;
                    state_nxt   = ST_DATA;
                end else begin
                    timer_nxt = timer_reg + 1;
                end
            end

            ST_DATA: begin
                tx_nxt = data_reg[bit_idx_reg]; // Wysyłanie LSB (najmłodszego bitu) najpierw
                if (timer_reg == BAUD_TIMER_MAX - 1) begin
                    timer_nxt = '0;
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
                tx_nxt = 1'b1; // Bit stopu to stan wysoki
                if (timer_reg == BAUD_TIMER_MAX - 1) begin
                    state_nxt = ST_IDLE;
                end else begin
                    timer_nxt = timer_reg + 1;
                end
            end
        endcase
    end

    assign tx_busy = (state_reg != ST_IDLE);
    assign tx = tx_reg;

endmodule
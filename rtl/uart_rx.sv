`timescale 1 ns / 1 ps

module uart_rx #(
    parameter int CLK_FREQ = 65_000_000, 
    parameter int BAUD_RATE = 115200
) (
    input logic clk,
    input logic rst_n,
    output logic [7:0] rx_data,
    output logic rx_ready,
    input logic rx
);

/* Local parameters */
localparam int BAUD_TIMER_MAX = CLK_FREQ / BAUD_RATE;

/* User defined types and constants */
typedef enum logic [1:0] {
    ST_IDLE  = 2'd0,
    ST_START = 2'd1,
    ST_DATA  = 2'd2,
    ST_STOP  = 2'd3
} state_t;

/* Local variables and signals */
state_t state_reg, state_nxt;

logic [15:0] timer_reg, timer_nxt;
logic [2:0] bit_idx_reg, bit_idx_nxt;
logic [7:0] data_reg, data_nxt;
logic ready_reg, ready_nxt;

(* ASYNC_REG = "TRUE" *) logic rx_sync1_reg, rx_sync2_reg;
logic rx_sync1_nxt, rx_sync2_nxt;

/* Signals assignments */
assign rx_data = data_reg;
assign rx_ready = ready_reg;

/* Module internal logic */
always_comb begin
    rx_sync1_nxt = rx;
    rx_sync2_nxt = rx_sync1_reg;
end

always_comb begin
    state_nxt = state_reg;
    timer_nxt = timer_reg;
    bit_idx_nxt = bit_idx_reg;
    data_nxt = data_reg;
    ready_nxt = 1'b0;

    case (state_reg)
        ST_IDLE: begin
            /* Wykrycie opadajacego zbocza (Bit Startu) */
            if (rx_sync2_reg == 1'b0) begin
                timer_nxt = 16'd0;
                state_nxt = ST_START;
            end
        end

        ST_START: begin
            /* Odczekanie do POLOWY czasu trwania bitu startu */
            if (timer_reg == 16'((BAUD_TIMER_MAX / 2) - 1)) begin
                if (rx_sync2_reg == 1'b0) begin
                    /* Potwierdzenie, ze to faktycznie start, a nie szpilka zaklocen */
                    timer_nxt = 16'd0;
                    bit_idx_nxt = 3'd0;
                    state_nxt = ST_DATA;
                end else begin
                    /* Falszywy alarm */
                    state_nxt = ST_IDLE;
                end
            end else begin
                timer_nxt = timer_reg + 16'd1;
            end
        end

        ST_DATA: begin
            if (timer_reg == 16'(BAUD_TIMER_MAX - 1)) begin
                timer_nxt = 16'd0;
                /* Probkowanie bitu */
                data_nxt[bit_idx_reg] = rx_sync2_reg;
                
                if (bit_idx_reg == 3'd7) begin
                    state_nxt = ST_STOP;
                end else begin
                    bit_idx_nxt = bit_idx_reg + 3'd1;
                end
            end else begin
                timer_nxt = timer_reg + 16'd1;
            end
        end

        ST_STOP: begin
            if (timer_reg == 16'(BAUD_TIMER_MAX - 1)) begin
                /* Wystawienie flagi nowej danej */
                ready_nxt = 1'b1;
                state_nxt = ST_IDLE;
            end else begin
                timer_nxt = timer_reg + 16'd1;
            end
        end
        
        default: begin
            state_nxt = ST_IDLE;
        end
    endcase
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state_reg <= ST_IDLE;
        timer_reg <= 16'd0;
        bit_idx_reg <= 3'd0;
        data_reg <= 8'd0;
        ready_reg <= 1'b0;
        rx_sync1_reg <= 1'b1;
        rx_sync2_reg <= 1'b1;
    end else begin
        state_reg <= state_nxt;
        timer_reg <= timer_nxt;
        bit_idx_reg <= bit_idx_nxt;
        data_reg <= data_nxt;
        ready_reg <= ready_nxt;
        rx_sync1_reg <= rx_sync1_nxt;
        rx_sync2_reg <= rx_sync2_nxt;
    end
end

endmodule
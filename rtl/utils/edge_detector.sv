`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * Uniwersalny detektor zbocza narastającego (Posedge Edge Detector).
 * Analizuje sygnał wejściowy i generuje dokładnie jeden impuls (szpilkę) zegarową
 * w momencie wykrycia przejścia ze stanu niskiego w wysoki.
 */

module edge_detector (
    input logic clk,
    input logic rst_n,
    output logic out_pulse,
    input logic in_signal
);

/* Local variables and signals */
logic in_signal_d1_reg, in_signal_d1_nxt;

/* Signals assignments */
/* Wyrzucamy jedynke tylko w takcie, w ktorym sygnal wszedl w stan wysoki,
   a w poprzednim takcie byl jeszcze w stanie niskim. */
assign out_pulse = in_signal & (~in_signal_d1_reg);

/* Module internal logic */
always_comb begin
    in_signal_d1_nxt = in_signal;
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        in_signal_d1_reg <= 1'b0;
    end else begin
        in_signal_d1_reg <= in_signal_d1_nxt;
    end
end

endmodule
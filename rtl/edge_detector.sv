`timescale 1 ns / 1 ps

module edge_detector (
    input  logic clk,
    input  logic rst_n,       // Reset asynchroniczny
    input  logic in_signal,
    output logic out_pulse
);

    logic in_signal_delayed;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_signal_delayed <= 1'b0;
        end else begin
            in_signal_delayed <= in_signal;
        end
    end

    // Wyrzucamy jedynkę tylko w takcie, w którym sygnał wszedł w stan wysoki,
    // a w poprzednim takcie był jeszcze w stanie niskim.
    assign out_pulse = in_signal & ~in_signal_delayed;

endmodule
module char_rom #(
    parameter string TEXT = {
        "                                ",
        "  MTM UEC2 - Lab 1 - Krok 2     ",
        "  Prostokat 32 x 8 znakow       ",
        "  Test pamieci char_rom         ",
        "  123456789012345678901234567890",
        "  ABCDEFGHIJKLMNOPQRSTUVWXYZ    ",
        "  abcdefghijklmnopqrstuvwxyz    ",
        "                                "
    }
)(
    input  logic clk,
    input  logic [7:0] addr, // 256 pozycji (32 kolumny * 8 wierszy)
    output logic [6:0] char_code
);

    logic [6:0] rom [0:255];

    initial begin
        for (int i = 0; i < 256; i++) begin
            if (i < TEXT.len())
                rom[i] = 7'(TEXT[i]);
            else
                rom[i] = 7'h20;
        end
    end

    always_ff @(posedge clk) begin
        char_code <= rom[addr];
    end

endmodule
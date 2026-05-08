`timescale 1ns / 1ps

module draw_rect_ctl_tb;
    // Sygnały wejściowe
    logic clk;
    logic rst_n;
    logic mouse_right;
    logic [11:0] mouse_xpos;
    logic [11:0] mouse_ypos;
    logic vsync;
    
    // Sygnały wyjściowe
    logic [11:0] xpos;
    logic [11:0] ypos;

    draw_rect_ctl dut (
        .clk(clk),
        .rst_n(rst_n),
        .mouse_right(mouse_right),
        .mouse_xpos(mouse_xpos),
        .mouse_ypos(mouse_ypos),
        .vsync(vsync),
        .xpos(xpos),
        .ypos(ypos)
    );

    // Generator Zegara 40 MHz 
    // Okres 25 ns (zmiana stanu co 12.5 ns)
    initial begin
        clk = 1'b0;
        forever #12.5 clk = ~clk;
    end

    // Task - generowanie pojedynczego impulsu VSYNC
    task pulse_vsync();
        begin
            @(posedge clk);
            vsync = 1'b1;
            @(posedge clk);
            vsync = 1'b0;
            repeat(10) @(posedge clk);
        end
    endtask

    initial begin
        // Inicjalizacja
        rst_n = 1'b0;
        mouse_right = 1'b0;
        mouse_xpos = 12'd0;
        mouse_ypos = 12'd0;
        vsync = 1'b0;

        // Reset
        #50;
        rst_n = 1'b1;
        #50;

        $display("START TESTU: Pozycja poczatkowa: X=%0d, Y=%0d", xpos, ypos);

        // Symulacja kliknięcia myszką 
        @(posedge clk);
        mouse_xpos = 12'd415;
        mouse_ypos = 12'd285;
        mouse_right = 1'b1;   // Wciśnięcie PPM
        
        @(posedge clk);
        mouse_right = 1'b0;   // Puszczenie PPM po takcie zegara
        
        $display(">>> PPM - Cel:X=415, Y=285 <<<");

        // Generujemy klatki obrazu i patrzymy jak kwadrat idzie do celu
        // Skoro różnica to 15 pikseli, a kwadrat idzie 3 px na klatkę, 
        // to po 5 klatkach (VSYNCach) powinien dojść do celu.
        // Wygenerujemy 7 klatek, żeby udowodnić działanie "Hamulca" (w klatce 6 i 7 pozycja się nie zmieni)
        
        for (int i = 1; i <= 7; i++) begin
            pulse_vsync();
            $display("VSYNC: %0d; Pozycja: X=%0d, Y=%0d", i, xpos, ypos);
        end

        $display("KONIEC TESTU.");
        
        #100;
        $finish;
    end

endmodule
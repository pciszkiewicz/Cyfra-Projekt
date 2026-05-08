module draw_rect_ctl_prog (
    input  logic clk,
    output logic rst_n,
    output logic mouse_left,
    output logic [11:0] mouse_xpos,
    output logic [11:0] mouse_ypos
);

    timeunit 1ns;
    timeprecision 1ps;

    initial begin
        // Reset układu
        rst_n = 1'b0;
        mouse_left = 1'b0;
        mouse_xpos = 12'd100;
        mouse_ypos = 12'd50; 
        
        // Czekamy synchronicznie na opadające zbocza zegara
        repeat(5) @(negedge clk);
        
        // Puszczamy reset
        rst_n = 1'b1;
        
        repeat(20) @(negedge clk);
        
        // Użytkownik klika przycisk myszy
        $display("INFO: Swobodne spadanie.");
        mouse_left = 1'b1;

        // Czekamy 2 pełne sekundy
        #2_000_000; 
        
        $display("INFO: Symulacja zakoczona.");
        $finish;
    end

endmodule
`timescale 1ns / 1ps

module draw_rect_ctl_tb;
    logic clk = 0;
    logic rst_n, mouse_left;
    logic [11:0] mouse_xpos, mouse_ypos, xpos, ypos;

    always #12.5 clk = ~clk;

    draw_rect_ctl_prog u_prog (.*);
    draw_rect_ctl #(
        .TICK_LIMIT(666) // 1000x szybciej
    ) u_dut (.*);

    int file_handle;
    initial begin
        file_handle = $fopen("bouncing_log.csv", "w");
        $fdisplay(file_handle, "Time_ns, Y_Pos");
        $timeformat(-9, 0, "", 0);

        @(posedge rst_n); // Czekaj na koniec resetu
        $fmonitor(file_handle, "%0t, %0d", $time, ypos);
    end

    final begin
        if (file_handle) $fclose(file_handle);
    end
endmodule
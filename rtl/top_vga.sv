`timescale 1ns / 1ps

module top_vga ( 
    input  logic clk,        // 40 MHz pixel clock
    input  logic clk100MHz,  // 100 MHz system clock
    input  logic rst_n,      
    inout  wire  ps2_clk, 
    inout  wire  ps2_data, 
    output logic vs, 
    output logic hs, 
    output logic [3:0] r, 
    output logic [3:0] g, 
    output logic [3:0] b 
);
    timeunit 1ns; 
    timeprecision 1ps; 

    import vga_pkg::*; 

    // Sygnały myszy i śluzy CDC
    wire [11:0] mouse_x_raw, mouse_y_raw;
    logic [11:0] mouse_x_sync1, mouse_x_sync2; 
    logic [11:0] mouse_y_sync1, mouse_y_sync2; 

    wire mouse_right_raw;
    logic mouse_right_sync1, mouse_right_sync2; 

    // Przejście z domeny 100MHz (mysz) do 40MHz (piksele)
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            mouse_x_sync1 <= '0; mouse_x_sync2 <= '0; 
            mouse_y_sync1 <= '0; mouse_y_sync2 <= '0; 
            mouse_right_sync1 <= '0; mouse_right_sync2 <= '0;
        end else begin 
            mouse_x_sync1 <= mouse_x_raw; 
            mouse_x_sync2 <= mouse_x_sync1; 
            
            mouse_y_sync1 <= mouse_y_raw; 
            mouse_y_sync2 <= mouse_y_sync1; 
             
            mouse_right_sync1 <= mouse_right_raw; 
            mouse_right_sync2 <= mouse_right_sync1;
        end 
    end 

    // Inicjalizacja limitów myszki
    typedef enum logic [2:0] {
        ST_INIT_START, ST_SET_X, ST_WAIT_X, ST_SET_Y, ST_WAIT_Y, ST_DONE
    } MOUSE_CFG_STATE_E;

    MOUSE_CFG_STATE_E m_state, m_state_nxt;
    logic [11:0] m_cfg_val, m_cfg_val_nxt;
    logic m_set_x, m_set_x_nxt;
    logic m_set_y, m_set_y_nxt;

    always_ff @(posedge clk100MHz or negedge rst_n) begin
        if (!rst_n) begin
            m_state <= ST_INIT_START; m_set_x <= 1'b0; m_set_y <= 1'b0; m_cfg_val <= 12'd0;
        end else begin
            m_state <= m_state_nxt; m_set_x <= m_set_x_nxt; m_set_y <= m_set_y_nxt; m_cfg_val <= m_cfg_val_nxt;
        end
    end

    always_comb begin
        m_state_nxt = m_state; m_set_x_nxt = m_set_x; m_set_y_nxt = m_set_y; m_cfg_val_nxt = m_cfg_val;
        case (m_state)
            ST_INIT_START: m_state_nxt = ST_SET_X;
            ST_SET_X: begin m_cfg_val_nxt = 12'd799; m_set_x_nxt = 1'b1; m_state_nxt = ST_WAIT_X; end
            ST_WAIT_X: begin m_set_x_nxt = 1'b0; m_state_nxt = ST_SET_Y; end
            ST_SET_Y: begin m_cfg_val_nxt = 12'd599; m_set_y_nxt = 1'b1; m_state_nxt = ST_WAIT_Y; end
            ST_WAIT_Y: begin m_set_y_nxt = 1'b0; m_state_nxt = ST_DONE; end
            ST_DONE: begin m_set_x_nxt = 1'b0; m_set_y_nxt = 1'b0; end
            default: m_state_nxt = ST_INIT_START;
        endcase
    end

    // Kontroler myszy
    MouseCtl u_mouse_ctl ( 
        .clk      (clk100MHz), 
        .rst      (!rst_n), 
        .ps2_clk  (ps2_clk), 
        .ps2_data (ps2_data), 
        .xpos     (mouse_x_raw), 
        .ypos     (mouse_y_raw), 
        .right    (mouse_right_raw),
        .value    (m_cfg_val),    
        .setmax_x (m_set_x),   
        .setmax_y (m_set_y),   
        .setx(1'b0), .sety(1'b0), 
        .zpos(), .middle(), .left(), .new_event() 
    );

    // Potok VGA
    vga_if timing_to_render(); 
    vga_if render_to_mouse();  
    vga_if mouse_to_out();

    assign vs = mouse_to_out.vsync; 
    assign hs = mouse_to_out.hsync; 
    assign {r, g, b} = mouse_to_out.rgb;

    // Generacja sygnałów HSYNC, VSYNC
    vga_timing u_vga_timing ( 
        .clk   (clk), 
        .rst_n (rst_n), 
        .out   (timing_to_render.out) 
    );

    // FIZYKA GRACZA
    logic [11:0] player_x, player_y; 
    
    draw_rect_ctl u_draw_rect_ctl ( 
        .clk         (clk), 
        .rst_n       (rst_n), 
        .mouse_right (mouse_right_sync2), // Zsynchronizowany sygnał PPM
        .mouse_xpos  (mouse_x_sync2),    
        .mouse_ypos  (mouse_y_sync2),  
        .vsync       (timing_to_render.vsync), // Przekazujemy VSYNC dla płynności ruchu!  
        .xpos        (player_x),        
        .ypos        (player_y)         
    );

    // Rysowanie gracza
    localparam PLAYER_SIZE = 12'd32;

    always_comb begin
        // Przekazanie sygnałów sterujących dalej
        render_to_mouse.vcount = timing_to_render.vcount;
        render_to_mouse.hcount = timing_to_render.hcount;
        render_to_mouse.vsync  = timing_to_render.vsync;
        render_to_mouse.hsync  = timing_to_render.hsync;
        render_to_mouse.vblnk  = timing_to_render.vblnk;
        render_to_mouse.hblnk  = timing_to_render.hblnk;
        
        // Tło
        render_to_mouse.rgb = 12'h222; 

        // Rysowanie gracza na zielono
        if (timing_to_render.hcount >= player_x && timing_to_render.hcount < player_x + PLAYER_SIZE &&
            timing_to_render.vcount >= player_y && timing_to_render.vcount < player_y + PLAYER_SIZE) begin
            render_to_mouse.rgb = 12'h0F0; 
        end
    end

    // Kursor myszy na wierzchu
    draw_mouse u_draw_mouse ( 
        .clk   (clk), 
        .rst_n (rst_n), 
        .xpos  (mouse_x_sync2),
        .ypos  (mouse_y_sync2), 
        .in    (render_to_mouse.in), 
        .out   (mouse_to_out.out) 
    );

endmodule
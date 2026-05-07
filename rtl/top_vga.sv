/**
 * Copyright (C) 2026  AGH University of Science and Technology
 * MTM UEC2
 * * Description:
 * Top level VGA module with integrated CDC, Shift-Register Debouncer,
 * and robust Mouse initialization FSM.
 */

 `timescale 1ns / 1ps

 module top_vga ( 
     input  logic clk,        // 40 MHz pixel clock
     input  logic clk100MHz,  // 100 MHz system clock
     input  logic rst_n,      // Asynchronous reset button (active low)
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
 
     // SYGNAŁY MYSZY I ŚLUZA CDC 
     wire [11:0] mouse_x_raw, mouse_y_raw; 
     logic [11:0] mouse_x_sync1, mouse_x_sync2; 
     logic [11:0] mouse_y_sync1, mouse_y_sync2; 
 
     wire mouse_left_raw; 
     logic mouse_left_sync1, mouse_left_sync2; 
 
     // Przejście z domeny 100MHz (mysz) do 40MHz (piksele i fizyka)
     always_ff @(posedge clk or negedge rst_n) begin 
         if (!rst_n) begin 
             mouse_x_sync1 <= '0; mouse_x_sync2 <= '0; 
             mouse_y_sync1 <= '0; mouse_y_sync2 <= '0; 
             mouse_left_sync1 <= '0; mouse_left_sync2 <= '0; 
         end else begin 
             mouse_x_sync1 <= mouse_x_raw; 
             mouse_x_sync2 <= mouse_x_sync1; 
             
             mouse_y_sync1 <= mouse_y_raw; 
             mouse_y_sync2 <= mouse_y_sync1; 
              
             mouse_left_sync1 <= mouse_left_raw; 
             mouse_left_sync2 <= mouse_left_sync1; 
         end 
     end 
 
     // SHIFT-REGISTER DEBOUNCER 
     logic [15:0] tick_1ms_cnt; 
     logic tick_1ms;
 
     // Generator tiku co 1 ms (dla zegara 40 MHz: 40 MHz / 1 kHz = 40 000 taktów)
     always_ff @(posedge clk or negedge rst_n) begin
         if (!rst_n) begin
             tick_1ms_cnt <= '0;
             tick_1ms <= 1'b0;
         end else begin
             if (tick_1ms_cnt == 16'd39_999) begin
                 tick_1ms_cnt <= '0;
                 tick_1ms <= 1'b1;
             end else begin
                 tick_1ms_cnt <= tick_1ms_cnt + 1'b1;
                 tick_1ms <= 1'b0;
             end
         end
     end
 
     logic [7:0] shift_reg;
     logic mouse_left_clean;
 
     // Właściwy rejestr przesuwny
     always_ff @(posedge clk or negedge rst_n) begin
         if (!rst_n) begin
             shift_reg <= '0;
             mouse_left_clean <= 1'b0;
         end else if (tick_1ms) begin 
             // Przesuwamy o jedną pozycję i wpisujemy nowy stan wejścia
             shift_reg <= {shift_reg[6:0], mouse_left_sync2};
 
             // 16 jedynek lub 16 zer z rzędu
             if ({shift_reg[6:0], mouse_left_sync2} == 8'b1111_1111) begin
                 mouse_left_clean <= 1'b1; 
             end 
             else if ({shift_reg[6:0], mouse_left_sync2} == 8'b0000_0000) begin
                 mouse_left_clean <= 1'b0; 
             end
         end
     end
 
     // INICJALIZACJA LIMITÓW
    
    typedef enum logic [2:0] {
        ST_INIT_START,
        ST_SET_X,
        ST_WAIT_X,
        ST_SET_Y,
        ST_WAIT_Y,
        ST_DONE
    } MOUSE_CFG_STATE_E;

    MOUSE_CFG_STATE_E m_state, m_state_nxt;
    logic [11:0] m_cfg_val, m_cfg_val_nxt;
    logic m_set_x, m_set_x_nxt;
    logic m_set_y, m_set_y_nxt;

    always_ff @(posedge clk100MHz or negedge rst_n) begin
        if (!rst_n) begin
            m_state   <= ST_INIT_START;
            m_set_x   <= 1'b0;
            m_set_y   <= 1'b0;
            m_cfg_val <= 12'd0;
        end else begin
            m_state   <= m_state_nxt;
            m_set_x   <= m_set_x_nxt;
            m_set_y   <= m_set_y_nxt;
            m_cfg_val <= m_cfg_val_nxt;
        end
    end

    always_comb begin
        m_state_nxt   = m_state;
        m_set_x_nxt   = m_set_x;
        m_set_y_nxt   = m_set_y;
        m_cfg_val_nxt = m_cfg_val;

        case (m_state)
            ST_INIT_START: begin
                m_state_nxt = ST_SET_X;
            end
            ST_SET_X: begin
                m_cfg_val_nxt = 12'd799;
                m_set_x_nxt   = 1'b1;
                m_state_nxt   = ST_WAIT_X;
            end
            ST_WAIT_X: begin
                m_set_x_nxt   = 1'b0;
                m_state_nxt   = ST_SET_Y;
            end
            ST_SET_Y: begin
                m_cfg_val_nxt = 12'd599;
                m_set_y_nxt   = 1'b1;
                m_state_nxt   = ST_WAIT_Y;
            end
            ST_WAIT_Y: begin
                m_set_y_nxt   = 1'b0;
                m_state_nxt   = ST_DONE;
            end
            ST_DONE: begin
                m_set_x_nxt   = 1'b0;
                m_set_y_nxt   = 1'b0;
            end
            default: begin
                m_state_nxt = ST_INIT_START;
            end
        endcase
    end
 
     // Instancja sterownika myszy z VHDL
     MouseCtl u_mouse_ctl ( 
         .clk      (clk100MHz), 
         .rst      (!rst_n), 
         .ps2_clk  (ps2_clk), 
         .ps2_data (ps2_data), 
         .xpos     (mouse_x_raw), 
         .ypos     (mouse_y_raw), 
         .left     (mouse_left_raw), 
          
         .value    (m_cfg_val),    
         .setmax_x (m_set_x),   
         .setmax_y (m_set_y),   
          
         .setx(1'b0), .sety(1'b0), 
         .zpos(), .middle(), .right(), .new_event() 
     ); 
 
     // POTOK VGA
     vga_if timing_to_bg(); 
     vga_if bg_to_char(); 
     vga_if char_to_rect();  
     vga_if rect_to_mouse();  
     vga_if mouse_to_out(); 
 
     assign vs = mouse_to_out.vsync; 
     assign hs = mouse_to_out.hsync; 
     assign {r, g, b} = mouse_to_out.rgb; 
 
     // Timing (Generacja sygnałów HSYNC, VSYNC)
     vga_timing u_vga_timing ( 
         .clk   (clk), 
         .rst_n (rst_n), 
         .out   (timing_to_bg.out) 
     ); 
 
     // Tło (Inicjały i ramki)
     draw_bg u_draw_bg ( 
         .clk   (clk), 
         .rst_n (rst_n), 
         .in    (timing_to_bg.in), 
         .out   (bg_to_char.out) 
     ); 
     
     logic [7:0] char_xy;
     logic [3:0] char_line;
     logic [6:0] char_code;
     logic [7:0] char_pixels;

     // Sterownik obszaru tekstowego (wylicza adresy i opóźnia sygnały VGA)
     draw_rect_char #(  
        .RECT_X_POS(64),
        .RECT_Y_POS(64)
     ) u_draw_rect_char (
         .clk         (clk),
         .rst_n       (rst_n),
         .in          (bg_to_char.in),
         .out         (char_to_rect.out),
         .char_xy     (char_xy),
         .char_line   (char_line),
         .char_pixels (char_pixels)
     );

     // Pamięć ROM z treścią tekstu (Krok 2)
     char_rom u_char_rom (
         .clk       (clk),
         .addr      (char_xy),
         .char_code (char_code)
     );

     // Pamięć ROM z pikselami czcionki
     font_rom u_font_rom (
         .clk              (clk),
         .addr             ({char_code, char_line}),
         .char_line_pixels (char_pixels)
     );
 
     // Fizyka opadającego loga AGH 
     logic [11:0] rect_xpos, rect_ypos; 
     logic [11:0] rom_addr; 
     logic [11:0] rom_rgb; 
 
     draw_rect_ctl u_draw_rect_ctl ( 
         .clk        (clk), 
         .rst_n      (rst_n), 
         .mouse_left (mouse_left_clean),
         .mouse_xpos (mouse_x_sync2),    
         .mouse_ypos (mouse_y_sync2),    
         .xpos       (rect_xpos),        
         .ypos       (rect_ypos)         
     ); 
 
     // Moduł rysujący logo (Zarządza adresowaniem ROM)
     draw_rect u_draw_rect ( 
         .clk        (clk), 
         .rst_n      (rst_n), 
         .xpos       (rect_xpos), 
         .ypos       (rect_ypos), 
         .in         (char_to_rect.in), 
         .out        (rect_to_mouse.out), 
         .pixel_addr (rom_addr), 
         .rgb_pixel  (rom_rgb) 
     ); 
 
     // Kursor myszy na wierzchu
     draw_mouse u_draw_mouse ( 
         .clk   (clk), 
         .rst_n (rst_n), 
         .xpos  (mouse_x_sync2), 
         .ypos  (mouse_y_sync2), 
         .in    (rect_to_mouse.in), 
         .out   (mouse_to_out.out) 
     ); 
 
     // Pamięć ze sprite'em logo
     image_rom u_image_rom ( 
         .clk     (clk), 
         .address (rom_addr), 
         .rgb     (rom_rgb) 
     ); 
 
 endmodule
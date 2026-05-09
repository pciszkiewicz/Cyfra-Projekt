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

    // ==========================================
    // 1. SYGNAŁY I CDC (Twoja oryginalna logika)
    // ==========================================
    wire [11:0] mouse_x_raw, mouse_y_raw;
    logic [11:0] mouse_x_sync1, mouse_x_sync2;
    logic [11:0] mouse_y_sync1, mouse_y_sync2; 

    wire mouse_right_raw;
    logic mouse_right_sync1, mouse_right_sync2; 
    
    wire mouse_left_raw;
    logic mouse_left_sync1, mouse_left_sync2; 

    // Przejście z domeny 100MHz (mysz) do 40MHz (piksele)
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            mouse_x_sync1 <= '0; mouse_x_sync2 <= '0; 
            mouse_y_sync1 <= '0; mouse_y_sync2 <= '0; 
            mouse_right_sync1 <= '0; mouse_right_sync2 <= '0;
            mouse_left_sync1 <= '0; mouse_left_sync2 <= '0;
        end else begin 
            mouse_x_sync1 <= mouse_x_raw; mouse_x_sync2 <= mouse_x_sync1; 
            mouse_y_sync1 <= mouse_y_raw; mouse_y_sync2 <= mouse_y_sync1; 
            mouse_right_sync1 <= mouse_right_raw; mouse_right_sync2 <= mouse_right_sync1;
            mouse_left_sync1 <= mouse_left_raw; mouse_left_sync2 <= mouse_left_sync1;
        end 
    end 

    // ==========================================
    // 2. MASZYNA STANÓW MYSZY (Twoja oryginalna logika)
    // ==========================================
    typedef enum logic [2:0] {
        ST_INIT_START, ST_SET_X, ST_WAIT_X, ST_SET_Y, ST_WAIT_Y, ST_DONE
    } MOUSE_CFG_STATE_E;

    MOUSE_CFG_STATE_E m_state, m_state_nxt;
    logic [11:0] m_cfg_val, m_cfg_val_nxt;
    logic m_set_x, m_set_x_nxt;
    logic m_set_y, m_set_y_nxt;

    always_ff @(posedge clk100MHz or negedge rst_n) begin
        if (!rst_n) begin
            m_state <= ST_INIT_START;
            m_set_x <= 1'b0; m_set_y <= 1'b0; m_cfg_val <= 12'd0;
        end else begin
            m_state <= m_state_nxt;
            m_set_x <= m_set_x_nxt; m_set_y <= m_set_y_nxt; m_cfg_val <= m_cfg_val_nxt;
        end
    end

    always_comb begin
        m_state_nxt = m_state;
        m_set_x_nxt = m_set_x; m_set_y_nxt = m_set_y; m_cfg_val_nxt = m_cfg_val;
        case (m_state)
            ST_INIT_START: m_state_nxt = ST_SET_X;
            ST_SET_X: begin m_cfg_val_nxt = 12'd1023; m_set_x_nxt = 1'b1; m_state_nxt = ST_WAIT_X; end
            ST_WAIT_X: begin m_set_x_nxt = 1'b0; m_state_nxt = ST_SET_Y; end
            ST_SET_Y: begin m_cfg_val_nxt = 12'd767; m_set_y_nxt = 1'b1; m_state_nxt = ST_WAIT_Y; end
            ST_WAIT_Y: begin m_set_y_nxt = 1'b0; m_state_nxt = ST_DONE; end
            ST_DONE: begin m_set_x_nxt = 1'b0; m_set_y_nxt = 1'b0; end
            default: m_state_nxt = ST_INIT_START;
        endcase
    end

    MouseCtl u_mouse_ctl ( 
        .clk      (clk100MHz), 
        .rst      (!rst_n), 
        .ps2_clk  (ps2_clk), 
        .ps2_data (ps2_data), 
        .xpos     (mouse_x_raw), 
        .ypos     (mouse_y_raw), 
        .right    (mouse_right_raw),
        .left     (mouse_left_raw),
        .value    (m_cfg_val),    
        .setmax_x (m_set_x),   
        .setmax_y (m_set_y),   
        .setx(1'b0), .sety(1'b0), 
        .zpos(), .middle(), .new_event() 
    );

    // ==========================================
    // 3. LOGIKA GRY (Nowe moduły, podpięte bezpiecznie)
    // ==========================================
    logic [31:0] active_crates;
    logic [1:0]  current_state;
    logic [11:0] player_x, player_y;
    logic [9:0]  map_addr;
    logic        is_wall;

    game_logic_top u_game_logic (
        .clk(clk),
        .rst(!rst_n),
        .start_btn(mouse_left_sync2), // LPM startuje grę
        .phase_timeout(1'b0),
        .crates_hit_mask(32'b0),
        .active_crates(active_crates),
        .current_state(current_state)
    );

    player_ctl u_player_ctl (
        .clk(clk),
        .rst(!rst_n),
        .frame_tick(timing_to_render.vsync && !timing_to_render.vblnk), 
        .mouse_x(mouse_x_sync2[9:0]),
        .mouse_y(mouse_y_sync2[9:0]),
        .mouse_rmb(mouse_right_sync2), 
        .player_x(player_x),
        .player_y(player_y)
    );

    map_rom u_map_rom (
        .clk(clk),
        .addr(map_addr),
        .is_wall(is_wall)
    );

    // ==========================================
    // 4. POTOK VGA (Zgodny z Twoim labem)
    // ==========================================
    vga_if timing_to_render(); 
    vga_if render_to_mouse();  
    vga_if mouse_to_out();

    assign vs = mouse_to_out.vsync; 
    assign hs = mouse_to_out.hsync;
    assign {r, g, b} = mouse_to_out.rgb;

    vga_timing u_vga_timing ( 
        .clk   (clk), 
        .rst_n (rst_n), 
        .out   (timing_to_render.out) 
    );

    // Rysowanie mapy (zastępuje Twój stary blok always_comb z graczem na zielono)
    draw_map u_draw_map (
        .clk(clk),
        .rst(!rst_n),
        .in(timing_to_render.in),
        .out(render_to_mouse.out),
        .player_x(player_x),
        .player_y(player_y),
        .map_addr(map_addr),
        .is_wall(is_wall)
    );

    draw_mouse u_draw_mouse ( 
        .clk   (clk), 
        .rst_n (rst_n), 
        .xpos  (mouse_x_sync2),
        .ypos  (mouse_y_sync2), 
        .in    (render_to_mouse.in), 
        .out   (mouse_to_out.out) 
    );

endmodule
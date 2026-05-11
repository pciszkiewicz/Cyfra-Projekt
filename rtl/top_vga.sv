/**
 * Autorzy:
 * Opis: Główny moduł strukturalny projektu (top_vga). 
 * Odpowiada za integrację kontrolerów, logiki gry oraz potoku wyświetlania VGA.
 */

 module top_vga (
    input  logic clk,              /* Zegar pikseli 40 MHz */
    input  logic clk100MHz,        /* Zegar systemowy 100 MHz */
    input  logic rst_pclk,         /* Reset synchroniczny dla domeny 40 MHz */
    input  logic rst_100m,         /* Reset synchroniczny dla domeny 100 MHz */
    inout  wire  ps2_clk,          /* Linie interfejsu PS/2 */
    inout  wire  ps2_data,
    output logic vs,               /* Wyjścia VGA synchronizacja pionowa */
    output logic hs,               /* Wyjścia VGA synchronizacja pozioma */
    output logic [3:0] r,          /* Wyjścia VGA kolory R, G, B */
    output logic [3:0] g,
    output logic [3:0] b
);

    import vga_pkg::*;             /* Import stałych z pakietu */

    /* Definicje typów i stałych lokalnych */
    typedef enum logic [2:0] {
        ST_INIT_START, 
        ST_SET_X, 
        ST_WAIT_X, 
        ST_SET_Y, 
        ST_WAIT_Y, 
        ST_DONE
    } mouse_cfg_state_t;           /* Sufiks _t dla typów */

    /* Sygnały lokalne i interfejsy */
    wire [11:0]  mouse_x_raw, mouse_y_raw;
    wire         mouse_right_raw, mouse_left_raw;

    logic [11:0] mouse_x_sync1, mouse_x_sync2;
    logic [11:0] mouse_y_sync1, mouse_y_sync2;
    logic        mouse_right_sync1, mouse_right_sync2;
    logic        mouse_left_sync1, mouse_left_sync2;

    mouse_cfg_state_t m_state, m_state_nxt;
    logic [11:0] m_cfg_val, m_cfg_val_nxt;
    logic        m_set_x, m_set_x_nxt;
    logic        m_set_y, m_set_y_nxt;

    logic [31:0] active_crates;
    logic [1:0]  current_state;
    logic [11:0] player_x, player_y;
    logic [9:0]  map_addr;
    logic        is_wall;

    vga_if timing_to_render();     /* Interfejsy VGA */
    vga_if render_to_mouse();
    vga_if mouse_to_out();


    /* Przypisania wyjść */
    assign vs = mouse_to_out.vsync;
    assign hs = mouse_to_out.hsync;
    assign {r, g, b} = mouse_to_out.rgb;


    /* CDC - Synchronizacja sygnałów myszy (z domeny 100MHz do 40MHz) */
    always_ff @(posedge clk) begin
        if (rst_pclk) begin
            mouse_x_sync1     <= '0;
            mouse_x_sync2     <= '0;
            mouse_y_sync1     <= '0;
            mouse_y_sync2     <= '0;
            mouse_right_sync1 <= '0;
            mouse_right_sync2 <= '0;
            mouse_left_sync1  <= '0;
            mouse_left_sync2  <= '0;
        end else begin
            mouse_x_sync1     <= mouse_x_raw;
            mouse_x_sync2     <= mouse_x_sync1;
            mouse_y_sync1     <= mouse_y_raw;
            mouse_y_sync2     <= mouse_y_sync1;
            mouse_right_sync1 <= mouse_right_raw;
            mouse_right_sync2 <= mouse_right_sync1;
            mouse_left_sync1  <= mouse_left_raw;
            mouse_left_sync2  <= mouse_left_sync1;
        end
    end


    /* Logika konfiguracji myszy (Domena 100 MHz) */
    always_ff @(posedge clk100MHz) begin
        if (rst_100m) begin
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
        m_set_x_nxt   = 1'b0;
        m_set_y_nxt   = 1'b0;
        m_cfg_val_nxt = m_cfg_val;

        case (m_state)
            ST_INIT_START: m_state_nxt = ST_SET_X;
            
            ST_SET_X: begin
                m_cfg_val_nxt = MOUSE_MAX_X;
                m_set_x_nxt   = 1'b1;
                m_state_nxt   = ST_WAIT_X;
            end
            
            ST_WAIT_X: m_state_nxt = ST_SET_Y;
            
            ST_SET_Y: begin
                m_cfg_val_nxt = MOUSE_MAX_Y;
                m_set_y_nxt   = 1'b1;
                m_state_nxt   = ST_WAIT_Y;
            end
            
            ST_WAIT_Y: m_state_nxt = ST_DONE;
            
            ST_DONE:   /* Konfiguracja zakończona */;
            
            default: m_state_nxt = ST_INIT_START;
        endcase
    end


    /* Instancje modułów */

    /* Kontroler myszy (VHDL) */
    MouseCtl u_mouse_ctl (
        .clk      (clk100MHz),
        .rst      (rst_100m),
        .ps2_clk  (ps2_clk),
        .ps2_data (ps2_data),
        .xpos     (mouse_x_raw),
        .ypos     (mouse_y_raw),
        .right    (mouse_right_raw),
        .left     (mouse_left_raw),
        .value    (m_cfg_val),
        .setmax_x (m_set_x),
        .setmax_y (m_set_y),
        .setx     (1'b0),
        .sety     (1'b0),
        .zpos     (),
        .middle   (),
        .new_event()
    );

    /* Główna logika gry */
    game_logic_top u_game_logic (
        .clk             (clk),
        .rst             (rst_pclk),
        .start_btn       (mouse_left_sync2),
        .phase_timeout   (1'b0),
        .crates_hit_mask (32'b0),
        .active_crates   (active_crates),
        .current_state   (current_state)
    );

    /* Kontroler ruchu gracza */
    player_ctl u_player_ctl (
        .clk        (clk),
        .rst        (rst_pclk),
        .frame_tick (timing_to_render.vsync && !timing_to_render.vblnk),
        .mouse_x    (mouse_x_sync2[9:0]),
        .mouse_y    (mouse_y_sync2[9:0]),
        .mouse_rmb  (mouse_right_sync2),
        .is_wall    (is_wall),
        .map_addr   (map_addr),
        .player_x   (player_x),
        .player_y   (player_y)
    );

    /* Pamięć ścian mapy */
    map_rom u_map_rom (
        .clk     (clk),
        .addr    (map_addr),
        .is_wall (is_wall)
    );


    /* Potok wyświetlania VGA */

    vga_timing u_vga_timing (
        .clk   (clk),
        .rst   (rst_pclk),
        .out   (timing_to_render.out)
    );

    draw_map u_draw_map (
        .clk      (clk),
        .rst      (rst_pclk),
        .in       (timing_to_render.in),
        .out      (render_to_mouse.out),
        .player_x (player_x),
        .player_y (player_y),
        .is_wall  (is_wall),
        .map_addr () /* Adres wystawiany jest w player_ctl */
    );

    draw_mouse u_draw_mouse (
        .clk   (clk),
        .rst   (rst_pclk),
        .xpos  (mouse_x_sync2),
        .ypos  (mouse_y_sync2),
        .in    (render_to_mouse.in),
        .out   (mouse_to_out.out)
    );

endmodule
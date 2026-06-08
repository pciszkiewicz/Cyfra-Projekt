/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz, Tomasz Jesionek
 *
 * Description:
 * Top VGA structural module.
 * Integrates Multiplayer (UART), FSM, 
 * Combat Logic, and fully debounced Mouse control with asynchronous resets.
 * Hardware-independent RTL (Clock generation is external).
 */

 `timescale 1ns / 1ps

 module top_vga
     import vga_pkg::*;
     (
         input  logic       clk_65MHz,
         input  logic       clk_100MHz,
         
         input  logic       rst_sys_n,
         input  logic       rst_100m_n,
         
         output logic       vs,
         output logic       hs,
         output logic [3:0] r,
         output logic [3:0] g,
         output logic [3:0] b,
         inout  wire        ps2_clk,
         inout  wire        ps2_data,
         
         // Komunikacja Multiplayer przez złącza PMOD
         input  logic       uart_rx,
         output logic       uart_tx
     );

     // =========================================================================
     // INTERFEJSY KASKADY RENDEROWANIA VGA (Pipeline)
     // =========================================================================
     vga_if timing_to_map();
     vga_if map_to_crates();
     vga_if crates_to_entities();
     vga_if entities_to_hud();
     vga_if hud_to_start();
     vga_if start_to_char();
     vga_if char_to_mouse();
     vga_if mouse_to_out();
 
     assign vs = mouse_to_out.vsync;
     assign hs = mouse_to_out.hsync;
     assign {r, g, b} = mouse_to_out.rgb;

     // Generator ticku 60Hz z VSYNC (do optymalizacji odświeżania logiki)
     logic vsync_reg;
     always_ff @(posedge clk_65MHz or negedge rst_sys_n) begin
         if (!rst_sys_n) vsync_reg <= 1'b0;
         else            vsync_reg <= timing_to_map.vsync;
     end
     wire logic_tick_60hz = timing_to_map.vsync & ~vsync_reg;

     // =========================================================================
     // SYNCHRONIZACJA I OBSŁUGA MYSZY (POPRAWA CDC)
     // =========================================================================
     logic [11:0] mouse_x_raw, mouse_y_raw;
     logic        mouse_right_raw, mouse_left_raw;
     logic        mouse_new_event;

     // Toggle Synchronizer (Przejście sygnału gotowości ze 100MHz na 65MHz)
     logic mouse_toggle_100;
     always_ff @(posedge clk_100MHz or negedge rst_100m_n) begin
         if (!rst_100m_n) mouse_toggle_100 <= 1'b0;
         else if (mouse_new_event) mouse_toggle_100 <= ~mouse_toggle_100;
     end

     (* ASYNC_REG = "TRUE" *) logic t_sync1, t_sync2, t_sync3;
     always_ff @(posedge clk_65MHz or negedge rst_sys_n) begin
         if (!rst_sys_n) {t_sync3, t_sync2, t_sync1} <= 3'b0;
         else            {t_sync3, t_sync2, t_sync1} <= {t_sync2, t_sync1, mouse_toggle_100};
     end

     // Odtworzenie jednocylkowego impulsu w domenie 65 MHz
     logic mouse_event_65MHz;
     assign mouse_event_65MHz = t_sync2 ^ t_sync3;

     // Właściwe, zsynchronizowane rejestry wyjściowe
     logic [11:0] mouse_x_sync2;
     logic [11:0] mouse_y_sync2;
     logic        mouse_right_sync2;
     logic        mouse_left_sync2;

     // Zatrzaskiwanie wektorów współrzędnych TYLKO w momencie poprawności danych
     always_ff @(posedge clk_65MHz or negedge rst_sys_n) begin
         if (!rst_sys_n) begin
             mouse_x_sync2     <= 12'h0;
             mouse_y_sync2     <= 12'h0;
             mouse_right_sync2 <= 1'b0;
             mouse_left_sync2  <= 1'b0;
         end else if (mouse_event_65MHz) begin
             mouse_x_sync2     <= mouse_x_raw;
             mouse_y_sync2     <= mouse_y_raw;
             mouse_right_sync2 <= mouse_right_raw;
             mouse_left_sync2  <= mouse_left_raw;
         end
     end
 
     // FSM konfigurująca granice (limity ekranu) dla układu myszy
     typedef enum logic [2:0] {
         ST_INIT_START = 3'd0,
         ST_SET_X      = 3'd1,
         ST_WAIT_X     = 3'd2,
         ST_SET_Y      = 3'd3,
         ST_WAIT_Y     = 3'd4,
         ST_DONE       = 3'd5
     } mouse_cfg_state_t;

     mouse_cfg_state_t m_state, m_state_nxt;
     logic [11:0] m_cfg_val, m_cfg_val_nxt;
     logic        m_set_x, m_set_x_nxt;
     logic        m_set_y, m_set_y_nxt;

     always_ff @(posedge clk_100MHz or negedge rst_100m_n) begin
         if (!rst_100m_n) begin
             m_state   <= ST_INIT_START;
             m_set_x   <= 1'b0;
             m_set_y   <= 1'b0;
             m_cfg_val <= 12'h0;
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
                 m_cfg_val_nxt = 12'd1023; // Max X ekranu VGA
                 m_set_x_nxt   = 1'b1;
                 m_state_nxt   = ST_WAIT_X;
             end
             ST_WAIT_X: m_state_nxt = ST_SET_Y;
             ST_SET_Y: begin
                 m_cfg_val_nxt = 12'd767; // Max Y ekranu VGA
                 m_set_y_nxt   = 1'b1;
                 m_state_nxt   = ST_WAIT_Y;
             end
             ST_WAIT_Y: m_state_nxt = ST_DONE;
             ST_DONE:   m_state_nxt = ST_DONE;
             default:   m_state_nxt = ST_INIT_START;
         endcase
     end
 
     MouseCtl u_mouse_ctl (
         .clk(clk_100MHz),
         .rst(~rst_100m_n), // MouseCtl zazwyczaj jest aktywny wysokim stanem resetu
         .ps2_clk(ps2_clk),
         .ps2_data(ps2_data),
         .xpos(mouse_x_raw),
         .ypos(mouse_y_raw),
         .right(mouse_right_raw),
         .left(mouse_left_raw),
         .value(m_cfg_val),
         .setmax_x(m_set_x),
         .setmax_y(m_set_y),
         .setx(1'b0),
         .sety(1'b0),
         .zpos(),
         .middle(),
         .new_event(mouse_new_event) // Podpięto sygnał CDC
     );

     // =========================================================================
     // GLOBALNE SYGNAŁY I LOGIKA GRY (Game Logic & Combat)
     // =========================================================================
     logic [2:0]  current_state;
     logic [31:0] active_crates, active_loot;
     
     logic [15:0] my_world_x, my_world_y;
     logic [7:0]  my_hp;
     logic [7:0]  my_dmg;
     logic        my_dead;
     logic [1:0]  class_id;
     logic        char_select_btn;
     
     logic [15:0] enemy_world_x, enemy_world_y;
     logic [7:0]  enemy_hp;

     logic [15:0] my_bullet_x, my_bullet_y;
     logic        my_bullet_active;
     logic [7:0]  my_bullet_dmg;

     logic        rx_take_dmg_en;
     logic [7:0]  rx_take_dmg_val;

     logic        hit_enemy, hit_wall;
     
     logic [13:0] map_addr_vga; 
     logic        is_wall_vga;
     logic [13:0] map_addr_collision;
     logic        is_wall_collision;

     // Odmierzanie czasu fazy Lootingu
     logic [9:0] loot_timer_reg;
     logic       phase_timeout;

     // =========================================================================
     // DETEKTORY ZBOCZA
     // =========================================================================
     logic mouse_lmb_pulse;
     logic mouse_rmb_pulse;
     logic rx_take_dmg_pulse; 

     edge_detector u_lmb_edge (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .in_signal(mouse_left_sync2),
         .out_pulse(mouse_lmb_pulse)
     );

     edge_detector u_rmb_edge (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .in_signal(mouse_right_sync2),
         .out_pulse(mouse_rmb_pulse)
     );

     edge_detector u_dmg_edge (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .in_signal(rx_take_dmg_en),
         .out_pulse(rx_take_dmg_pulse)
     );

     // =========================================================================
     // INSTANCJE LOGIKI GRY
     // =========================================================================
     always_ff @(posedge clk_65MHz or negedge rst_sys_n) begin
         if (!rst_sys_n) begin
             loot_timer_reg <= 10'd0;
         end else begin
             if (current_state == 3'd2) begin // ST_LOOTING
                 if (logic_tick_60hz && loot_timer_reg < 10'd600)
                     loot_timer_reg <= loot_timer_reg + 1;
             end else begin
                 loot_timer_reg <= 10'd0;
             end
         end
     end

     assign phase_timeout = (loot_timer_reg >= 10'd600);

     game_logic_top u_game_logic (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .active_crates(active_crates),
         .active_loot(active_loot),
         .current_state(current_state),
         .start_btn(mouse_lmb_pulse && (current_state == 3'd0 || current_state == 3'd4)), 
         .char_select_btn(char_select_btn), 
         .phase_timeout(phase_timeout),
         .crates_hit_mask(32'h0),
         .loot_collected_mask(32'h0),
         .p1_dead(my_dead),
         .p2_dead(enemy_hp == 8'd0)
     );

     player_ctl u_player_ctl (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .mouse_x(mouse_x_sync2),
         .mouse_y(mouse_y_sync2),
         .mouse_rmb(mouse_right_sync2), 
         .char_class(class_id),
         .load_stats(char_select_btn), 
         .update_tick(logic_tick_60hz),
         .take_dmg_en(rx_take_dmg_pulse),
         .take_dmg_val(rx_take_dmg_val), 
         .world_x(my_world_x),
         .world_y(my_world_y),
         .hp(my_hp),
         .dmg(my_dmg),
         .is_dead(my_dead)
     );

     bullet_ctl u_bullet_ctl (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .update_tick(logic_tick_60hz),
         .mouse_x(mouse_x_sync2),
         .mouse_y(mouse_y_sync2),
         .mouse_lmb(mouse_lmb_pulse), 
         .player_world_x(my_world_x),
         .player_world_y(my_world_y),
         .player_dmg(my_dmg),
         .hit_wall(hit_wall),
         .hit_enemy(hit_enemy),
         .phase_combat(current_state == 3'd3), 
         .bullet_world_x(my_bullet_x),
         .bullet_world_y(my_bullet_y),
         .bullet_active(my_bullet_active),
         .bullet_dmg(my_bullet_dmg)
     );

     collision_det u_collision_det (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .my_bullet_x(my_bullet_x),
         .my_bullet_y(my_bullet_y),
         .my_bullet_active(my_bullet_active),
         .enemy_x(enemy_world_x),
         .enemy_y(enemy_world_y),
         .map_addr(map_addr_collision),
         .map_data(is_wall_collision),
         .hit_enemy(hit_enemy),
         .hit_wall(hit_wall)
     );
 
     // =========================================================================
     // MULTIPLAYER UART (TX/RX)
     // =========================================================================
     logic       tx_start, tx_busy, rx_ready;
     logic [7:0] tx_data, rx_data;
 
     uart_tx u_uart_tx (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .tx_start(tx_start),
         .tx_data(tx_data),
         .tx(uart_tx),
         .tx_busy(tx_busy)
     );

     uart_rx u_uart_rx (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .rx(uart_rx),
         .rx_data(rx_data),
         .rx_ready(rx_ready)
     );

     uart_packet_ctl u_packet_ctl (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .send_tick(logic_tick_60hz),
         .my_x(my_world_x),
         .my_y(my_world_y),
         .my_hp(my_hp),
         .hit_enemy(hit_enemy),
         .my_bullet_dmg(my_bullet_dmg),
         .enemy_x(enemy_world_x),
         .enemy_y(enemy_world_y),
         .enemy_hp(enemy_hp),
         .take_dmg_en(rx_take_dmg_en),
         .take_dmg_val(rx_take_dmg_val),
         .tx_start(tx_start),
         .tx_data(tx_data),
         .tx_busy(tx_busy),
         .rx_data(rx_data),
         .rx_ready(rx_ready)
     );

     // =========================================================================
     // PAMIĘĆ MAPY I GENEROWANIE OBRAZU (VGA Pipeline)
     // =========================================================================
     map_rom u_map_rom (
         .clk(clk_65MHz),
         .addr_a(map_addr_vga),
         .is_wall_a(is_wall_vga),
         .addr_b(map_addr_collision), 
         .is_wall_b(is_wall_collision)
     );

     vga_timing u_vga_timing (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .out(timing_to_map.out)
     );

     draw_map u_draw_map (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .map_addr(map_addr_vga), 
         .out(map_to_crates.out),
         .in(timing_to_map.in),
         .player_x(my_world_x),     // <--- POPRAWKA: Przekazywane pełne 16 bitów
         .player_y(my_world_y),     // <--- POPRAWKA: Przekazywane pełne 16 bitów
         .is_wall(is_wall_vga)
     );

     draw_crates u_draw_crates (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .out(crates_to_entities.out),
         .in(map_to_crates.in),
         .player_x(my_world_x),     // <--- POPRAWKA: Przekazywane pełne 16 bitów
         .player_y(my_world_y),     // <--- POPRAWKA: Przekazywane pełne 16 bitów
         .active_crates(active_crates),
         .active_loot(active_loot)
     );

     draw_entities u_draw_entities (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .in(crates_to_entities.in),
         .out(entities_to_hud.out),
         .cam_world_x(my_world_x),
         .cam_world_y(my_world_y),
         .enemy_world_x(enemy_world_x),
         .enemy_world_y(enemy_world_y),
         .enemy_hp(enemy_hp),
         .bullet_world_x(my_bullet_x),
         .bullet_world_y(my_bullet_y),
         .bullet_active(my_bullet_active)
     );

     draw_hud u_draw_hud (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .in(entities_to_hud.in), 
         .out(hud_to_start.out),
         .my_hp(my_hp),
         .enemy_hp(enemy_hp)
     );

     draw_start_screen u_draw_start_screen (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .current_state(current_state),
         .mouse_x(mouse_x_sync2),
         .mouse_y(mouse_y_sync2),
         .mouse_left(mouse_left_sync2),
         .in(hud_to_start.in),
         .out(start_to_char.out)
     );

     draw_char_select u_char_select (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .current_state(current_state),
         .mouse_x(mouse_x_sync2),
         .mouse_y(mouse_y_sync2),
         .mouse_left(mouse_left_sync2),
         .in(start_to_char.in),
         .out(char_to_mouse.out),
         .class_id(class_id),
         .char_select_button(char_select_btn)
     );

     draw_mouse u_draw_mouse (
         .clk(clk_65MHz),
         .rst_n(rst_sys_n),
         .out(mouse_to_out.out),
         .in(char_to_mouse.in),
         .xpos(mouse_x_sync2),
         .ypos(mouse_y_sync2)
     );

 endmodule
`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz, Tomasz Jesionek
 *
 * Description:
 * Główny moduł strukturalny (Top) logiki systemowej działający w domenie 65MHz.
 * Łączy komponenty wejścia/wyjścia (PS2, UART), kontrolery wideo VGA, 
 * pamięci mapy oraz nadrzędny kontroler logiki rozgrywki.
 */

module top_vga
    import vga_pkg::*;
(
    input logic clk_65MHz,
    input logic clk_100MHz,
    input logic rst_sys_n,
    input logic rst_100m_n,
    output logic vs,
    output logic hs,
    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b,
    output logic uart_tx,
    inout wire ps2_clk,
    inout wire ps2_data,
    input logic uart_rx,
    input logic is_master
);

/* VGA signals and interfaces */
vga_if timing_to_map();
vga_if map_to_crates();
vga_if crates_to_entities();
vga_if entities_to_hud();
vga_if hud_to_start();
vga_if start_to_char();
vga_if char_to_game_over();
vga_if game_over_to_mouse();
vga_if mouse_to_out();

/* Local variables and signals */
logic vsync_reg, vsync_nxt;
logic logic_tick_60hz;

logic [11:0] mouse_x_raw, mouse_y_raw;
logic mouse_right_raw, mouse_left_raw, mouse_new_event;
logic mouse_toggle_100_reg, mouse_toggle_100_nxt;

(* ASYNC_REG = "TRUE" *) logic mouse_toggle_sync1_reg, mouse_toggle_sync2_reg, mouse_toggle_sync3_reg;
logic mouse_toggle_sync1_nxt, mouse_toggle_sync2_nxt, mouse_toggle_sync3_nxt;

logic mouse_event_65MHz;
(* ASYNC_REG = "TRUE" *) logic [11:0] mouse_x_sync1_reg;
(* ASYNC_REG = "TRUE" *) logic [11:0] mouse_y_sync1_reg;
(* ASYNC_REG = "TRUE" *) logic mouse_left_sync1_reg;
(* ASYNC_REG = "TRUE" *) logic mouse_right_sync1_reg;

logic [11:0] mouse_x_sync1_nxt, mouse_y_sync1_nxt;
logic mouse_left_sync1_nxt, mouse_right_sync1_nxt;

logic [11:0] mouse_x_sync2_reg, mouse_y_sync2_reg;
logic mouse_right_sync2_reg, mouse_left_sync2_reg;

logic [11:0] mouse_x_sync2_nxt, mouse_y_sync2_nxt;
logic mouse_left_sync2_nxt, mouse_right_sync2_nxt;

logic [2:0] current_state;
logic [31:0] active_crates, active_loot, rx_active_crates, rx_active_loot, crates_hit_mask, loot_collected_mask;
logic [15:0] my_world_x, my_world_y, enemy_world_x, enemy_world_y, my_bullet_x, my_bullet_y, enemy_bullet_x, enemy_bullet_y, player_next_x, player_next_y;
logic [7:0] my_hp, my_dmg, enemy_hp, my_bullet_dmg, rx_take_dmg_val;
logic my_dead, char_select_btn, my_ready_lock, my_bullet_active, enemy_bullet_active, rx_take_dmg_en, hit_enemy, hit_wall;
logic [1:0] class_id;
logic apply_heal, apply_dmg_boost, apply_speed_boost;
logic [1:0] winner_id;

logic is_wall_x, is_wall_y;
logic [11:0] map_addr_x, map_addr_y;
logic [15:0] check_x, check_y;
logic [15:0] current_center_x, current_center_y;

logic mouse_lmb_pulse, mouse_rmb_pulse, rx_take_dmg_pulse;
logic tx_start, tx_busy, rx_ready;
logic [7:0] tx_data, rx_data;

logic [10:0] timeout_counter_reg, timeout_counter_nxt;
logic phase_timeout_pulse_reg, phase_timeout_pulse_nxt;

logic mouse_over_start_btn;
logic start_clicked_reg, start_clicked_nxt;
logic [5:0] start_timer_reg, start_timer_nxt;
logic delayed_start_pulse;

logic [11:0] map_addr_vga, map_addr_collision;
logic is_wall_vga, is_wall_collision;

logic [15:0] center_x, center_y;

/* Signals assignments */
assign vs = mouse_to_out.vsync;
assign hs = mouse_to_out.hsync;
assign {r, g, b} = mouse_to_out.rgb;

assign logic_tick_60hz = timing_to_map.vsync & (~vsync_reg);
assign mouse_event_65MHz = mouse_toggle_sync2_reg ^ mouse_toggle_sync3_reg;

assign current_center_x = my_world_x + 16'd16;
assign current_center_y = my_world_y + 16'd16;

always_comb begin
    // Weryfikacja osi X
    check_x = current_center_x;
    if (player_next_x > my_world_x) check_x = current_center_x + 16'd14;
    else if (player_next_x < my_world_x) check_x = current_center_x - 16'd14;

    // Weryfikacja osi Y
    check_y = current_center_y;
    if (player_next_y > my_world_y) check_y = current_center_y + 16'd14;
    else if (player_next_y < my_world_y) check_y = current_center_y - 16'd14;
end

// Port A: sprawdzamy nową pozycję X, ale wciąż STARĄ pozycję Y
assign map_addr_x = {current_center_y[10:5], check_x[10:5]};
// Port B: sprawdzamy STARĄ pozycję X, ale za to nową pozycję Y
assign map_addr_y = {check_y[10:5], current_center_x[10:5]};

/* Module internal logic */
always_comb begin
    vsync_nxt = timing_to_map.vsync;
end

always_comb begin
    mouse_toggle_100_nxt = mouse_toggle_100_reg;
    if (mouse_new_event) begin
        mouse_toggle_100_nxt = ~mouse_toggle_100_reg;
    end
end

always_comb begin
    mouse_toggle_sync1_nxt = mouse_toggle_100_reg;
    mouse_toggle_sync2_nxt = mouse_toggle_sync1_reg;
    mouse_toggle_sync3_nxt = mouse_toggle_sync2_reg;
end

always_comb begin
    mouse_x_sync1_nxt = mouse_x_sync1_reg;
    mouse_y_sync1_nxt = mouse_y_sync1_reg;
    mouse_left_sync1_nxt = mouse_left_sync1_reg;
    mouse_right_sync1_nxt = mouse_right_sync1_reg;
    if (mouse_event_65MHz) begin
        mouse_x_sync1_nxt = mouse_x_raw;
        mouse_y_sync1_nxt = mouse_y_raw;
        mouse_left_sync1_nxt = mouse_left_raw;
        mouse_right_sync1_nxt = mouse_right_raw;
    end
    
    mouse_x_sync2_nxt = mouse_x_sync1_reg;
    mouse_y_sync2_nxt = mouse_y_sync1_reg;
    mouse_left_sync2_nxt = mouse_left_sync1_reg;
    mouse_right_sync2_nxt = mouse_right_sync1_reg;
end

always_comb begin
    timeout_counter_nxt = timeout_counter_reg;
    phase_timeout_pulse_nxt = 1'b0;
    if ((current_state == 3'd3) && logic_tick_60hz) begin
        if (timeout_counter_reg == 11'd1800) begin 
            phase_timeout_pulse_nxt = 1'b1;
        end else begin
            timeout_counter_nxt = timeout_counter_reg + 11'd1;
        end
    end else if (current_state != 3'd3) begin
        timeout_counter_nxt = 11'd0;
    end
end

always_comb begin
    start_clicked_nxt = start_clicked_reg;
    start_timer_nxt = start_timer_reg;
    delayed_start_pulse = 1'b0;

    // Kliknięcie działa tylko w obszarze przycisku dla ST_INIT (3'd0)
    if (mouse_lmb_pulse && ((current_state == 3'd0 && mouse_over_start_btn) || (current_state == 3'd5))) begin
        start_clicked_nxt = 1'b1;
        start_timer_nxt = 6'd0;
    end

    // Odliczanie opóźnienia - 15 klatek zegara 60Hz to dokładnie 0.25 sekundy
    if (start_clicked_reg) begin
        if (logic_tick_60hz) begin
            if (start_timer_reg == 6'd15) begin
                delayed_start_pulse = 1'b1;
                start_clicked_nxt = 1'b0;
                start_timer_nxt = 6'd0;
            end else begin
                start_timer_nxt = start_timer_reg + 6'd1;
            end
        end
    end
end

always_ff @(posedge clk_100MHz or negedge rst_100m_n) begin
    if (!rst_100m_n) begin
        mouse_toggle_100_reg <= 1'b0;
    end else begin
        mouse_toggle_100_reg <= mouse_toggle_100_nxt;
    end
end

always_ff @(posedge clk_65MHz or negedge rst_sys_n) begin
    if (!rst_sys_n) begin
        vsync_reg <= 1'b0;
        mouse_toggle_sync1_reg <= 1'b0;
        mouse_toggle_sync2_reg <= 1'b0;
        mouse_toggle_sync3_reg <= 1'b0;
        mouse_x_sync1_reg <= 12'h0;
        mouse_y_sync1_reg <= 12'h0;
        mouse_left_sync1_reg <= 1'b0;
        mouse_right_sync1_reg <= 1'b0;
        mouse_x_sync2_reg <= 12'h0;
        mouse_y_sync2_reg <= 12'h0;
        mouse_left_sync2_reg <= 1'b0;
        mouse_right_sync2_reg <= 1'b0;
        timeout_counter_reg <= 11'd0;
        phase_timeout_pulse_reg <= 1'b0;
        start_clicked_reg <= 1'b0;
        start_timer_reg <= 6'd0;
    end else begin
        vsync_reg <= vsync_nxt;
        mouse_toggle_sync1_reg <= mouse_toggle_sync1_nxt;
        mouse_toggle_sync2_reg <= mouse_toggle_sync2_nxt;
        mouse_toggle_sync3_reg <= mouse_toggle_sync3_nxt;
        mouse_x_sync1_reg <= mouse_x_sync1_nxt;
        mouse_y_sync1_reg <= mouse_y_sync1_nxt;
        mouse_left_sync1_reg <= mouse_left_sync1_nxt;
        mouse_right_sync1_reg <= mouse_right_sync1_nxt;
        mouse_x_sync2_reg <= mouse_x_sync2_nxt;
        mouse_y_sync2_reg <= mouse_y_sync2_nxt;
        mouse_left_sync2_reg <= mouse_left_sync2_nxt;
        mouse_right_sync2_reg <= mouse_right_sync2_nxt;
        timeout_counter_reg <= timeout_counter_nxt;
        phase_timeout_pulse_reg <= phase_timeout_pulse_nxt;
        start_clicked_reg <= start_clicked_nxt;
        start_timer_reg <= start_timer_nxt;
    end
end

/* Submodules placement */
MouseCtl u_mouse_ctl (
    .clk        (clk_100MHz), 
    .rst        (~rst_100m_n), 
    .ps2_clk    (ps2_clk), 
    .ps2_data   (ps2_data),
    .xpos       (mouse_x_raw), 
    .ypos       (mouse_y_raw), 
    .right      (mouse_right_raw), 
    .left       (mouse_left_raw),
    .value      (12'd1023), 
    .setmax_x   (1'b0), 
    .setmax_y   (1'b0), 
    .setx       (1'b0), 
    .sety       (1'b0),
    .zpos       (), 
    .middle     (), 
    .new_event  (mouse_new_event) 
);

edge_detector u_lmb_edge (
    .clk(clk_65MHz),
    .rst_n(rst_sys_n),
    .in_signal(mouse_left_sync2_reg),
    .out_pulse(mouse_lmb_pulse)
);

edge_detector u_rmb_edge (
    .clk(clk_65MHz),
    .rst_n(rst_sys_n),
    .in_signal(mouse_right_sync2_reg),
    .out_pulse(mouse_rmb_pulse)
);

edge_detector u_dmg_edge (
    .clk(clk_65MHz),
    .rst_n(rst_sys_n),
    .in_signal(rx_take_dmg_en),
    .out_pulse(rx_take_dmg_pulse)
);

game_logic_top u_game_logic (
    .clk                 (clk_65MHz),
    .rst_n               (rst_sys_n),
    .active_crates       (active_crates),
    .active_loot         (active_loot),
    .current_state       (current_state),
    .winner_id           (winner_id),
    .is_master           (is_master),
    .rx_active_crates    (rx_active_crates),
    .rx_active_loot      (rx_active_loot),
    .start_btn           (delayed_start_pulse), 
    .char_select_btn     (my_ready_lock),
    .enemy_ready         (enemy_hp > 8'd0),
    .phase_timeout       (phase_timeout_pulse_reg),
    .crates_hit_mask     (crates_hit_mask),
    .loot_collected_mask (loot_collected_mask),
    .p1_dead             (my_dead),
    .p2_dead             (enemy_hp == 8'd0)
);

player_ctl #(
    .MAP_WIDTH_M(2048),
    .MAP_HEIGHT_N(2048)
) u_player_ctl (
    .clk               (clk_65MHz),
    .rst_n             (rst_sys_n),
    .next_x_out        (player_next_x),
    .next_y_out        (player_next_y),
    .world_x           (my_world_x),
    .world_y           (my_world_y),
    .hp                (my_hp),
    .dmg               (my_dmg),
    .is_dead           (my_dead),
    .is_master         (is_master),
    .mouse_x           (mouse_x_sync2_reg),
    .mouse_y           (mouse_y_sync2_reg),
    .mouse_rmb         (mouse_right_sync2_reg),
    .char_class        (class_id),
    .load_stats        (char_select_btn),
    .update_tick       (logic_tick_60hz),
    .take_dmg_en       (rx_take_dmg_pulse),
    .take_dmg_val      (rx_take_dmg_val),
    .apply_heal        (apply_heal),
    .apply_dmg_boost   (apply_dmg_boost),
    .apply_speed_boost (apply_speed_boost),
    .movement_en       ((current_state == 3'd3) || (current_state == 3'd4)),
    .is_wall_x         (is_wall_x),
    .is_wall_y         (is_wall_y)
);

bullet_ctl #(
    .MAP_WIDTH_M(2048),
    .MAP_HEIGHT_N(2048)
) u_bullet_ctl (
    .clk              (clk_65MHz),
    .rst_n            (rst_sys_n),
    .bullet_world_x   (my_bullet_x),
    .bullet_world_y   (my_bullet_y),
    .bullet_active    (my_bullet_active),
    .bullet_dmg       (my_bullet_dmg),
    .update_tick      (logic_tick_60hz),
    .mouse_x          (mouse_x_sync2_reg),
    .mouse_y          (mouse_y_sync2_reg),
    .mouse_lmb        (mouse_lmb_pulse),
    .player_world_x   (my_world_x),
    .player_world_y   (my_world_y),
    .player_dmg       (my_dmg),
    .hit_wall         (hit_wall),
    .hit_enemy        (hit_enemy),
    .phase_combat     ((current_state == 3'd3) || (current_state == 3'd4))
);

collision_det u_collision_det (
    .clk              (clk_65MHz),
    .rst_n            (rst_sys_n),
    .map_addr         (map_addr_collision),
    .hit_enemy        (hit_enemy),
    .hit_wall         (hit_wall),
    .my_bullet_x      (my_bullet_x),
    .my_bullet_y      (my_bullet_y),
    .my_bullet_active (my_bullet_active),
    .enemy_x          (enemy_world_x),
    .enemy_y          (enemy_world_y),
    .map_data         (is_wall_collision)
);

crates_collision_det u_crates_collision (
    .clk                 (clk_65MHz),
    .rst_n               (rst_sys_n),
    .crates_hit_mask     (crates_hit_mask),
    .loot_collected_mask (loot_collected_mask),
    .apply_heal          (apply_heal),
    .apply_dmg_boost     (apply_dmg_boost),
    .apply_speed_boost   (apply_speed_boost),
    .update_tick         (logic_tick_60hz),
    .my_bullet_x         (my_bullet_x),
    .my_bullet_y         (my_bullet_y),
    .my_bullet_active    (my_bullet_active),
    .enemy_bullet_x      (enemy_bullet_x),
    .enemy_bullet_y      (enemy_bullet_y),
    .enemy_bullet_active (enemy_bullet_active),
    .player_x            (my_world_x),
    .player_y            (my_world_y),
    .enemy_x             (enemy_world_x),
    .enemy_y             (enemy_world_y),
    .active_crates       (active_crates),
    .active_loot         (active_loot)
);

uart_packet_ctl u_packet_ctl (
    .clk                 (clk_65MHz),
    .rst_n               (rst_sys_n),
    .my_x                (my_world_x),
    .my_y                (my_world_y),
    .my_hp               (my_hp),
    .my_bullet_dmg       (my_bullet_dmg),
    .my_bullet_x         (my_bullet_x),
    .my_bullet_y         (my_bullet_y),
    .my_bullet_active    (my_bullet_active),
    .my_active_crates    (active_crates),
    .my_active_loot      (active_loot),
    .tx_start            (tx_start),
    .tx_data             (tx_data),
    .send_tick           (logic_tick_60hz),
    .hit_enemy           (hit_enemy && (current_state == 3'd4)),
    .enemy_x             (enemy_world_x),
    .enemy_y             (enemy_world_y),
    .enemy_hp            (enemy_hp),
    .take_dmg_en         (rx_take_dmg_en),
    .take_dmg_val        (rx_take_dmg_val),
    .enemy_bullet_x      (enemy_bullet_x),
    .enemy_bullet_y      (enemy_bullet_y),
    .enemy_bullet_active (enemy_bullet_active),
    .rx_active_crates    (rx_active_crates),
    .rx_active_loot      (rx_active_loot),
    .tx_busy             (tx_busy),
    .rx_data             (rx_data),
    .rx_ready            (rx_ready)
);

uart_tx u_uart_tx (
    .clk      (clk_65MHz),
    .rst_n    (rst_sys_n),
    .tx_start (tx_start),
    .tx_data  (tx_data),
    .tx       (uart_tx),
    .tx_busy  (tx_busy)
);

uart_rx u_uart_rx (
    .clk      (clk_65MHz),
    .rst_n    (rst_sys_n),
    .rx       (uart_rx),
    .rx_data  (rx_data),
    .rx_ready (rx_ready)
);

map_rom u_map_rom_player (
    .clk       (clk_65MHz),
    .rst_n     (rst_sys_n),
    .is_wall_a (is_wall_x),
    .is_wall_b (is_wall_y),
    .addr_a    (map_addr_x),
    .addr_b    (map_addr_y)
);

map_rom u_map_rom_vga (
    .clk       (clk_65MHz),
    .rst_n     (rst_sys_n),
    .is_wall_a (is_wall_vga),
    .is_wall_b (is_wall_collision), 
    .addr_a    (map_addr_vga),
    .addr_b    (map_addr_collision)
);

vga_timing u_vga_timing (
    .clk    (clk_65MHz),
    .rst_n  (rst_sys_n),
    .out    (timing_to_map.out)
);

draw_map u_draw_map (
    .clk       (clk_65MHz),
    .rst_n     (rst_sys_n),
    .map_addr  (map_addr_vga),
    .out       (map_to_crates.out),
    .in        (timing_to_map.in),
    .player_x  (my_world_x),
    .player_y  (my_world_y),
    .is_wall   (is_wall_vga)
);

draw_crates u_draw_crates (
    .clk            (clk_65MHz),
    .rst_n          (rst_sys_n),
    .out            (crates_to_entities.out),
    .in             (map_to_crates.in),
    .player_x       (my_world_x[11:0]),
    .player_y       (my_world_y[11:0]),
    .active_crates  (active_crates),
    .active_loot    (active_loot)
);

draw_entities u_draw_entities (
    .clk                 (clk_65MHz),
    .rst_n               (rst_sys_n),
    .out                 (entities_to_hud.out),
    .in                  (crates_to_entities.in),
    .cam_world_x         (my_world_x),
    .cam_world_y         (my_world_y),
    .enemy_world_x       (enemy_world_x),
    .enemy_world_y       (enemy_world_y),
    .enemy_hp            (enemy_hp),
    .bullet_world_x      (my_bullet_x),
    .bullet_world_y      (my_bullet_y),
    .bullet_active       (my_bullet_active),
    .enemy_bullet_x      (enemy_bullet_x),      
    .enemy_bullet_y      (enemy_bullet_y),      
    .enemy_bullet_active (enemy_bullet_active) 
);

draw_hud u_draw_hud (
    .clk       (clk_65MHz),
    .rst_n     (rst_sys_n),
    .out       (hud_to_start.out),
    .in        (entities_to_hud.in),
    .my_hp     (my_hp),
    .enemy_hp  (enemy_hp)
);

draw_start_screen u_draw_start_screen (
    .clk                (clk_65MHz),
    .rst_n              (rst_sys_n),
    .is_master          (is_master),
    .out                (start_to_char.out),
    .current_state      (current_state),
    .mouse_x            (mouse_x_sync2_reg),
    .mouse_y            (mouse_y_sync2_reg),
    .mouse_left         (mouse_left_sync2_reg),
    .start_clicked      (start_clicked_reg),
    .mouse_over_button  (mouse_over_start_btn),
    .in                 (hud_to_start.in)
);

draw_char_select u_char_select (
    .clk                 (clk_65MHz),
    .rst_n               (rst_sys_n),
    .class_id            (class_id),
    .char_select_button  (char_select_btn),
    .my_ready            (my_ready_lock),
    .enemy_ready         (enemy_hp > 8'd0),
    .out                 (char_to_game_over.out),
    .current_state       (current_state),
    .mouse_x             (mouse_x_sync2_reg),
    .mouse_y             (mouse_y_sync2_reg),
    .mouse_left          (mouse_left_sync2_reg),
    .in                  (start_to_char.in)
);

draw_game_over u_draw_game_over (
    .clk            (clk_65MHz),
    .rst_n          (rst_sys_n),
    .current_state  (current_state),
    .winner_id      (winner_id),
    .in             (char_to_game_over.in),
    .out            (game_over_to_mouse.out)
);

draw_mouse u_draw_mouse (
    .clk    (clk_65MHz),
    .rst_n  (rst_sys_n),
    .out    (mouse_to_out.out),
    .in     (game_over_to_mouse.in),
    .xpos   (mouse_x_sync2_reg),
    .ypos   (mouse_y_sync2_reg)
);

endmodule
`timescale 1ns / 1ps

module top_vga
    import vga_pkg::*;
(
    input  logic       clk_65MHz,
    input  logic       clk_100MHz,
    input  logic       rst_sys_n,
    input  logic       rst_100m_n,
    input  logic       is_master,
    
    output logic       vs,
    output logic       hs,
    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b,
    inout  wire        ps2_clk,
    inout  wire        ps2_data,
    
    input  logic       uart_rx,
    output logic       uart_tx
);

    // KASKADA VGA I SYNCHRONIZACJA
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

    logic vsync_reg;
    always_ff @(posedge clk_65MHz or negedge rst_sys_n) begin
        if (!rst_sys_n) vsync_reg <= 1'b0;
        else            vsync_reg <= timing_to_map.vsync;
    end
    wire logic_tick_60hz = timing_to_map.vsync & ~vsync_reg;

// MYSZ (CDC) - Dokładne nazwy, których szuka plik .xdc (usuwa Critical Warning)
    logic [11:0] mouse_x_raw, mouse_y_raw;
    logic        mouse_right_raw, mouse_left_raw, mouse_new_event, mouse_toggle_100;
    
    // Sygnały dla domeny 65 MHz
    logic [11:0] mouse_x_sync2, mouse_y_sync2;
    logic        mouse_right_sync2, mouse_left_sync2, mouse_event_65MHz;

    // 1. Synchronizacja impulsu (zdarzenia) za pomocą Toggle Synchronizer
    always_ff @(posedge clk_100MHz or negedge rst_100m_n) begin
        if (!rst_100m_n) mouse_toggle_100 <= 1'b0;
        else if (mouse_new_event) mouse_toggle_100 <= ~mouse_toggle_100;
    end

    (* ASYNC_REG = "TRUE" *) logic mouse_toggle_sync1, mouse_toggle_sync2, mouse_toggle_sync3;
    always_ff @(posedge clk_65MHz or negedge rst_sys_n) begin
        if (!rst_sys_n) begin 
            {mouse_toggle_sync3, mouse_toggle_sync2, mouse_toggle_sync1} <= 3'b0;
        end else begin
            {mouse_toggle_sync3, mouse_toggle_sync2, mouse_toggle_sync1} <= {mouse_toggle_sync2, mouse_toggle_sync1, mouse_toggle_100};
        end
    end

    assign mouse_event_65MHz = mouse_toggle_sync2 ^ mouse_toggle_sync3;

    // 2. Dwustopniowa synchronizacja DANYCH myszy (z wymuszonym sync1 dla pliku .xdc)
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_x_sync1;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_y_sync1;
    (* ASYNC_REG = "TRUE" *) logic        mouse_left_sync1;
    (* ASYNC_REG = "TRUE" *) logic        mouse_right_sync1;

    always_ff @(posedge clk_65MHz or negedge rst_sys_n) begin
        if (!rst_sys_n) begin
            mouse_x_sync1     <= 12'h0;
            mouse_y_sync1     <= 12'h0;
            mouse_left_sync1  <= 1'b0;
            mouse_right_sync1 <= 1'b0;
            
            mouse_x_sync2     <= 12'h0;
            mouse_y_sync2     <= 12'h0;
            mouse_left_sync2  <= 1'b0;
            mouse_right_sync2 <= 1'b0;
        end else begin
            // Stopień 1: Przechwytuje dane asynchroniczne 
            // (Vivado dzięki nazwie _sync1 wie, żeby nałożyć tu regułę set_max_delay)
            mouse_x_sync1     <= mouse_x_raw;
            mouse_y_sync1     <= mouse_y_raw;
            mouse_left_sync1  <= mouse_left_raw;
            mouse_right_sync1 <= mouse_right_raw;
            
            // Stopień 2: Przekazuje w pełni stabilne dane dla reszty logiki gry
            mouse_x_sync2     <= mouse_x_sync1;
            mouse_y_sync2     <= mouse_y_sync1;
            mouse_left_sync2  <= mouse_left_sync1;
            mouse_right_sync2 <= mouse_right_sync1;
        end
    end

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

    // LOGIKA GRY I SYGNAŁY STERUJĄCE
    logic [2:0]  current_state;
    logic [31:0] active_crates, active_loot, rx_active_crates, rx_active_loot, crates_hit_mask, loot_collected_mask;
    logic [15:0] my_world_x, my_world_y, enemy_world_x, enemy_world_y, my_bullet_x, my_bullet_y, enemy_bullet_x, enemy_bullet_y, player_next_x, player_next_y;
    logic [7:0]  my_hp, my_dmg, enemy_hp, my_bullet_dmg, rx_take_dmg_val;
    logic        my_dead, char_select_btn, my_bullet_active, enemy_bullet_active, rx_take_dmg_en, hit_enemy, hit_wall;
    logic [1:0]  class_id;
    logic        apply_heal, apply_dmg_boost, apply_speed_boost, phase_timeout;
    logic [13:0] map_addr_vga, map_addr_collision, map_addr_player;
    logic        is_wall_vga, is_wall_collision, is_wall_player;
    logic        mouse_lmb_pulse, mouse_rmb_pulse, rx_take_dmg_pulse; 
    logic        tx_start, tx_busy, rx_ready;
    logic [7:0]  tx_data, rx_data;

    edge_detector u_lmb_edge (.clk(clk_65MHz), .rst_n(rst_sys_n), .in_signal(mouse_left_sync2), .out_pulse(mouse_lmb_pulse));
    edge_detector u_rmb_edge (.clk(clk_65MHz), .rst_n(rst_sys_n), .in_signal(mouse_right_sync2), .out_pulse(mouse_rmb_pulse));
    edge_detector u_dmg_edge (.clk(clk_65MHz), .rst_n(rst_sys_n), .in_signal(rx_take_dmg_en), .out_pulse(rx_take_dmg_pulse));

    // INSTANCJE MODUŁÓW
    game_logic_top u_game_logic (
        .clk                 (clk_65MHz),
        .rst_n               (rst_sys_n),
        .is_master           (is_master),
        .rx_active_crates    (rx_active_crates),
        .rx_active_loot      (rx_active_loot),
        .active_crates       (active_crates),
        .active_loot         (active_loot),
        .current_state       (current_state),
        .start_btn           (mouse_lmb_pulse && (current_state == 3'd0 || current_state == 3'd4)),
        .char_select_btn     (char_select_btn),
        .phase_timeout       (1'b0),
        .crates_hit_mask     (crates_hit_mask),
        .loot_collected_mask (loot_collected_mask),
        .p1_dead             (my_dead),
        .p2_dead             (enemy_hp == 8'd0)
    );

    player_ctl u_player_ctl (
        .clk               (clk_65MHz),
        .rst_n             (rst_sys_n),
        .mouse_x           (mouse_x_sync2),
        .mouse_y           (mouse_y_sync2),
        .mouse_rmb         (mouse_right_sync2),
        .char_class        (class_id),
        .load_stats        (char_select_btn),
        .update_tick       (logic_tick_60hz),
        .take_dmg_en       (rx_take_dmg_pulse),
        .take_dmg_val      (rx_take_dmg_val),
        .apply_heal        (apply_heal),
        .apply_dmg_boost   (apply_dmg_boost),
        .apply_speed_boost (apply_speed_boost),
        .is_wall_ahead     (is_wall_player),
        .next_x_out        (player_next_x),
        .next_y_out        (player_next_y),
        .world_x           (my_world_x),
        .world_y           (my_world_y),
        .hp                (my_hp),
        .dmg               (my_dmg),
        .is_dead           (my_dead)
    );

    bullet_ctl u_bullet_ctl (
        .clk              (clk_65MHz),
        .rst_n            (rst_sys_n),
        .update_tick      (logic_tick_60hz),
        .mouse_x          (mouse_x_sync2),
        .mouse_y          (mouse_y_sync2),
        .mouse_lmb        (mouse_lmb_pulse),
        .player_world_x   (my_world_x),
        .player_world_y   (my_world_y),
        .player_dmg       (my_dmg),
        .hit_wall         (hit_wall),
        .hit_enemy        (hit_enemy),
        .phase_combat     (current_state == 3'd2),
        .bullet_world_x   (my_bullet_x),
        .bullet_world_y   (my_bullet_y),
        .bullet_active    (my_bullet_active),
        .bullet_dmg       (my_bullet_dmg)
    );

    collision_det u_collision_det (
        .clk              (clk_65MHz),
        .rst_n            (rst_sys_n),
        .my_bullet_x      (my_bullet_x),
        .my_bullet_y      (my_bullet_y),
        .my_bullet_active (my_bullet_active),
        .enemy_x          (enemy_world_x),
        .enemy_y          (enemy_world_y),
        .map_addr         (map_addr_collision),
        .map_data         (is_wall_collision),
        .hit_enemy        (hit_enemy),
        .hit_wall         (hit_wall)
    );

    crates_collision_det u_crates_collision (
        .clk                 (clk_65MHz),
        .rst_n               (rst_sys_n),
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
        .active_loot         (active_loot),
        .crates_hit_mask     (crates_hit_mask),
        .loot_collected_mask (loot_collected_mask),
        .apply_heal          (apply_heal),
        .apply_dmg_boost     (apply_dmg_boost),
        .apply_speed_boost   (apply_speed_boost)
    );

    uart_packet_ctl u_packet_ctl (
        .clk                 (clk_65MHz),
        .rst_n               (rst_sys_n),
        .send_tick           (logic_tick_60hz),
        .my_x                (my_world_x),
        .my_y                (my_world_y),
        .my_hp               (my_hp),
        .hit_enemy           (hit_enemy),
        .my_bullet_dmg       (my_bullet_dmg),
        .my_bullet_x         (my_bullet_x),
        .my_bullet_y         (my_bullet_y),
        .my_bullet_active    (my_bullet_active),
        .my_active_crates    (active_crates),
        .my_active_loot      (active_loot),
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
        .tx_start            (tx_start),
        .tx_data             (tx_data),
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

    map_rom u_map_rom (
        .clk       (clk_65MHz),
        .addr_a    (map_addr_vga[11:0]),
        .is_wall_a (is_wall_vga),
        .addr_b    (map_addr_collision[11:0]),
        .is_wall_b (is_wall_collision)
    );

    map_rom u_map_rom_player (
        .clk       (clk_65MHz),
        .addr_a    (map_addr_player[11:0]),
        .is_wall_a (is_wall_player),
        .addr_b    (12'h0),
        .is_wall_b ()
    );
    assign map_addr_player = {player_next_y[11:5], player_next_x[11:5]};

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

    // Aktualizacja instancji draw_entities - podpinamy pocisk wroga
    draw_entities u_draw_entities (
        .clk             (clk_65MHz),
        .rst_n           (rst_sys_n),
        .in              (crates_to_entities.in),
        .out             (entities_to_hud.out),
        .cam_world_x     (my_world_x),
        .cam_world_y     (my_world_y),
        .enemy_world_x   (enemy_world_x),
        .enemy_world_y   (enemy_world_y),
        .enemy_hp        (enemy_hp),
        .bullet_world_x  (my_bullet_x),
        .bullet_world_y  (my_bullet_y),
        .bullet_active   (my_bullet_active),
        .enemy_bullet_x  (enemy_bullet_x),      // DODANE
        .enemy_bullet_y  (enemy_bullet_y),      // DODANE
        .enemy_bullet_active (enemy_bullet_active) // DODANE
    );

    draw_hud u_draw_hud (
        .clk       (clk_65MHz),
        .rst_n     (rst_sys_n),
        .in        (entities_to_hud.in),
        .out       (hud_to_start.out),
        .my_hp     (my_hp),
        .enemy_hp  (enemy_hp)
    );

    draw_start_screen u_draw_start_screen (
        .clk            (clk_65MHz),
        .rst_n          (rst_sys_n),
        .current_state  (current_state),
        .mouse_x        (mouse_x_sync2),
        .mouse_y        (mouse_y_sync2),
        .mouse_left     (mouse_left_sync2),
        .in             (hud_to_start.in),
        .out            (start_to_char.out)
    );

    draw_char_select u_char_select (
        .clk                 (clk_65MHz),
        .rst_n               (rst_sys_n),
        .current_state       (current_state),
        .mouse_x             (mouse_x_sync2),
        .mouse_y             (mouse_y_sync2),
        .mouse_left          (mouse_left_sync2),
        .in                  (start_to_char.in),
        .out                 (char_to_mouse.out),
        .class_id            (class_id),
        .char_select_button  (char_select_btn)
    );

    draw_mouse u_draw_mouse (
        .clk    (clk_65MHz),
        .rst_n  (rst_sys_n),
        .out    (mouse_to_out.out),
        .in     (char_to_mouse.in),
        .xpos   (mouse_x_sync2),
        .ypos   (mouse_y_sync2)
    );
endmodule
/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz, Tomasz Jesionek
 *
 * Description:
 * Top VGA structural module.
 */

`timescale 1ns / 1ps

module top_vga
    import vga_pkg::*;
    (
        input  logic       clk,
        input  logic       clk100MHz,
        input  logic       rst_pclk_n,
        input  logic       rst_100m_n,
        output logic       vs,
        output logic       hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b,
        inout  wire        ps2_clk,
        inout  wire        ps2_data
    );

    logic clk_65MHz;
    logic clk_100MHz_internal;
    logic clk_locked;
    logic rst_sys_n;

    assign rst_sys_n = rst_pclk_n & clk_locked;

    clk_wiz_0 u_clk_wiz (
        .clk(clk100MHz),
        .clk100MHz(clk_100MHz_internal),
        .clk65MHz(clk_65MHz),
        .locked(clk_locked)
    );
    
    typedef enum logic [2:0] {
        ST_INIT_START = 3'd0,
        ST_SET_X      = 3'd1,
        ST_WAIT_X     = 3'd2,
        ST_SET_Y      = 3'd3,
        ST_WAIT_Y     = 3'd4,
        ST_DONE       = 3'd5
    } mouse_cfg_state_t;

    logic [11:0] mouse_x_raw;
    logic [11:0] mouse_y_raw;
    logic        mouse_right_raw;
    logic        mouse_left_raw;

    logic [11:0] mouse_x_sync1;
    logic [11:0] mouse_x_sync2;
    logic [11:0] mouse_y_sync1;
    logic [11:0] mouse_y_sync2;
    logic        mouse_right_sync1;
    logic        mouse_right_sync2;
    logic        mouse_left_sync1;
    logic        mouse_left_sync2;

    mouse_cfg_state_t m_state;
    mouse_cfg_state_t m_state_nxt;
    logic [11:0] m_cfg_val;
    logic [11:0] m_cfg_val_nxt;
    logic        m_set_x;
    logic        m_set_x_nxt;
    logic        m_set_y;
    logic        m_set_y_nxt;

    logic [31:0] active_crates;
    logic [31:0] active_loot;
    logic [2:0]  current_state;
    logic [11:0] player_x;
    logic [11:0] player_y;

    logic [9:0]  map_addr_vga;
    logic        is_wall_vga;
    logic [9:0]  map_addr_player;
    logic        is_wall_player;

    logic [1:0]  class_id;
    logic        char_select_btn;
    logic [11:0] cam_x;
    logic [11:0] cam_y;

    vga_if timing_to_render_map();
    vga_if render_map_to_crates();
    vga_if render_crates_to_start();
    vga_if render_start_to_char();
    vga_if char_to_mouse();
    vga_if mouse_to_out();

    assign vs = mouse_to_out.vsync;
    assign hs = mouse_to_out.hsync;
    assign {r, g, b} = mouse_to_out.rgb;

    always_ff @(posedge clk_65MHz or negedge rst_sys_n) begin
        if (!rst_pclk_n) begin
            mouse_x_sync1     <= 12'h0;
            mouse_x_sync2     <= 12'h0;
            mouse_y_sync1     <= 12'h0;
            mouse_y_sync2     <= 12'h0;
            mouse_right_sync1 <= 1'b0;
            mouse_right_sync2 <= 1'b0;
            mouse_left_sync1  <= 1'b0;
            mouse_left_sync2  <= 1'b0;
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

    always_ff @(posedge clk100MHz_internal or negedge rst_100m_n) begin
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
            ST_INIT_START: begin
                m_state_nxt = ST_SET_X;
            end
            ST_SET_X: begin
                m_cfg_val_nxt = MOUSE_MAX_X;
                m_set_x_nxt   = 1'b1;
                m_state_nxt   = ST_WAIT_X;
            end
            ST_WAIT_X: begin
                m_state_nxt = ST_SET_Y;
            end
            ST_SET_Y: begin
                m_cfg_val_nxt = MOUSE_MAX_Y;
                m_set_y_nxt   = 1'b1;
                m_state_nxt   = ST_WAIT_Y;
            end
            ST_WAIT_Y: begin
                m_state_nxt = ST_DONE;
            end
            ST_DONE: begin
            end
            default: begin
                m_state_nxt = ST_INIT_START;
            end
        endcase
    end

    MouseCtl u_mouse_ctl (
        .clk(clk100MHz),
        .rst(~rst_100m_n),
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
        .new_event()
    );

    game_logic_top u_game_logic (
        .clk(clk),
        .rst_n(rst_pclk_n),
        .active_crates(active_crates),
        .active_loot(active_loot),
        .current_state(current_state),
        .start_btn(mouse_left_sync2),
        .char_select_btn(char_select_btn),
        .phase_timeout(1'b0),
        .crates_hit_mask(32'h0),
        .loot_collected_mask(32'h0)
    );

    player_ctl u_player_ctl (
        .clk(clk),
        .rst_n(rst_pclk_n),
        .class_id(class_id),
        .map_addr(map_addr_player),
        .player_x(player_x),
        .player_y(player_y),
        .vcount(timing_to_render.vcount),
        .hcount(timing_to_render.hcount),
        .mouse_x(mouse_x_sync2[9:0]),
        .mouse_y(mouse_y_sync2[9:0]),
        .mouse_rmb(mouse_right_sync2),
        .is_wall(is_wall_player),
        .cam_x(cam_x),
        .cam_y(cam_y),
    );

    map_rom u_map_rom (
        .clk(clk),
        .addr_a(map_addr_vga),
        .is_wall_a(is_wall_vga),
        .addr_b(map_addr_player),
        .is_wall_b(is_wall_player)
    );

    vga_timing u_vga_timing (
        .clk(clk),
        .rst_n(rst_pclk_n),
        .out(timing_to_render.out)
    );

    draw_map u_draw_map (
        .clk(clk),
        .rst_n(rst_pclk_n),
        .cam_x(cam_X),
        .cam_y(cam_y),
        .map_addr(map_addr_vga),
        .out(render_map_to_crates.out),
        .in(timing_to_render.in),
        .player_x(player_x),
        .player_y(player_y),
        .is_wall(is_wall_vga)
    );

    draw_crates u_draw_crates (
        .clk(clk),
        .rst_n(rst_pclk_n),
        .out(render_crates_to_start.out),
        .in(render_map_to_crates.in),
        .player_x(player_x),
        .player_y(player_y),
        .active_crates(active_crates),
        .active_loot(active_loot)
    );

    draw_start_screen u_draw_start_screen (
        .clk(clk),
        .rst_n(rst_pclk_n),
        .current_state(current_state),
        .mouse_x(mouse_x_sync2),
        .mouse_y(mouse_y_sync2),
        .mouse_left(mouse_left_sync2),
        .in(render_crates_to_start.in),
        .out(render_start_to_char.out)
    );

    char_select u_char_select (
        .clk(clk),
        .rst_n(rst_pclk_n),
        .current_state(current_state),
        .mouse_x(mouse_x_sync2),
        .mouse_y(mouse_y_sync2),
        .mouse_left(mouse_left_sync2),
        .in(render_start_to_char.in),
        .out(char_to_mouse.out),
        .class_id(class_id),
        .char_select_btn(char_select_btn)
    );

    draw_mouse u_draw_mouse (
        .clk(clk),
        .rst_n(rst_pclk_n),
        .out(mouse_to_out.out),
        .in(char_to_mouse.in),
        .xpos(mouse_x_sync2),
        .ypos(mouse_y_sync2)
    );

endmodule
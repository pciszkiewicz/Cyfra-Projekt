`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz, Tomasz Jesionek
 *
 * Description:
 * Top-level podsystemu logiki gry.
 * Spina maszynę stanów FSM, generator pseudolosowy LFSR do dystrybucji skrzyń
 * oraz pamięć ROM konfiguracji aren (układu obiektów na mapie).
 */

module game_logic_top (
    input logic clk,
    input logic rst_n,
    output logic [31:0] active_crates,
    output logic [31:0] active_loot,
    output logic [2:0] current_state,
    output logic [1:0] winner_id,
    input logic is_master,
    input logic [31:0] rx_active_crates,
    input logic [31:0] rx_active_loot,
    input logic start_btn,
    input logic char_select_btn,
    input logic enemy_ready,
    input logic phase_timeout,
    input logic [31:0] crates_hit_mask,
    input logic [31:0] loot_collected_mask,
    input logic p1_dead,
    input logic p2_dead
);

/* Local variables and signals */
logic [15:0] lfsr_out;
logic [31:0] rom_data_out;
logic [7:0] rom_addr;

/* Submodules placement */
lfsr #(
    .SEED(16'hACE1)
) u_lfsr (
    .clk(clk),
    .rst_n(rst_n),
    .rand_out(lfsr_out),
    .en(1'b1) 
);

crates_rom u_crates_rom (
    .clk(clk),
    .rst_n(rst_n),
    .data_out(rom_data_out),
    .addr(rom_addr)
);

game_fsm u_game_fsm (
    .clk(clk),
    .rst_n(rst_n),
    .rom_addr(rom_addr),
    .active_crates(active_crates),
    .active_loot(active_loot),
    .current_state(current_state),
    .winner_id(winner_id),
    .is_master(is_master),
    .rx_active_crates(rx_active_crates),
    .rx_active_loot(rx_active_loot),
    .start_btn(start_btn),
    .char_select_btn(char_select_btn),
    .enemy_ready(enemy_ready),
    .phase_timeout(phase_timeout),
    .lfsr_val(lfsr_out[7:0]),
    .rom_data(rom_data_out),
    .crates_hit_mask(crates_hit_mask),
    .loot_collected_mask(loot_collected_mask),
    .p1_dead(p1_dead),
    .p2_dead(p2_dead)
);

endmodule
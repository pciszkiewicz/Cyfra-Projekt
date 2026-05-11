/**
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * Game logic top module connecting LFSR, ROM, and FSM.
 */

 module game_logic_top (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] active_crates,
    output logic [1:0]  current_state,
    input  logic        start_btn,
    input  logic        phase_timeout,
    input  logic [31:0] crates_hit_mask
);

logic [15:0] lfsr_out;
logic [31:0] rom_data_out;
logic [7:0]  rom_addr;

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
    .data_out(rom_data_out),
    .addr(rom_addr)
);

game_fsm u_game_fsm (
    .clk(clk),
    .rst_n(rst_n),
    .rom_addr(rom_addr),
    .active_crates(active_crates),
    .current_state(current_state),
    .start_btn(start_btn),
    .phase_timeout(phase_timeout),
    .lfsr_val(lfsr_out[7:0]),
    .rom_data(rom_data_out),
    .crates_hit_mask(crates_hit_mask)
);

endmodule
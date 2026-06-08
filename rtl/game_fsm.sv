`timescale 1 ns / 1 ps

module game_fsm (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        is_master,
    input  logic [31:0] rx_active_crates,
    input  logic [31:0] rx_active_loot,
    output logic [7:0]  rom_addr,
    output logic [31:0] active_crates,
    output logic [31:0] active_loot,
    output logic [2:0]  current_state,
    input  logic        start_btn,
    input  logic        char_select_btn,
    input  logic        phase_timeout,
    input  logic [7:0]  lfsr_val,
    input  logic [31:0] rom_data,
    input  logic [31:0] crates_hit_mask,
    input  logic [31:0] loot_collected_mask,
    input  logic        p1_dead,
    input  logic        p2_dead
);

typedef enum logic [2:0] {
    ST_INIT        = 3'd0,
    ST_CHAR_SELECT = 3'd1,
    ST_LOOTING     = 3'd2,
    ST_COMBAT      = 3'd3,
    ST_END         = 3'd4
} state_t;

state_t state;
state_t state_nxt;

logic [31:0] active_crates_reg, active_crates_nxt;
logic [31:0] active_loot_reg, active_loot_nxt;
logic [31:0] newly_destroyed_crates;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state             <= ST_INIT;
        active_crates_reg <= 32'h0;
        active_loot_reg   <= 32'h0;
    end else begin
        state             <= state_nxt;
        active_crates_reg <= active_crates_nxt;
        active_loot_reg   <= active_loot_nxt;
    end
end

always_comb begin
    state_nxt              = state;
    active_crates_nxt      = active_crates_reg;
    active_loot_nxt        = active_loot_reg;
    rom_addr               = lfsr_val;
    newly_destroyed_crates = active_crates_reg & crates_hit_mask;

    case (state)
        ST_INIT: begin
            if (start_btn) state_nxt = ST_CHAR_SELECT;
        end

        ST_CHAR_SELECT: begin
            if(char_select_btn) begin
                state_nxt = ST_LOOTING;
                if (is_master) begin
                    active_crates_nxt = rom_data;
                    active_loot_nxt   = 32'h0;
                end
            end
        end
        
        ST_LOOTING: begin
            if (is_master) begin
                active_crates_nxt = active_crates_reg & ~crates_hit_mask;
                active_loot_nxt = (active_loot_reg | newly_destroyed_crates) & ~loot_collected_mask;
            end else begin
                active_crates_nxt = rx_active_crates;
                active_loot_nxt   = rx_active_loot;
            end
            
            if (phase_timeout) begin
                state_nxt         = ST_COMBAT;
                active_crates_nxt = 32'h0;
                active_loot_nxt   = 32'h0;
            end
        end
        
        ST_COMBAT: begin
            if (p1_dead || p2_dead) state_nxt = ST_END;
        end
        
        ST_END: begin
            if (start_btn) state_nxt = ST_INIT;
        end
        
        default: state_nxt = ST_INIT;
    endcase
end

assign current_state = state;
assign active_crates = active_crates_reg;
assign active_loot   = active_loot_reg;

endmodule
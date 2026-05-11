/**
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Game state machine (FSM).
 */

 module game_fsm (
    input  logic        clk,
    input  logic        rst_n,
    output logic [7:0]  rom_addr,
    output logic [31:0] active_crates,
    output logic [1:0]  current_state,
    input  logic        start_btn,
    input  logic        phase_timeout,
    input  logic [7:0]  lfsr_val,
    input  logic [31:0] rom_data,
    input  logic [31:0] crates_hit_mask
);

typedef enum logic [1:0] {
    ST_INIT    = 2'd0,
    ST_LOOTING = 2'd1,
    ST_COMBAT  = 2'd2,
    ST_END     = 2'd3
} state_t;

state_t state, state_nxt;
logic [31:0] active_crates_reg, active_crates_nxt;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state             <= ST_INIT;
        active_crates_reg <= 32'h0;
    end else begin
        state             <= state_nxt;
        active_crates_reg <= active_crates_nxt;
    end
end

always_comb begin
    state_nxt         = state;
    active_crates_nxt = active_crates_reg;
    rom_addr          = lfsr_val; 

    case (state)
        ST_INIT: begin
            if (start_btn) begin
                state_nxt         = ST_LOOTING;
                active_crates_nxt = rom_data;
            end
        end
        
        ST_LOOTING: begin
            active_crates_nxt = active_crates_reg & ~crates_hit_mask;
            
            if (phase_timeout) begin
                state_nxt         = ST_COMBAT;
                active_crates_nxt = 32'h0;
            end
        end
        
        ST_COMBAT: begin
        end
        
        ST_END: begin
            if (start_btn) begin
                state_nxt = ST_INIT;
            end
        end
        
        default: begin
            state_nxt = ST_INIT;
        end
    endcase
end

assign current_state = state;
assign active_crates = active_crates_reg;

endmodule
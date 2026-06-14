`timescale 1 ns / 1 ps

module crates_collision_det (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic        update_tick,      
    
    input  logic [15:0] my_bullet_x,
    input  logic [15:0] my_bullet_y,
    input  logic        my_bullet_active,
    
    input  logic [15:0] enemy_bullet_x,
    input  logic [15:0] enemy_bullet_y,
    input  logic        enemy_bullet_active,
    
    input  logic [15:0] player_x,
    input  logic [15:0] player_y,
    input  logic [15:0] enemy_x,
    input  logic [15:0] enemy_y,
    
    input  logic [31:0] active_crates,
    input  logic [31:0] active_loot,
    
    output logic [31:0] crates_hit_mask,
    output logic [31:0] loot_collected_mask,
    
    output logic        apply_heal,
    output logic        apply_dmg_boost,
    output logic        apply_speed_boost
);

    logic [4:0] crate_idx;
    logic [15:0] crate_x, crate_y;

    crate_lut u_crate_lut (
        .crate_id(crate_idx),
        .crate_x(crate_x),
        .crate_y(crate_y)
    );

    typedef enum logic [1:0] { IDLE, CHECK_CRATES, DONE } state_t;
    state_t state;
    
    logic [31:0] hit_mask_reg, loot_mask_reg;
    logic [31:0] already_looted_reg; 
    
    logic hit_by_me, hit_by_enemy;
    logic looted_by_me, looted_by_enemy;

    always_comb begin
        hit_by_me = (my_bullet_active && my_bullet_x + 4 >= crate_x && my_bullet_x <= crate_x + 32 &&
                     my_bullet_y + 4 >= crate_y && my_bullet_y <= crate_y + 32);
        hit_by_enemy = (enemy_bullet_active && enemy_bullet_x + 4 >= crate_x && enemy_bullet_x <= crate_x + 32 &&
                        enemy_bullet_y + 4 >= crate_y && enemy_bullet_y <= crate_y + 32);

        looted_by_me = (player_x + 32 >= crate_x && player_x <= crate_x + 32 &&
                        player_y + 32 >= crate_y && player_y <= crate_y + 32);
        looted_by_enemy = (enemy_x + 32 >= crate_x && enemy_x <= crate_x + 32 &&
                           enemy_y + 32 >= crate_y && enemy_y <= crate_y + 32);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            crate_idx <= 5'd0;
            crates_hit_mask <= 32'h0;
            loot_collected_mask <= 32'h0;
            hit_mask_reg <= 32'h0;
            loot_mask_reg <= 32'h0;
            already_looted_reg <= 32'h0;
            apply_heal <= 1'b0;
            apply_dmg_boost <= 1'b0;
            apply_speed_boost <= 1'b0;
        end else begin
            apply_heal <= 1'b0;
            apply_dmg_boost <= 1'b0;
            apply_speed_boost <= 1'b0;
            
            // Oczyszczanie latacha gdy serwer fizycznie usunie loot
            for (int i = 0; i < 32; i++) begin
                if (!active_loot[i]) already_looted_reg[i] <= 1'b0;
            end

            case (state)
                IDLE: begin
                    if (update_tick) begin
                        state <= CHECK_CRATES;
                        crate_idx <= 5'd0;
                        hit_mask_reg <= 32'h0;
                        loot_mask_reg <= 32'h0;
                    end
                    crates_hit_mask <= 32'h0;
                    loot_collected_mask <= 32'h0;
                end
                
                CHECK_CRATES: begin
                    if (active_crates[crate_idx]) begin
                        if (hit_by_me || hit_by_enemy) hit_mask_reg[crate_idx] <= 1'b1;
                    end
                    
                    if (active_loot[crate_idx]) begin
                        if (looted_by_me || looted_by_enemy) loot_mask_reg[crate_idx] <= 1'b1;
                        
                        // Przydział bonusów - pojedynczy puls na łup
                        if (looted_by_me && !already_looted_reg[crate_idx]) begin
                            already_looted_reg[crate_idx] <= 1'b1;
                            if (crate_idx % 3 == 0)      apply_heal <= 1'b1;
                            else if (crate_idx % 3 == 1) apply_dmg_boost <= 1'b1;
                            else                         apply_speed_boost <= 1'b1;
                        end
                    end
                    
                    if (crate_idx == 5'd31) state <= DONE;
                    else                    crate_idx <= crate_idx + 1;
                end
                
                DONE: begin
                    crates_hit_mask <= hit_mask_reg;
                    loot_collected_mask <= loot_mask_reg;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
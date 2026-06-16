`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * Dedykowany moduł detekcji kolizji obiektów statycznych (Skrzynie & Łup).
 * Iteruje maszyną stanów po obiektach na mapie, generując impulsy zniszczenia skrzyń
 * pociskiem oraz impulsy przyznania bonusów (leczenie, speed, dmg) po wejściu gracza w łup.
 */

module crates_collision_det (
    input logic clk,
    input logic rst_n,
    output logic [31:0] crates_hit_mask,
    output logic [31:0] loot_collected_mask,
    output logic apply_heal,
    output logic apply_dmg_boost,
    output logic apply_speed_boost,
    input logic update_tick,
    input logic [15:0] my_bullet_x,
    input logic [15:0] my_bullet_y,
    input logic my_bullet_active,
    input logic [15:0] enemy_bullet_x,
    input logic [15:0] enemy_bullet_y,
    input logic enemy_bullet_active,
    input logic [15:0] player_x,
    input logic [15:0] player_y,
    input logic [15:0] enemy_x,
    input logic [15:0] enemy_y,
    input logic [31:0] active_crates,
    input logic [31:0] active_loot
);

/* User defined types and constants */
typedef enum logic [1:0] {
    IDLE,
    CHECK_CRATES,
    DONE
} state_t;

/* Local variables and signals */
state_t state, state_nxt;

logic [4:0] crate_idx, crate_idx_nxt;
logic [15:0] crate_x, crate_y;

logic [31:0] crates_hit_mask_reg, crates_hit_mask_nxt;
logic [31:0] loot_collected_mask_reg, loot_collected_mask_nxt;
logic [31:0] hit_mask_reg, hit_mask_nxt;
logic [31:0] loot_mask_reg, loot_mask_nxt;
logic [31:0] already_looted_reg, already_looted_nxt;

logic apply_heal_reg, apply_heal_nxt;
logic apply_dmg_boost_reg, apply_dmg_boost_nxt;
logic apply_speed_boost_reg, apply_speed_boost_nxt;

logic hit_by_me;
logic hit_by_enemy;
logic looted_by_me;
logic looted_by_enemy;

/* Signals assignments */
assign crates_hit_mask = crates_hit_mask_reg;
assign loot_collected_mask = loot_collected_mask_reg;
assign apply_heal = apply_heal_reg;
assign apply_dmg_boost = apply_dmg_boost_reg;
assign apply_speed_boost = apply_speed_boost_reg;

/* Submodules placement */
crate_lut u_crate_lut (
    .crate_x(crate_x),
    .crate_y(crate_y),
    .crate_id(crate_idx)
);

/* Module internal logic */
always_comb begin
    hit_by_me = (my_bullet_active && (my_bullet_x + 16'd4 >= crate_x) &&
                (my_bullet_x <= crate_x + 16'd32) && (my_bullet_y + 16'd4 >= crate_y) &&
                (my_bullet_y <= crate_y + 16'd32));
                
    hit_by_enemy = (enemy_bullet_active && (enemy_bullet_x + 16'd4 >= crate_x) &&
                   (enemy_bullet_x <= crate_x + 16'd32) && (enemy_bullet_y + 16'd4 >= crate_y) &&
                   (enemy_bullet_y <= crate_y + 16'd32));

    looted_by_me = ((player_x + 16'd32 >= crate_x) && (player_x <= crate_x + 16'd32) &&
                   (player_y + 16'd32 >= crate_y) && (player_y <= crate_y + 16'd32));
                   
    looted_by_enemy = ((enemy_x + 16'd32 >= crate_x) && (enemy_x <= crate_x + 16'd32) &&
                      (enemy_y + 16'd32 >= crate_y) && (enemy_y <= crate_y + 16'd32));
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        crate_idx <= 5'd0;
        crates_hit_mask_reg <= 32'h0;
        loot_collected_mask_reg <= 32'h0;
        hit_mask_reg <= 32'h0;
        loot_mask_reg <= 32'h0;
        already_looted_reg <= 32'h0;
        apply_heal_reg <= 1'b0;
        apply_dmg_boost_reg <= 1'b0;
        apply_speed_boost_reg <= 1'b0;
    end else begin
        state <= state_nxt;
        crate_idx <= crate_idx_nxt;
        crates_hit_mask_reg <= crates_hit_mask_nxt;
        loot_collected_mask_reg <= loot_collected_mask_nxt;
        hit_mask_reg <= hit_mask_nxt;
        loot_mask_reg <= loot_mask_nxt;
        already_looted_reg <= already_looted_nxt;
        apply_heal_reg <= apply_heal_nxt;
        apply_dmg_boost_reg <= apply_dmg_boost_nxt;
        apply_speed_boost_reg <= apply_speed_boost_nxt;
    end
end

always_comb begin
    state_nxt = state;
    crate_idx_nxt = crate_idx;
    crates_hit_mask_nxt = crates_hit_mask_reg;
    loot_collected_mask_nxt = loot_collected_mask_reg;
    hit_mask_nxt = hit_mask_reg;
    loot_mask_nxt = loot_mask_reg;
    already_looted_nxt = already_looted_reg;
    apply_heal_nxt = 1'b0;
    apply_dmg_boost_nxt = 1'b0;
    apply_speed_boost_nxt = 1'b0;

    /* Oczyszczanie latacha gdy serwer fizycznie usunie loot */
    for (int i = 0; i < 32; ++i) begin
        if (!active_loot[i]) begin
            already_looted_nxt[i] = 1'b0;
        end
    end

    case (state)
        IDLE: begin
            if (update_tick) begin
                state_nxt = CHECK_CRATES;
                crate_idx_nxt = 5'd0;
                hit_mask_nxt = 32'h0;
                loot_mask_nxt = 32'h0;
            end
            crates_hit_mask_nxt = 32'h0;
            loot_collected_mask_nxt = 32'h0;
        end

        CHECK_CRATES: begin
            if (active_crates[crate_idx]) begin
                if (hit_by_me || hit_by_enemy) begin
                    hit_mask_nxt[crate_idx] = 1'b1;
                end
            end

            if (active_loot[crate_idx]) begin
                if (looted_by_me || looted_by_enemy) begin
                    loot_mask_nxt[crate_idx] = 1'b1;
                end

                /* Przydzial bonusow - pojedynczy puls na lup */
                if (looted_by_me && !already_looted_reg[crate_idx]) begin
                    already_looted_nxt[crate_idx] = 1'b1;
                    
                    if (crate_idx % 5'd3 == 5'd0) begin
                        apply_heal_nxt = 1'b1;
                    end else if (crate_idx % 5'd3 == 5'd1) begin
                        apply_dmg_boost_nxt = 1'b1;
                    end else begin
                        apply_speed_boost_nxt = 1'b1;
                    end
                end
            end

            if (crate_idx == 5'd31) begin
                state_nxt = DONE;
            end else begin
                crate_idx_nxt = crate_idx + 5'd1;
            end
        end

        DONE: begin
            crates_hit_mask_nxt = hit_mask_reg;
            loot_collected_mask_nxt = loot_mask_reg;
            state_nxt = IDLE;
        end
    endcase
end

endmodule
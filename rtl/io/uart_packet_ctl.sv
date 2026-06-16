`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz
 *
 * Description:
 * Kontroler pakietów sieciowych UART (Protokół Multiplayer).
 * Agreguje pozycje, punkty zdrowia, stan pocisków oraz stan masek skrzyń/łupu.
 * Formuje wielobajtowe ramki sieciowe i odpowiada za synchronizację rozgrywki p2p.
 */

module uart_packet_ctl (
    input logic clk,
    input logic rst_n,
    output logic [15:0] enemy_x,
    output logic [15:0] enemy_y,
    output logic [7:0] enemy_hp,
    output logic take_dmg_en,
    output logic [7:0] take_dmg_val,
    output logic [15:0] enemy_bullet_x,
    output logic [15:0] enemy_bullet_y,
    output logic enemy_bullet_active,
    output logic [31:0] rx_active_crates,
    output logic [31:0] rx_active_loot,
    output logic tx_start,
    output logic [7:0] tx_data,
    input logic send_tick,
    input logic [15:0] my_x,
    input logic [15:0] my_y,
    input logic [7:0] my_hp,
    input logic hit_enemy,
    input logic [7:0] my_bullet_dmg,
    input logic [15:0] my_bullet_x,
    input logic [15:0] my_bullet_y,
    input logic my_bullet_active,
    input logic [31:0] my_active_crates,
    input logic [31:0] my_active_loot,
    input logic tx_busy,
    input logic [7:0] rx_data,
    input logic rx_ready
);

/* User defined types and constants */
localparam logic [7:0] HEADER_BYTE = 8'hAA;
localparam logic [4:0] PACKET_SIZE = 5'd20;

typedef enum logic [1:0] {
    TX_IDLE,
    TX_SEND,
    TX_WAIT_ACK,
    TX_WAIT_BUSY
} tx_state_t;

/* Local variables and signals */
tx_state_t tx_state_reg, tx_state_nxt;

logic [7:0] tx_packet_reg [20];
logic [7:0] tx_packet_nxt [20];
logic [4:0] tx_byte_cnt_reg, tx_byte_cnt_nxt;
logic [7:0] pending_dmg_reg, pending_dmg_nxt;
logic tx_start_reg, tx_start_nxt;
logic [7:0] tx_data_reg, tx_data_nxt;

logic [7:0] rx_packet_reg [20];
logic [7:0] rx_packet_nxt [20];
logic [4:0] rx_byte_cnt_reg, rx_byte_cnt_nxt;
logic [17:0] rx_timeout_reg, rx_timeout_nxt;

logic [15:0] enemy_x_reg, enemy_x_nxt;
logic [15:0] enemy_y_reg, enemy_y_nxt;
logic [7:0] enemy_hp_reg, enemy_hp_nxt;
logic take_dmg_en_reg, take_dmg_en_nxt;
logic [7:0] take_dmg_val_reg, take_dmg_val_nxt;
logic [15:0] enemy_bullet_x_reg, enemy_bullet_x_nxt;
logic [15:0] enemy_bullet_y_reg, enemy_bullet_y_nxt;
logic enemy_bullet_active_reg, enemy_bullet_active_nxt;
logic [31:0] rx_active_crates_reg, rx_active_crates_nxt;
logic [31:0] rx_active_loot_reg, rx_active_loot_nxt;

/* Signals assignments */
assign enemy_x = enemy_x_reg;
assign enemy_y = enemy_y_reg;
assign enemy_hp = enemy_hp_reg;
assign take_dmg_en = take_dmg_en_reg;
assign take_dmg_val = take_dmg_val_reg;
assign enemy_bullet_x = enemy_bullet_x_reg;
assign enemy_bullet_y = enemy_bullet_y_reg;
assign enemy_bullet_active = enemy_bullet_active_reg;
assign rx_active_crates = rx_active_crates_reg;
assign rx_active_loot = rx_active_loot_reg;
assign tx_start = tx_start_reg;
assign tx_data = tx_data_reg;

/* Module internal logic */

/* TX Combinational Logic */
always_comb begin
    tx_state_nxt = tx_state_reg;
    tx_start_nxt = 1'b0;
    tx_data_nxt = tx_data_reg;
    tx_byte_cnt_nxt = tx_byte_cnt_reg;
    pending_dmg_nxt = pending_dmg_reg;
    
    for (int i = 0; i < 20; ++i) begin
        tx_packet_nxt[i] = tx_packet_reg[i];
    end

    if (hit_enemy) begin
        pending_dmg_nxt = my_bullet_dmg;
    end

    case (tx_state_reg)
        TX_IDLE: begin
            if (send_tick) begin
                tx_packet_nxt[0] = HEADER_BYTE;
                tx_packet_nxt[1] = my_x[15:8];
                tx_packet_nxt[2] = my_x[7:0];
                tx_packet_nxt[3] = my_y[15:8];
                tx_packet_nxt[4] = my_y[7:0];
                tx_packet_nxt[5] = my_hp;
                
                if (hit_enemy) begin
                    tx_packet_nxt[6] = my_bullet_dmg;
                end else begin
                    tx_packet_nxt[6] = pending_dmg_reg;
                end
                
                tx_packet_nxt[7] = my_bullet_x[15:8];
                tx_packet_nxt[8] = my_bullet_x[7:0];
                tx_packet_nxt[9] = my_bullet_y[15:8];
                tx_packet_nxt[10] = my_bullet_y[7:0];
                tx_packet_nxt[11] = {7'd0, my_bullet_active};
                tx_packet_nxt[12] = my_active_crates[31:24];
                tx_packet_nxt[13] = my_active_crates[23:16];
                tx_packet_nxt[14] = my_active_crates[15:8];
                tx_packet_nxt[15] = my_active_crates[7:0];
                tx_packet_nxt[16] = my_active_loot[31:24];
                tx_packet_nxt[17] = my_active_loot[23:16];
                tx_packet_nxt[18] = my_active_loot[15:8];
                tx_packet_nxt[19] = my_active_loot[7:0];
                
                pending_dmg_nxt = 8'h0; 
                tx_byte_cnt_nxt = 5'd0;
                tx_state_nxt = TX_SEND;
            end
        end
        
        TX_SEND: begin
            tx_data_nxt = tx_packet_reg[tx_byte_cnt_reg];
            tx_start_nxt = 1'b1;
            tx_state_nxt = TX_WAIT_ACK;
        end
        
        TX_WAIT_ACK: begin
            if (tx_busy) begin
                tx_state_nxt = TX_WAIT_BUSY;
            end
        end
        
        TX_WAIT_BUSY: begin
            if (!tx_busy) begin
                if (tx_byte_cnt_reg == (PACKET_SIZE - 5'd1)) begin
                    tx_state_nxt = TX_IDLE;
                end else begin
                    tx_byte_cnt_nxt = tx_byte_cnt_reg + 5'd1;
                    tx_state_nxt = TX_SEND;
                end
            end
        end
        
        default: begin
            tx_state_nxt = TX_IDLE;
        end
    endcase
end

/* RX Combinational Logic */
always_comb begin
    rx_byte_cnt_nxt = rx_byte_cnt_reg;
    rx_timeout_nxt = rx_timeout_reg;
    enemy_x_nxt = enemy_x_reg;
    enemy_y_nxt = enemy_y_reg;
    enemy_hp_nxt = enemy_hp_reg;
    take_dmg_en_nxt = 1'b0;
    take_dmg_val_nxt = take_dmg_val_reg;
    enemy_bullet_x_nxt = enemy_bullet_x_reg;
    enemy_bullet_y_nxt = enemy_bullet_y_reg;
    enemy_bullet_active_nxt = enemy_bullet_active_reg;
    rx_active_crates_nxt = rx_active_crates_reg;
    rx_active_loot_nxt = rx_active_loot_reg;

    for (int i = 0; i < 20; ++i) begin
        rx_packet_nxt[i] = rx_packet_reg[i];
    end

    if (rx_byte_cnt_reg > 5'd0) begin
        rx_timeout_nxt = rx_timeout_reg + 18'd1;
        if (rx_timeout_reg > 18'd100_000) begin
            rx_byte_cnt_nxt = 5'd0;
        end
    end else begin
        rx_timeout_nxt = 18'd0;
    end

    if (rx_ready) begin
        rx_timeout_nxt = 18'd0; 
        
        if (rx_byte_cnt_reg == 5'd0) begin
            if (rx_data == HEADER_BYTE) begin
                rx_packet_nxt[0] = rx_data;
                rx_byte_cnt_nxt = 5'd1;
            end
        end else begin
            rx_packet_nxt[rx_byte_cnt_reg] = rx_data;
            
            if (rx_byte_cnt_reg == (PACKET_SIZE - 5'd1)) begin
                enemy_x_nxt = {rx_packet_reg[1], rx_packet_reg[2]};
                enemy_y_nxt = {rx_packet_reg[3], rx_packet_reg[4]};
                enemy_hp_nxt = rx_packet_reg[5];
                
                if (rx_packet_reg[6] > 8'd0) begin
                    take_dmg_en_nxt = 1'b1;
                    take_dmg_val_nxt = rx_packet_reg[6];
                end
                
                enemy_bullet_x_nxt = {rx_packet_reg[7], rx_packet_reg[8]};
                enemy_bullet_y_nxt = {rx_packet_reg[9], rx_packet_reg[10]};
                enemy_bullet_active_nxt = rx_packet_reg[11][0];
                rx_active_crates_nxt = {rx_packet_reg[12], rx_packet_reg[13], rx_packet_reg[14], rx_packet_reg[15]};
                rx_active_loot_nxt = {rx_packet_reg[16], rx_packet_reg[17], rx_packet_reg[18], rx_data};
                
                rx_byte_cnt_nxt = 5'd0;
            end else begin
                rx_byte_cnt_nxt = rx_byte_cnt_reg + 5'd1;
            end
        end
    end
end

/* Sequential Logic */
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_state_reg <= TX_IDLE;
        tx_start_reg <= 1'b0;
        tx_data_reg <= 8'h0;
        tx_byte_cnt_reg <= 5'd0;
        pending_dmg_reg <= 8'h0;
        tx_packet_reg <= '{default: 8'h0};
        
        rx_byte_cnt_reg <= 5'd0;
        rx_timeout_reg <= 18'd0;
        enemy_x_reg <= 16'd0;
        enemy_y_reg <= 16'd0;
        enemy_hp_reg <= 8'd0;
        take_dmg_en_reg <= 1'b0;
        take_dmg_val_reg <= 8'd0;
        enemy_bullet_x_reg <= 16'd0;
        enemy_bullet_y_reg <= 16'd0;
        enemy_bullet_active_reg <= 1'b0;
        rx_active_crates_reg <= 32'h0;
        rx_active_loot_reg <= 32'h0;
        rx_packet_reg <= '{default: 8'h0};
    end else begin
        tx_state_reg <= tx_state_nxt;
        tx_start_reg <= tx_start_nxt;
        tx_data_reg <= tx_data_nxt;
        tx_byte_cnt_reg <= tx_byte_cnt_nxt;
        pending_dmg_reg <= pending_dmg_nxt;
        tx_packet_reg <= tx_packet_nxt;
        
        rx_byte_cnt_reg <= rx_byte_cnt_nxt;
        rx_timeout_reg <= rx_timeout_nxt;
        enemy_x_reg <= enemy_x_nxt;
        enemy_y_reg <= enemy_y_nxt;
        enemy_hp_reg <= enemy_hp_nxt;
        take_dmg_en_reg <= take_dmg_en_nxt;
        take_dmg_val_reg <= take_dmg_val_nxt;
        enemy_bullet_x_reg <= enemy_bullet_x_nxt;
        enemy_bullet_y_reg <= enemy_bullet_y_nxt;
        enemy_bullet_active_reg <= enemy_bullet_active_nxt;
        rx_active_crates_reg <= rx_active_crates_nxt;
        rx_active_loot_reg <= rx_active_loot_nxt;
        rx_packet_reg <= rx_packet_nxt;
    end
end

endmodule
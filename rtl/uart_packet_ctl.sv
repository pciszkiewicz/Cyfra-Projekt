`timescale 1 ns / 1 ps

module uart_packet_ctl (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        send_tick,

    input  logic [15:0] my_x,
    input  logic [15:0] my_y,
    input  logic [7:0]  my_hp,
    input  logic        hit_enemy,      
    input  logic [7:0]  my_bullet_dmg,  
    
    input  logic [15:0] my_bullet_x,
    input  logic [15:0] my_bullet_y,
    input  logic        my_bullet_active,
    input  logic [31:0] my_active_crates,
    input  logic [31:0] my_active_loot,

    output logic [15:0] enemy_x,
    output logic [15:0] enemy_y,
    output logic [7:0]  enemy_hp,
    output logic        take_dmg_en,
    output logic [7:0]  take_dmg_val,

    output logic [15:0] enemy_bullet_x,
    output logic [15:0] enemy_bullet_y,
    output logic        enemy_bullet_active,
    output logic [31:0] rx_active_crates,
    output logic [31:0] rx_active_loot,

    output logic        tx_start,
    output logic [7:0]  tx_data,
    input  logic        tx_busy,

    input  logic [7:0]  rx_data,
    input  logic        rx_ready
);

    localparam logic [7:0] HEADER_BYTE = 8'hAA;
    localparam int PACKET_SIZE = 20;

    logic [7:0] tx_packet [0:19];
    logic [4:0] tx_byte_cnt;
    logic [7:0] pending_dmg_reg;
    
    typedef enum logic [1:0] { TX_IDLE, TX_SEND, TX_WAIT_ACK, TX_WAIT_BUSY } tx_state_t;
    tx_state_t tx_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state <= TX_IDLE;
            tx_start <= 1'b0;
            tx_data  <= 8'h0;
            tx_byte_cnt <= '0;
            pending_dmg_reg <= '0;
            tx_packet <= '{default: 8'h0};
        end else begin
            tx_start <= 1'b0; 
            
            if (hit_enemy) pending_dmg_reg <= my_bullet_dmg;

            case (tx_state)
                TX_IDLE: begin
                    if (send_tick) begin
                        tx_packet[0]  <= HEADER_BYTE;
                        tx_packet[1]  <= my_x[15:8];
                        tx_packet[2]  <= my_x[7:0];
                        tx_packet[3]  <= my_y[15:8];
                        tx_packet[4]  <= my_y[7:0];
                        tx_packet[5]  <= my_hp;
                        tx_packet[6]  <= hit_enemy ? my_bullet_dmg : pending_dmg_reg;
                        tx_packet[7]  <= my_bullet_x[15:8];
                        tx_packet[8]  <= my_bullet_x[7:0];
                        tx_packet[9]  <= my_bullet_y[15:8];
                        tx_packet[10] <= my_bullet_y[7:0];
                        tx_packet[11] <= {7'd0, my_bullet_active};
                        tx_packet[12] <= my_active_crates[31:24];
                        tx_packet[13] <= my_active_crates[23:16];
                        tx_packet[14] <= my_active_crates[15:8];
                        tx_packet[15] <= my_active_crates[7:0];
                        tx_packet[16] <= my_active_loot[31:24];
                        tx_packet[17] <= my_active_loot[23:16];
                        tx_packet[18] <= my_active_loot[15:8];
                        tx_packet[19] <= my_active_loot[7:0];
                        
                        pending_dmg_reg <= 8'h0; 
                        tx_byte_cnt <= '0;
                        tx_state <= TX_SEND;
                    end
                end
                
                TX_SEND: begin
                    tx_data <= tx_packet[tx_byte_cnt];
                    tx_start <= 1'b1;
                    tx_state <= TX_WAIT_ACK;
                end
                
                TX_WAIT_ACK: begin
                    if (tx_busy) tx_state <= TX_WAIT_BUSY;
                end
                
                TX_WAIT_BUSY: begin
                    if (!tx_busy) begin
                        if (tx_byte_cnt == PACKET_SIZE - 1) begin
                            tx_state <= TX_IDLE;
                        end else begin
                            tx_byte_cnt <= tx_byte_cnt + 1;
                            tx_state <= TX_SEND;
                        end
                    end
                end
            endcase
        end
    end

    logic [7:0] rx_packet [0:19];
    logic [4:0] rx_byte_cnt;
    logic [17:0] rx_timeout_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_byte_cnt <= '0;
            rx_timeout_reg <= '0;
            enemy_x <= '0;
            enemy_y <= '0;
            enemy_hp <= '0;
            take_dmg_en <= 1'b0;
            take_dmg_val <= '0;
            enemy_bullet_x <= '0;
            enemy_bullet_y <= '0;
            enemy_bullet_active <= 1'b0;
            rx_active_crates <= '0;
            rx_active_loot <= '0;
            rx_packet <= '{default: 8'h0};
        end else begin
            take_dmg_en <= 1'b0;
            
            if (rx_byte_cnt > 0) begin
                rx_timeout_reg <= rx_timeout_reg + 1;
                if (rx_timeout_reg > 18'd100_000) rx_byte_cnt <= '0;
            end else begin
                rx_timeout_reg <= '0;
            end

            if (rx_ready) begin
                rx_timeout_reg <= '0; 
                if (rx_byte_cnt == 0) begin
                    if (rx_data == HEADER_BYTE) begin
                        rx_packet[0] <= rx_data;
                        rx_byte_cnt <= 1;
                    end
                end else begin
                    rx_packet[rx_byte_cnt] <= rx_data;
                    if (rx_byte_cnt == PACKET_SIZE - 1) begin
                        enemy_x <= {rx_packet[1], rx_packet[2]};
                        enemy_y <= {rx_packet[3], rx_packet[4]};
                        enemy_hp <= rx_packet[5];
                        if (rx_packet[6] > 0) begin
                            take_dmg_en <= 1'b1;
                            take_dmg_val <= rx_packet[6];
                        end
                        enemy_bullet_x <= {rx_packet[7], rx_packet[8]};
                        enemy_bullet_y <= {rx_packet[9], rx_packet[10]};
                        enemy_bullet_active <= rx_packet[11][0];
                        rx_active_crates <= {rx_packet[12], rx_packet[13], rx_packet[14], rx_packet[15]};
                        rx_active_loot   <= {rx_packet[16], rx_packet[17], rx_packet[18], rx_packet[19]};
                        
                        rx_byte_cnt <= 0;
                    end else begin
                        rx_byte_cnt <= rx_byte_cnt + 1;
                    end
                end
            end
        end
    end
endmodule
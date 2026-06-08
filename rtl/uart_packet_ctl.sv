`timescale 1 ns / 1 ps

module uart_packet_ctl (
    input  logic        clk,
    input  logic        rst_n,

    // Sygnał wyzwalający wysyłanie
    input  logic        send_tick,

    // Dane lokalnego gracza
    input  logic [15:0] my_x,
    input  logic [15:0] my_y,
    input  logic [7:0]  my_hp,
    
    // Sygnały kolizji i zadanych obrażeń do wysłania przeciwnikowi
    input  logic        hit_enemy,      
    input  logic [7:0]  my_bullet_dmg,  

    // Zdekodowane dane przeciwnika
    output logic [15:0] enemy_x,
    output logic [15:0] enemy_y,
    output logic [7:0]  enemy_hp,
    
    // Zdekodowane impulsy obrażeń zadanych nam przez wroga
    output logic        take_dmg_en,
    output logic [7:0]  take_dmg_val,

    // Interfejs do modułu UART TX
    output logic        tx_start,
    output logic [7:0]  tx_data,
    input  logic        tx_busy,

    // Interfejs z modułu UART RX
    input  logic [7:0]  rx_data,
    input  logic        rx_ready
);

    localparam logic [7:0] HEADER_BYTE = 8'hAA;

    // =========================================================================
    // NADAJNIK (TX FSM) - Handshake z idealnym, 1-taktowym impulsem tx_start
    // =========================================================================
    typedef enum logic [4:0] {
        TX_IDLE,
        TX_SEND_HDR, TX_WAIT_ACK_HDR, TX_WAIT_HDR,
        TX_SEND_XH,  TX_WAIT_ACK_XH,  TX_WAIT_XH,
        TX_SEND_XL,  TX_WAIT_ACK_XL,  TX_WAIT_XL,
        TX_SEND_YH,  TX_WAIT_ACK_YH,  TX_WAIT_YH,
        TX_SEND_YL,  TX_WAIT_ACK_YL,  TX_WAIT_YL,
        TX_SEND_HP,  TX_WAIT_ACK_HP,  TX_WAIT_HP,
        TX_SEND_DMG, TX_WAIT_ACK_DMG, TX_WAIT_DMG
    } tx_state_t;

    tx_state_t tx_state_reg, tx_state_nxt;
    
    logic [15:0] latched_x_reg, latched_x_nxt;
    logic [15:0] latched_y_reg, latched_y_nxt;
    logic [7:0]  latched_hp_reg, latched_hp_nxt;
    logic [7:0]  latched_dmg_reg, latched_dmg_nxt;
    logic [7:0]  pending_dmg_reg, pending_dmg_nxt; 

    logic        tx_start_reg, tx_start_nxt;
    logic [7:0]  tx_data_reg, tx_data_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state_reg    <= TX_IDLE;
            latched_x_reg   <= '0;
            latched_y_reg   <= '0;
            latched_hp_reg  <= '0;
            latched_dmg_reg <= '0;
            pending_dmg_reg <= '0;
            tx_start_reg    <= 1'b0;
            tx_data_reg     <= '0;
        end else begin
            tx_state_reg    <= tx_state_nxt;
            latched_x_reg   <= latched_x_nxt;
            latched_y_reg   <= latched_y_nxt;
            latched_hp_reg  <= latched_hp_nxt;
            latched_dmg_reg <= latched_dmg_nxt;
            pending_dmg_reg <= pending_dmg_nxt;
            tx_start_reg    <= tx_start_nxt;
            tx_data_reg     <= tx_data_nxt;
        end
    end

    always_comb begin
        tx_state_nxt    = tx_state_reg;
        latched_x_nxt   = latched_x_reg;
        latched_y_nxt   = latched_y_reg;
        latched_hp_nxt  = latched_hp_reg;
        latched_dmg_nxt = latched_dmg_reg;
        pending_dmg_nxt = pending_dmg_reg;
        
        // Domyślne zerowanie gwarantuje, że impuls tx_start trwa tylko 1 takt
        tx_start_nxt    = 1'b0;
        tx_data_nxt     = tx_data_reg;

        // Łapanie strzału
        if (hit_enemy) pending_dmg_nxt = my_bullet_dmg;

        case (tx_state_reg)
            TX_IDLE: begin
                if (send_tick) begin
                    latched_x_nxt   = my_x;
                    latched_y_nxt   = my_y;
                    latched_hp_nxt  = my_hp; // Zwrócone pełne wartości (bez maskowania)
                    latched_dmg_nxt = hit_enemy ? my_bullet_dmg : pending_dmg_reg; 
                    pending_dmg_nxt = 8'h0;            
                    tx_state_nxt    = TX_SEND_HDR;
                end
            end
            
            // Nagłówek
            TX_SEND_HDR:     begin tx_data_nxt = HEADER_BYTE; tx_start_nxt = 1'b1; tx_state_nxt = TX_WAIT_ACK_HDR; end
            TX_WAIT_ACK_HDR: begin if (tx_busy) tx_state_nxt = TX_WAIT_HDR; end // Czeka na reakcję modułu
            TX_WAIT_HDR:     begin if (!tx_busy) tx_state_nxt = TX_SEND_XH; end // Czeka na zakończenie wysyłania
            
            // XH
            TX_SEND_XH:      begin tx_data_nxt = latched_x_reg[15:8]; tx_start_nxt = 1'b1; tx_state_nxt = TX_WAIT_ACK_XH; end
            TX_WAIT_ACK_XH:  begin if (tx_busy) tx_state_nxt = TX_WAIT_XH; end
            TX_WAIT_XH:      begin if (!tx_busy) tx_state_nxt = TX_SEND_XL; end
            
            // XL
            TX_SEND_XL:      begin tx_data_nxt = latched_x_reg[7:0]; tx_start_nxt = 1'b1; tx_state_nxt = TX_WAIT_ACK_XL; end
            TX_WAIT_ACK_XL:  begin if (tx_busy) tx_state_nxt = TX_WAIT_XL; end
            TX_WAIT_XL:      begin if (!tx_busy) tx_state_nxt = TX_SEND_YH; end
            
            // YH
            TX_SEND_YH:      begin tx_data_nxt = latched_y_reg[15:8]; tx_start_nxt = 1'b1; tx_state_nxt = TX_WAIT_ACK_YH; end
            TX_WAIT_ACK_YH:  begin if (tx_busy) tx_state_nxt = TX_WAIT_YH; end
            TX_WAIT_YH:      begin if (!tx_busy) tx_state_nxt = TX_SEND_YL; end
            
            // YL
            TX_SEND_YL:      begin tx_data_nxt = latched_y_reg[7:0]; tx_start_nxt = 1'b1; tx_state_nxt = TX_WAIT_ACK_YL; end
            TX_WAIT_ACK_YL:  begin if (tx_busy) tx_state_nxt = TX_WAIT_YL; end
            TX_WAIT_YL:      begin if (!tx_busy) tx_state_nxt = TX_SEND_HP; end
            
            // HP
            TX_SEND_HP:      begin tx_data_nxt = latched_hp_reg; tx_start_nxt = 1'b1; tx_state_nxt = TX_WAIT_ACK_HP; end
            TX_WAIT_ACK_HP:  begin if (tx_busy) tx_state_nxt = TX_WAIT_HP; end
            TX_WAIT_HP:      begin if (!tx_busy) tx_state_nxt = TX_SEND_DMG; end 
            
            // DMG
            TX_SEND_DMG:     begin tx_data_nxt = latched_dmg_reg; tx_start_nxt = 1'b1; tx_state_nxt = TX_WAIT_ACK_DMG; end
            TX_WAIT_ACK_DMG: begin if (tx_busy) tx_state_nxt = TX_WAIT_DMG; end
            TX_WAIT_DMG:     begin if (!tx_busy) tx_state_nxt = TX_IDLE; end
            
            default: tx_state_nxt = TX_IDLE;
        endcase
    end

    assign tx_start = tx_start_reg;
    assign tx_data  = tx_data_reg;

    // =========================================================================
    // ODBIORNIK (RX FSM) - z Watchdogiem
    // =========================================================================
    typedef enum logic [3:0] {
        RX_IDLE, 
        RX_GET_XH, RX_GET_XL,
        RX_GET_YH, RX_GET_YL,
        RX_GET_HP, RX_GET_DMG
    } rx_state_t;

    rx_state_t rx_state_reg, rx_state_nxt;
    
    logic [17:0] rx_timeout_reg, rx_timeout_nxt;
    
    logic [15:0] rx_x_buf_reg, rx_x_buf_nxt;
    logic [15:0] rx_y_buf_reg, rx_y_buf_nxt;
    logic [7:0]  rx_hp_buf_reg, rx_hp_buf_nxt;
    
    logic [15:0] enemy_x_reg, enemy_x_nxt;
    logic [15:0] enemy_y_reg, enemy_y_nxt;
    logic [7:0]  enemy_hp_reg, enemy_hp_nxt;
    
    logic       td_en_reg, td_en_nxt;
    logic [7:0] td_val_reg, td_val_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state_reg   <= RX_IDLE;
            rx_timeout_reg <= '0;
            rx_x_buf_reg   <= '0;
            rx_y_buf_reg   <= '0;
            rx_hp_buf_reg  <= '0;
            enemy_x_reg    <= '0;
            enemy_y_reg    <= '0;
            enemy_hp_reg   <= '0;
            td_en_reg      <= 1'b0;
            td_val_reg     <= '0;
        end else begin
            rx_state_reg   <= rx_state_nxt;
            rx_timeout_reg <= rx_timeout_nxt;
            rx_x_buf_reg   <= rx_x_buf_nxt;
            rx_y_buf_reg   <= rx_y_buf_nxt;
            rx_hp_buf_reg  <= rx_hp_buf_nxt;
            enemy_x_reg    <= enemy_x_nxt;
            enemy_y_reg    <= enemy_y_nxt;
            enemy_hp_reg   <= enemy_hp_nxt;
            td_en_reg      <= td_en_nxt;
            td_val_reg     <= td_val_nxt;
        end
    end

    always_comb begin
        rx_state_nxt   = rx_state_reg;
        rx_timeout_nxt = rx_timeout_reg;
        rx_x_buf_nxt   = rx_x_buf_reg;
        rx_y_buf_nxt   = rx_y_buf_reg;
        rx_hp_buf_nxt  = rx_hp_buf_reg;
        enemy_x_nxt    = enemy_x_reg;
        enemy_y_nxt    = enemy_y_reg;
        enemy_hp_nxt   = enemy_hp_reg;
        
        td_val_nxt     = td_val_reg;
        td_en_nxt      = 1'b0; 

        if (rx_state_reg == RX_IDLE) begin
            rx_timeout_nxt = 18'd0;
        end else begin
            rx_timeout_nxt = rx_timeout_reg + 1;
        end

        // Ratunkowy reset FSM jeśli drugi gracz odłączył kabel lub zgubił bajt (czas > 1.5ms)
        if (rx_timeout_reg > 18'd100_000) begin
            rx_state_nxt = RX_IDLE;
        end 
        else if (rx_ready) begin
            rx_timeout_nxt = 18'd0; 
            
            case (rx_state_reg)
                RX_IDLE:    if (rx_data == HEADER_BYTE) rx_state_nxt = RX_GET_XH;
                
                RX_GET_XH:  begin rx_x_buf_nxt[15:8] = rx_data; rx_state_nxt = RX_GET_XL; end
                RX_GET_XL:  begin rx_x_buf_nxt[7:0]  = rx_data; rx_state_nxt = RX_GET_YH; end
                RX_GET_YH:  begin rx_y_buf_nxt[15:8] = rx_data; rx_state_nxt = RX_GET_YL; end
                RX_GET_YL:  begin rx_y_buf_nxt[7:0]  = rx_data; rx_state_nxt = RX_GET_HP; end
                RX_GET_HP:  begin rx_hp_buf_nxt      = rx_data; rx_state_nxt = RX_GET_DMG; end
                
                RX_GET_DMG: begin 
                    if (rx_data > 0) begin
                        td_en_nxt  = 1'b1;
                        td_val_nxt = rx_data;
                    end
                    enemy_x_nxt  = rx_x_buf_reg;
                    enemy_y_nxt  = rx_y_buf_reg;
                    enemy_hp_nxt = rx_hp_buf_reg;
                    rx_state_nxt = RX_IDLE;
                end
                default: rx_state_nxt = RX_IDLE;
            endcase
        end
    end

    assign enemy_x      = enemy_x_reg;
    assign enemy_y      = enemy_y_reg;
    assign enemy_hp     = enemy_hp_reg;
    assign take_dmg_en  = td_en_reg;
    assign take_dmg_val = td_val_reg;

endmodule
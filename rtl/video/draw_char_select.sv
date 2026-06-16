`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Ekran wyboru klasy postaci (Character Selection Screen).
 * Odpowiada za wizualizację kafelków klas, obsługę podświetlenia (hover)
 * oraz dynamiczne rysowanie pasków statystyk (HP, Speed, DMG) wybranej postaci.
 */

module draw_char_select (
    input logic clk,
    input logic rst_n,
    output logic [1:0] class_id,
    output logic char_select_button,
    vga_if.out out,
    input logic [2:0] current_state,
    input logic [11:0] mouse_x,
    input logic [11:0] mouse_y,
    input logic mouse_left,
    vga_if.in in
);

/* Local parameters */
localparam logic [11:0] BTN_W = 12'd150;
localparam logic [11:0] BTN_H = 12'd150;
localparam logic [11:0] BTN_Y = 12'd500;

localparam logic [11:0] B0_X = 12'd136;
localparam logic [11:0] B1_X = 12'd336;
localparam logic [11:0] B2_X = 12'd536;
localparam logic [11:0] B3_X = 12'd736;

localparam logic [11:0] PANEL_X = 12'd262;
localparam logic [11:0] PANEL_Y = 12'd150;
localparam logic [11:0] PANEL_W = 12'd500;
localparam logic [11:0] PANEL_H = 12'd250;

localparam logic [11:0] BAR_X = 12'd400;
localparam logic [11:0] BAR_H = 12'd24;
localparam logic [11:0] HP_Y = 12'd200;
localparam logic [11:0] SPD_Y = 12'd260;
localparam logic [11:0] DMG_Y = 12'd320;

/* Local variables and signals */
logic mouse_left_prev_reg, mouse_left_prev_nxt;
logic click_pulse;

logic hover0, hover1, hover2, hover3;
logic [1:0] viewed_class;
logic [11:0] bar_hp_w, bar_spd_w, bar_dmg_w;

logic [10:0] hcount_d1_reg, hcount_d1_nxt;
logic [10:0] vcount_d1_reg, vcount_d1_nxt;
logic hsync_d1_reg, hsync_d1_nxt;
logic vsync_d1_reg, vsync_d1_nxt;
logic hblnk_d1_reg, hblnk_d1_nxt;
logic vblnk_d1_reg, vblnk_d1_nxt;
logic [11:0] rgb_d1_reg, rgb_d1_nxt;

logic [1:0] class_id_reg, class_id_nxt;
logic char_select_btn_reg, char_select_btn_nxt;

logic in_panel, in_bar_hp, in_bar_spd, in_bar_dmg;
logic in_b0, in_b1, in_b2, in_b3;
logic [11:0] rgb_nxt;

/* Signals assignments */
assign click_pulse = mouse_left & (!mouse_left_prev_reg);
assign class_id = class_id_reg;
assign char_select_button = char_select_btn_reg;

/* Module internal logic */
always_comb begin
    hover0 = (mouse_x >= B0_X) && (mouse_x < B0_X + BTN_W) && (mouse_y >= BTN_Y) && (mouse_y < BTN_Y + BTN_H);
    hover1 = (mouse_x >= B1_X) && (mouse_x < B1_X + BTN_W) && (mouse_y >= BTN_Y) && (mouse_y < BTN_Y + BTN_H);
    hover2 = (mouse_x >= B2_X) && (mouse_x < B2_X + BTN_W) && (mouse_y >= BTN_Y) && (mouse_y < BTN_Y + BTN_H);
    hover3 = (mouse_x >= B3_X) && (mouse_x < B3_X + BTN_W) && (mouse_y >= BTN_Y) && (mouse_y < BTN_Y + BTN_H);

    if (hover1) begin
        viewed_class = 2'd1;
    end else if (hover2) begin
        viewed_class = 2'd2;
    end else if (hover3) begin
        viewed_class = 2'd3;
    end else begin
        viewed_class = 2'd0;
    end

    bar_hp_w = 12'd150;
    bar_spd_w = 12'd200;
    bar_dmg_w = 12'd150;

    case (viewed_class)
        2'd0: begin
            bar_hp_w = 12'd150;
            bar_spd_w = 12'd200;
            bar_dmg_w = 12'd150;
        end
        2'd1: begin
            bar_hp_w = 12'd300;
            bar_spd_w = 12'd100;
            bar_dmg_w = 12'd90;
        end
        2'd2: begin
            bar_hp_w = 12'd112;
            bar_spd_w = 12'd300;
            bar_dmg_w = 12'd60;
        end
        2'd3: begin
            bar_hp_w = 12'd75;
            bar_spd_w = 12'd150;
            bar_dmg_w = 12'd300;
        end
        default: begin
            bar_hp_w = 12'd150;
            bar_spd_w = 12'd200;
            bar_dmg_w = 12'd150;
        end
    endcase

    in_panel = (hcount_d1_reg >= PANEL_X) && (hcount_d1_reg < PANEL_X + PANEL_W) &&
               (vcount_d1_reg >= PANEL_Y) && (vcount_d1_reg < PANEL_Y + PANEL_H);
    in_bar_hp = (hcount_d1_reg >= BAR_X) && (hcount_d1_reg < BAR_X + bar_hp_w) &&
                (vcount_d1_reg >= HP_Y) && (vcount_d1_reg < HP_Y + BAR_H);
    in_bar_spd = (hcount_d1_reg >= BAR_X) && (hcount_d1_reg < BAR_X + bar_spd_w) &&
                 (vcount_d1_reg >= SPD_Y) && (vcount_d1_reg < SPD_Y + BAR_H);
    in_bar_dmg = (hcount_d1_reg >= BAR_X) && (hcount_d1_reg < BAR_X + bar_dmg_w) &&
                 (vcount_d1_reg >= DMG_Y) && (vcount_d1_reg < DMG_Y + BAR_H);
    
    in_b0 = (hcount_d1_reg >= B0_X) && (hcount_d1_reg < B0_X + BTN_W) &&
            (vcount_d1_reg >= BTN_Y) && (vcount_d1_reg < BTN_Y + BTN_H);
    in_b1 = (hcount_d1_reg >= B1_X) && (hcount_d1_reg < B1_X + BTN_W) &&
            (vcount_d1_reg >= BTN_Y) && (vcount_d1_reg < BTN_Y + BTN_H);
    in_b2 = (hcount_d1_reg >= B2_X) && (hcount_d1_reg < B2_X + BTN_W) &&
            (vcount_d1_reg >= BTN_Y) && (vcount_d1_reg < BTN_Y + BTN_H);
    in_b3 = (hcount_d1_reg >= B3_X) && (hcount_d1_reg < B3_X + BTN_W) &&
            (vcount_d1_reg >= BTN_Y) && (vcount_d1_reg < BTN_Y + BTN_H);

    mouse_left_prev_nxt = mouse_left;
    hcount_d1_nxt = in.hcount;
    vcount_d1_nxt = in.vcount;
    hsync_d1_nxt = in.hsync;
    vsync_d1_nxt = in.vsync;
    hblnk_d1_nxt = in.hblnk;
    vblnk_d1_nxt = in.vblnk;
    rgb_d1_nxt = in.rgb;

    class_id_nxt = class_id_reg;
    char_select_btn_nxt = 1'b0;

    if (current_state == 3'd1 && click_pulse) begin
        if (hover0) begin
            class_id_nxt = 2'd0;
            char_select_btn_nxt = 1'b1;
        end
        if (hover1) begin
            class_id_nxt = 2'd1;
            char_select_btn_nxt = 1'b1;
        end
        if (hover2) begin
            class_id_nxt = 2'd2;
            char_select_btn_nxt = 1'b1;
        end
        if (hover3) begin
            class_id_nxt = 2'd3;
            char_select_btn_nxt = 1'b1;
        end
    end

    rgb_nxt = rgb_d1_reg;

    if (current_state == 3'd1 && (!vblnk_d1_reg) && (!hblnk_d1_reg)) begin
        rgb_nxt = 12'h222; 

        if (in_bar_hp) begin
            rgb_nxt = 12'h2D2;
        end else if (in_bar_spd) begin
            rgb_nxt = 12'h2AF;
        end else if (in_bar_dmg) begin
            rgb_nxt = 12'hF22;
        end else if (in_panel) begin
            rgb_nxt = 12'h444;
        end else if (in_b0) begin
            if (hover0) begin
                rgb_nxt = 12'hF55;
            end else begin
                rgb_nxt = 12'hA00;
            end
        end else if (in_b1) begin
            if (hover1) begin
                rgb_nxt = 12'h5F5;
            end else begin
                rgb_nxt = 12'h0A0;
            end
        end else if (in_b2) begin
            if (hover2) begin
                rgb_nxt = 12'h55F;
            end else begin
                rgb_nxt = 12'h00A;
            end
        end else if (in_b3) begin
            if (hover3) begin
                rgb_nxt = 12'hFF5;
            end else begin
                rgb_nxt = 12'hAA0;
            end
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mouse_left_prev_reg <= 1'b0;
        
        hcount_d1_reg <= 11'h0;
        vcount_d1_reg <= 11'h0;
        hsync_d1_reg <= 1'b0;
        vsync_d1_reg <= 1'b0;
        hblnk_d1_reg <= 1'b0;
        vblnk_d1_reg <= 1'b0;
        rgb_d1_reg <= 12'h0;

        class_id_reg <= 2'd0;
        char_select_btn_reg <= 1'b0;
        
        out.vcount <= 11'h0;
        out.hcount <= 11'h0;
        out.vsync <= 1'b0;
        out.hsync <= 1'b0;
        out.vblnk <= 1'b0;
        out.hblnk <= 1'b0;
        out.rgb <= 12'h0;
    end else begin
        mouse_left_prev_reg <= mouse_left_prev_nxt;

        hcount_d1_reg <= hcount_d1_nxt;
        vcount_d1_reg <= vcount_d1_nxt;
        hsync_d1_reg <= hsync_d1_nxt;
        vsync_d1_reg <= vsync_d1_nxt;
        hblnk_d1_reg <= hblnk_d1_nxt;
        vblnk_d1_reg <= vblnk_d1_nxt;
        rgb_d1_reg <= rgb_d1_nxt;

        class_id_reg <= class_id_nxt;
        char_select_btn_reg <= char_select_btn_nxt;

        out.vcount <= vcount_d1_reg;
        out.hcount <= hcount_d1_reg;
        out.vsync <= vsync_d1_reg;
        out.hsync <= hsync_d1_reg;
        out.vblnk <= vblnk_d1_reg;
        out.hblnk <= hblnk_d1_reg;
        out.rgb <= rgb_nxt;
    end
end

endmodule
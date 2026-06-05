`timescale 1 ns / 1 ps

module draw_char_select (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [2:0]  current_state,
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic        mouse_left,
    vga_if.in           in,
    vga_if.out          out,
    output logic [1:0]  class_id,
    output logic        char_select_button
);

    logic mouse_left_prev;
    logic click_pulse;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) mouse_left_prev <= 1'b0;
        else        mouse_left_prev <= mouse_left;
    end
    assign click_pulse = mouse_left & ~mouse_left_prev;

    localparam logic [11:0] BTN_W   = 12'd150;
    localparam logic [11:0] BTN_H   = 12'd150;
    localparam logic [11:0] BTN_Y   = 12'd500;
    
    localparam logic [11:0] B0_X    = 12'd136;
    localparam logic [11:0] B1_X    = 12'd336;
    localparam logic [11:0] B2_X    = 12'd536;
    localparam logic [11:0] B3_X    = 12'd736;
    
    localparam logic [11:0] PANEL_X = 12'd262;
    localparam logic [11:0] PANEL_Y = 12'd150;
    localparam logic [11:0] PANEL_W = 12'd500;
    localparam logic [11:0] PANEL_H = 12'd250;
    
    localparam logic [11:0] BAR_X   = 12'd400;
    localparam logic [11:0] BAR_H   = 12'd24;
    localparam logic [11:0] HP_Y    = 12'd200;
    localparam logic [11:0] SPD_Y   = 12'd260;
    localparam logic [11:0] DMG_Y   = 12'd320;

    logic hover0, hover1, hover2, hover3;
    assign hover0 = (mouse_x >= B0_X && mouse_x < B0_X + BTN_W && mouse_y >= BTN_Y && mouse_y < BTN_Y + BTN_H);
    assign hover1 = (mouse_x >= B1_X && mouse_x < B1_X + BTN_W && mouse_y >= BTN_Y && mouse_y < BTN_Y + BTN_H);
    assign hover2 = (mouse_x >= B2_X && mouse_x < B2_X + BTN_W && mouse_y >= BTN_Y && mouse_y < BTN_Y + BTN_H);
    assign hover3 = (mouse_x >= B3_X && mouse_x < B3_X + BTN_W && mouse_y >= BTN_Y && mouse_y < BTN_Y + BTN_H);

    logic [1:0] viewed_class;
    always_comb begin
        if      (hover1) viewed_class = 2'd1;
        else if (hover2) viewed_class = 2'd2;
        else if (hover3) viewed_class = 2'd3;
        else             viewed_class = 2'd0;
    end

    logic [11:0] bar_hp_w, bar_spd_w, bar_dmg_w;
    always_comb begin
        case (viewed_class)
            2'd0: begin bar_hp_w = 12'd150; bar_spd_w = 12'd200; bar_dmg_w = 12'd150; end
            2'd1: begin bar_hp_w = 12'd300; bar_spd_w = 12'd100; bar_dmg_w = 12'd90;  end
            2'd2: begin bar_hp_w = 12'd112; bar_spd_w = 12'd300; bar_dmg_w = 12'd60;  end
            2'd3: begin bar_hp_w = 12'd75;  bar_spd_w = 12'd150; bar_dmg_w = 12'd300; end
        endcase
    end

    logic [10:0] hcount_d1, vcount_d1;
    logic        hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic [11:0] rgb_d1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hcount_d1 <= '0;
            vcount_d1 <= '0;
            hsync_d1  <= '0;
            vsync_d1  <= '0;
            hblnk_d1  <= '0;
            vblnk_d1  <= '0;
            rgb_d1    <= '0;
        end else begin
            hcount_d1 <= in.hcount;
            vcount_d1 <= in.vcount;
            hsync_d1  <= in.hsync;
            vsync_d1  <= in.vsync;
            hblnk_d1  <= in.hblnk;
            vblnk_d1  <= in.vblnk;
            rgb_d1    <= in.rgb;
        end
    end

    logic [1:0] class_id_reg;
    logic       char_select_btn_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            class_id_reg        <= 2'd0;
            char_select_btn_reg <= 1'b0;
        end else begin
            char_select_btn_reg <= 1'b0;
            if (current_state == 3'd1 && click_pulse) begin
                if (hover0) begin class_id_reg <= 2'd0; char_select_btn_reg <= 1'b1; end
                if (hover1) begin class_id_reg <= 2'd1; char_select_btn_reg <= 1'b1; end
                if (hover2) begin class_id_reg <= 2'd2; char_select_btn_reg <= 1'b1; end
                if (hover3) begin class_id_reg <= 2'd3; char_select_btn_reg <= 1'b1; end
            end
        end
    end

    assign class_id = class_id_reg;
    assign char_select_button = char_select_btn_reg;

    logic in_panel, in_bar_hp, in_bar_spd, in_bar_dmg;
    logic in_b0, in_b1, in_b2, in_b3;
    logic [11:0] rgb_nxt;

    always_comb begin
        in_panel   = (hcount_d1 >= PANEL_X && hcount_d1 < PANEL_X + PANEL_W && vcount_d1 >= PANEL_Y && vcount_d1 < PANEL_Y + PANEL_H);
        in_bar_hp  = (hcount_d1 >= BAR_X && hcount_d1 < BAR_X + bar_hp_w  && vcount_d1 >= HP_Y  && vcount_d1 < HP_Y  + BAR_H);
        in_bar_spd = (hcount_d1 >= BAR_X && hcount_d1 < BAR_X + bar_spd_w && vcount_d1 >= SPD_Y && vcount_d1 < SPD_Y + BAR_H);
        in_bar_dmg = (hcount_d1 >= BAR_X && hcount_d1 < BAR_X + bar_dmg_w && vcount_d1 >= DMG_Y && vcount_d1 < DMG_Y + BAR_H);
        
        in_b0 = (hcount_d1 >= B0_X && hcount_d1 < B0_X + BTN_W && vcount_d1 >= BTN_Y && vcount_d1 < BTN_Y + BTN_H);
        in_b1 = (hcount_d1 >= B1_X && hcount_d1 < B1_X + BTN_W && vcount_d1 >= BTN_Y && vcount_d1 < BTN_Y + BTN_H);
        in_b2 = (hcount_d1 >= B2_X && hcount_d1 < B2_X + BTN_W && vcount_d1 >= BTN_Y && vcount_d1 < BTN_Y + BTN_H);
        in_b3 = (hcount_d1 >= B3_X && hcount_d1 < B3_X + BTN_W && vcount_d1 >= BTN_Y && vcount_d1 < BTN_Y + BTN_H);

        rgb_nxt = rgb_d1;

        if (current_state == 3'd1 && !vblnk_d1 && !hblnk_d1) begin
            rgb_nxt = 12'h222; 

            if (in_bar_hp)       rgb_nxt = 12'h2D2; 
            else if (in_bar_spd) rgb_nxt = 12'h2AF; 
            else if (in_bar_dmg) rgb_nxt = 12'hF22; 
            else if (in_panel)   rgb_nxt = 12'h444; 
            else if (in_b0)      rgb_nxt = hover0 ? 12'hF55 : 12'hA00; 
            else if (in_b1)      rgb_nxt = hover1 ? 12'h5F5 : 12'h0A0; 
            else if (in_b2)      rgb_nxt = hover2 ? 12'h55F : 12'h00A; 
            else if (in_b3)      rgb_nxt = hover3 ? 12'hFF5 : 12'hAA0; 
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.vcount <= '0;
            out.hcount <= '0;
            out.vsync  <= '0;
            out.hsync  <= '0;
            out.vblnk  <= '0;
            out.hblnk  <= '0;
            out.rgb    <= '0;
        end else begin
            out.vcount <= vcount_d1;
            out.hcount <= hcount_d1;
            out.vsync  <= vsync_d1;
            out.hsync  <= hsync_d1;
            out.vblnk  <= vblnk_d1;
            out.hblnk  <= hblnk_d1;
            out.rgb    <= rgb_nxt;
        end
    end

endmodule
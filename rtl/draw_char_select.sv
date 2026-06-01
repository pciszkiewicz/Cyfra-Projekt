/**
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Game state machine (FSM).
 */

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

    localparam logic [11:0] BTN_W  = 12'd150;
    localparam logic [11:0] BTN_H  = 12'd200;
    localparam logic [11:0] BTN_Y  = 12'd284; 
    localparam logic [11:0] BORDER = 12'd6;   

    localparam logic [11:0] BTN0_X = 12'd84;
    localparam logic [11:0] BTN1_X = 12'd318;
    localparam logic [11:0] BTN2_X = 12'd552;
    localparam logic [11:0] BTN3_X = 12'd786;

    logic hover0, hover1, hover2, hover3;
    assign hover0 = (mouse_x >= BTN0_X && mouse_x < BTN0_X + BTN_W && mouse_y >= BTN_Y && mouse_y < BTN_Y + BTN_H);
    assign hover1 = (mouse_x >= BTN1_X && mouse_x < BTN1_X + BTN_W && mouse_y >= BTN_Y && mouse_y < BTN_Y + BTN_H);
    assign hover2 = (mouse_x >= BTN2_X && mouse_x < BTN2_X + BTN_W && mouse_y >= BTN_Y && mouse_y < BTN_Y + BTN_H);
    assign hover3 = (mouse_x >= BTN3_X && mouse_x < BTN3_X + BTN_W && mouse_y >= BTN_Y && mouse_y < BTN_Y + BTN_H);

    logic in_btn0, in_btn1, in_btn2, in_btn3;
    logic in_border0, in_border1, in_border2, in_border3;

    assign in_btn0 = (in.hcount >= BTN0_X && in.hcount < BTN0_X + BTN_W && in.vcount >= BTN_Y && in.vcount < BTN_Y + BTN_H);
    assign in_btn1 = (in.hcount >= BTN1_X && in.hcount < BTN1_X + BTN_W && in.vcount >= BTN_Y && in.vcount < BTN_Y + BTN_H);
    assign in_btn2 = (in.hcount >= BTN2_X && in.hcount < BTN2_X + BTN_W && in.vcount >= BTN_Y && in.vcount < BTN_Y + BTN_H);
    assign in_btn3 = (in.hcount >= BTN3_X && in.hcount < BTN3_X + BTN_W && in.vcount >= BTN_Y && in.vcount < BTN_Y + BTN_H);

    assign in_border0 = in_btn0 && (in.hcount < BTN0_X + BORDER || in.hcount >= BTN0_X + BTN_W - BORDER || in.vcount < BTN_Y + BORDER || in.vcount >= BTN_Y + BTN_H - BORDER);
    assign in_border1 = in_btn1 && (in.hcount < BTN1_X + BORDER || in.hcount >= BTN1_X + BTN_W - BORDER || in.vcount < BTN_Y + BORDER || in.vcount >= BTN_Y + BTN_H - BORDER);
    assign in_border2 = in_btn2 && (in.hcount < BTN2_X + BORDER || in.hcount >= BTN2_X + BTN_W - BORDER || in.vcount < BTN_Y + BORDER || in.vcount >= BTN_Y + BTN_H - BORDER);
    assign in_border3 = in_btn3 && (in.hcount < BTN3_X + BORDER || in.hcount >= BTN3_X + BTN_W - BORDER || in.vcount < BTN_Y + BORDER || in.vcount >= BTN_Y + BTN_H - BORDER);

    logic [1:0] class_id_reg, class_id_nxt;
    logic char_select_btn_reg, char_select_btn_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            class_id_reg <= 2'd0;
            char_select_btn_reg <= 1'b0;
        end else begin
            class_id_reg <= class_id_nxt;
            char_select_btn_reg <= char_select_btn_nxt;
        end
    end

    always_comb begin
        class_id_nxt = class_id_reg;
        char_select_btn_nxt = 1'b0;

        if (current_state == 3'd1 && click_pulse) begin
            if (hover0) begin class_id_nxt = 2'd0; char_select_btn_nxt = 1'b1; end
            if (hover1) begin class_id_nxt = 2'd1; char_select_btn_nxt = 1'b1; end
            if (hover2) begin class_id_nxt = 2'd2; char_select_btn_nxt = 1'b1; end
            if (hover3) begin class_id_nxt = 2'd3; char_select_btn_nxt = 1'b1; end
        end
    end

    assign class_id = class_id_reg;
    assign char_select_button = char_select_btn_reg;

    logic [11:0] rgb_nxt;

    always_comb begin
        if (current_state == 3'd1) begin
            rgb_nxt = 12'h333; 

            if (in_btn0) begin
                if (in_border0) rgb_nxt = hover0 ? 12'hFFF : 12'h888; 
                else            rgb_nxt = hover0 ? 12'hF55 : 12'hC00; 
            end
            else if (in_btn1) begin
                if (in_border1) rgb_nxt = hover1 ? 12'hFFF : 12'h888;
                else            rgb_nxt = hover1 ? 12'h5F5 : 12'h0C0;
            end
            else if (in_btn2) begin
                if (in_border2) rgb_nxt = hover2 ? 12'hFFF : 12'h888;
                else            rgb_nxt = hover2 ? 12'h55F : 12'h00C;
            end
            else if (in_btn3) begin
                if (in_border3) rgb_nxt = hover3 ? 12'hFFF : 12'h888;
                else            rgb_nxt = hover3 ? 12'hFF5 : 12'hCC0;
            end
        end else begin
            rgb_nxt = in.rgb; 
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
            out.vcount <= in.vcount;
            out.hcount <= in.hcount;
            out.vsync  <= in.vsync;
            out.hsync  <= in.hsync;
            out.vblnk  <= in.vblnk;
            out.hblnk  <= in.hblnk;
            out.rgb    <= rgb_nxt;
        end
    end

endmodule
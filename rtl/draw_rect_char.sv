//rejestrowanie wyjść char_xy

module draw_rect_char#(
    parameter int RECT_X_POS = 0,
    parameter int RECT_Y_POS = 0
)(
    input  logic clk,
    input  logic rst_n,
    vga_if.in    in,
    vga_if.out   out,
    output logic [7:0] char_xy,
    output logic [3:0] char_line,
    input  logic [7:0] char_pixels
);

    localparam RECT_WIDTH  = 256;
    localparam RECT_HEIGHT = 128;

    // Stworzenie lokalnego układu współrzędnych
    logic [11:0] rect_x_diff, rect_y_diff;
    assign rect_x_diff = in.hcount - RECT_X_POS;
    assign rect_y_diff = in.vcount - RECT_Y_POS;

    assign char_xy = {rect_y_diff[6:4], rect_x_diff[7:3]};

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) char_line <= '0;
        else        char_line <= rect_y_diff[3:0]; // Opóźnienie linii znaku
    end

    localparam BUS_WIDTH = 38;
    logic [BUS_WIDTH-1:0] delay_in, delay_out;

    assign delay_in = {in.rgb, in.hcount, in.vcount, in.hsync, in.vsync, in.hblnk, in.vblnk};

    delay #(
        .WIDTH(BUS_WIDTH),
        .CLK_DEL(2)
    ) u_delay_vga (
        .clk    (clk),
        .rst_n  (rst_n),
        .din    (delay_in),
        .dout   (delay_out)
    );

    logic [11:0] del_rgb;
    logic [10:0] del_hcount, del_vcount;
    logic del_hsync, del_vsync, del_hblnk, del_vblnk;
    assign {del_rgb, del_hcount, del_vcount, del_hsync, del_vsync, del_hblnk, del_vblnk} = delay_out;

    logic [11:0] rgb_nxt;
    logic pixel_bit;

    always_comb begin
        pixel_bit = char_pixels[7 - del_hcount[2:0]];
        
        if (del_hblnk || del_vblnk) begin
            rgb_nxt = 12'h000;
        end else if(del_hcount >= RECT_X_POS && del_hcount < RECT_X_POS + RECT_WIDTH &&
                    del_vcount >= RECT_Y_POS && del_vcount < RECT_Y_POS + RECT_HEIGHT && pixel_bit) begin
            rgb_nxt = 12'hFFF;
        end else begin
            rgb_nxt = del_rgb;
        end
    end

    // Rejestry wyjściowe
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.rgb <= '0;
            {out.hcount, out.vcount, out.hsync, out.vsync, out.hblnk, out.vblnk} <= '0;
        end else begin
            out.rgb <= rgb_nxt;
            {out.hcount, out.vcount, out.hsync, out.vsync, out.hblnk, out.vblnk} <= 
            {del_hcount, del_vcount, del_hsync, del_vsync, del_hblnk, del_vblnk};
        end
    end

endmodule
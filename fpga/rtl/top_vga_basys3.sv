`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Piotr Ciszkiewicz, Tomasz Jesionek
 *
 * Description:
 * Główny plik dla układu FPGA (Basys3 Hardware Top Module).
 * Mapuje fizyczne piny płytki Vivado (przyciski, przełączniki, porty VGA, piny Pmod)
 * na wewnętrzne sygnały logiczne systemu. Zawiera synchronizatory resetu i sygnałów wejściowych.
 */

module top_vga_basys3 (
    input logic clk,
    input logic btnC,
    input logic sw0,
    inout wire PS2Clk,
    inout wire PS2Data,
    output logic Vsync,
    output logic Hsync,
    output logic [3:0] vgaRed,
    output logic [3:0] vgaGreen,
    output logic [3:0] vgaBlue,
    input logic JA1,
    output logic JA2
);

/* Local signals */
logic clk_65MHz;
logic clk_100MHz_internal;
logic clk_locked;

logic rst_sys_n_sync1_reg, rst_sys_n_sync2_reg;
logic rst_100m_n_sync1_reg, rst_100m_n_sync2_reg;

logic sw0_sync1_reg, sw0_sync2_reg;

logic async_rst_n;

/* Signals assignments */
assign async_rst_n = clk_locked & (~btnC);

/* Clock generation */
clk_wiz_0 u_clk_wiz (
    .clk(clk),
    .clk100Mhz(clk_100MHz_internal),
    .clk65Mhz(clk_65MHz),
    .locked(clk_locked)
);

/* Reset synchronization */
always_ff @(posedge clk_65MHz or negedge async_rst_n) begin
    if (!async_rst_n) begin
        rst_sys_n_sync1_reg <= 1'b0;
        rst_sys_n_sync2_reg <= 1'b0;
    end else begin
        rst_sys_n_sync1_reg <= 1'b1;
        rst_sys_n_sync2_reg <= rst_sys_n_sync1_reg;
    end
end

always_ff @(posedge clk_100MHz_internal or negedge async_rst_n) begin
    if (!async_rst_n) begin
        rst_100m_n_sync1_reg <= 1'b0;
        rst_100m_n_sync2_reg <= 1'b0;
    end else begin
        rst_100m_n_sync1_reg <= 1'b1;
        rst_100m_n_sync2_reg <= rst_100m_n_sync1_reg;
    end
end

/* Input synchronization */
always_ff @(posedge clk_65MHz or negedge rst_sys_n_sync2_reg) begin
    if (!rst_sys_n_sync2_reg) begin
        sw0_sync1_reg <= 1'b0;
        sw0_sync2_reg <= 1'b0;
    end else begin
        sw0_sync1_reg <= sw0;
        sw0_sync2_reg <= sw0_sync1_reg;
    end
end

/* Top level VGA instantiation */
top_vga u_top_vga (
    .clk_65MHz(clk_65MHz),
    .clk_100MHz(clk_100MHz_internal),
    .rst_sys_n(rst_sys_n_sync2_reg),
    .rst_100m_n(rst_100m_n_sync2_reg),
    .is_master(sw0_sync2_reg),
    .vs(Vsync),
    .hs(Hsync),
    .r(vgaRed),
    .g(vgaGreen),
    .b(vgaBlue),
    .ps2_clk(PS2Clk),
    .ps2_data(PS2Data),
    .uart_rx(JA1),
    .uart_tx(JA2)
);

endmodule
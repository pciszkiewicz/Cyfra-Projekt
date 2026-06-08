`timescale 1 ns / 1 ps

module top_vga_basys3 (
    input  wire        clk,        
    input  wire        btnC,       
    input  wire        btnU,       
    input  wire        sw0,        // NOWE: Przełącznik Master (1) / Slave (0)
     
    inout  wire        PS2Clk,
    inout  wire        PS2Data,
     
    output wire        Vsync,
    output wire        Hsync,
    output wire [3:0]  vgaRed,
    output wire [3:0]  vgaGreen,
    output wire [3:0]  vgaBlue,
 
    input  wire        JA1,        
    output wire        JA2         
);

logic clk_65MHz;
logic clk_100MHz_internal;
logic clk_locked;

logic rst_sys_n_sync1, rst_sys_n_sync2;
logic rst_100m_n_sync1, rst_100m_n_sync2;

clk_wiz_0 u_clk_wiz (
    .clk(clk),
    .clk100Mhz(clk_100MHz_internal),
    .clk65Mhz(clk_65MHz),
    .locked(clk_locked)
);

wire async_rst_n = clk_locked & ~btnC;

always_ff @(posedge clk_65MHz or negedge async_rst_n) begin
    if (!async_rst_n) begin
        rst_sys_n_sync1 <= 1'b0;
        rst_sys_n_sync2 <= 1'b0;
    end else begin
        rst_sys_n_sync1 <= 1'b1;
        rst_sys_n_sync2 <= rst_sys_n_sync1;
    end
end

always_ff @(posedge clk_100MHz_internal or negedge async_rst_n) begin
    if (!async_rst_n) begin
        rst_100m_n_sync1 <= 1'b0;
        rst_100m_n_sync2 <= 1'b0;
    end else begin
        rst_100m_n_sync1 <= 1'b1;
        rst_100m_n_sync2 <= rst_100m_n_sync1;
    end
end
 
logic btnu_sync1, btnu_sync2;
logic sw0_sync1,  sw0_sync2;

always_ff @(posedge clk_65MHz or negedge rst_sys_n_sync2) begin
    if (!rst_sys_n_sync2) begin
        btnu_sync1 <= 1'b0;
        btnu_sync2 <= 1'b0;
        sw0_sync1  <= 1'b0;
        sw0_sync2  <= 1'b0;
    end else begin
        btnu_sync1 <= btnU;
        btnu_sync2 <= btnu_sync1;
        sw0_sync1  <= sw0;
        sw0_sync2  <= sw0_sync1;
    end
end
 
top_vga u_top_vga (
    .clk_65MHz(clk_65MHz),                  
    .clk_100MHz(clk_100MHz_internal),       
    .rst_sys_n(rst_sys_n_sync2),     
    .rst_100m_n(rst_100m_n_sync2),     
    .is_master(sw0_sync2),           // NOWE: Przekazanie roli
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
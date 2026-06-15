`timescale 1 ns / 1 ps

/*
 * MTM UEC2
 * Author: Tomasz Jesionek
 *
 * Description:
 * Package with vga related constants.
 */
package vga_pkg;

localparam HOR_PIXELS = 12'd1024;
localparam VER_PIXELS = 12'd768;

localparam H_FRONT_PORCH = 12'd24;
localparam H_SYNC_PULSE  = 12'd136;
localparam H_BACK_PORCH  = 12'd160;
localparam H_TOTAL       = HOR_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;

localparam V_FRONT_PORCH = 12'd3;
localparam V_SYNC_PULSE  = 12'd6;
localparam V_BACK_PORCH  = 12'd29;
localparam V_TOTAL       = VER_PIXELS + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

localparam MOUSE_MAX_X = 12'd1023;
localparam MOUSE_MAX_Y = 12'd767;

endpackage
/**
 * Copyright (C) 2026  AGH University of Science and Technology
 * MTM UEC
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Package with vga related constants.
 */



package vga_pkg;

   // Parametry dla VGA 800 x 600 @ 60fps przy użyciu zegara 40 MHz
   localparam HOR_PIXELS = 800; 
   localparam VER_PIXELS = 600; 
  
   // Parametry czasowe w poziomie (Horizontal) - liczone w taktach zegara 
   localparam H_FRONT_PORCH = 40;
   localparam H_SYNC_PULSE  = 128;
   localparam H_BACK_PORCH  = 88;
   localparam H_TOTAL       = HOR_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; // Razem 1056
  
   // Parametry czasowe w pionie (Vertical)
   localparam V_FRONT_PORCH = 1;
   localparam V_SYNC_PULSE  = 4;
   localparam V_BACK_PORCH  = 23;
   localparam V_TOTAL       = VER_PIXELS + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH; // Razem 628
  
endpackage
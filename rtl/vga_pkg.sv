/**
 * Copyright (C) 2026  AGH University of Science and Technology
 * MTM UEC
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Package with vga related constants.
 */



 package vga_pkg;

   // Parametry dla VGA 1024 x 768 @ 60fps przy użyciu zegara 65 MHz
   localparam HOR_PIXELS = 1024;
   localparam VER_PIXELS = 768; 
  
   // Parametry czasowe w poziomie (Horizontal) - liczone w taktach zegara 
   localparam H_FRONT_PORCH = 24;
   localparam H_SYNC_PULSE  = 136;
   localparam H_BACK_PORCH  = 160;
   localparam H_TOTAL       = HOR_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH; // Razem 1344
  
   // Parametry czasowe w pionie (Vertical)
   localparam V_FRONT_PORCH = 3;
   localparam V_SYNC_PULSE  = 6;
   localparam V_BACK_PORCH  = 29;
   localparam V_TOTAL       = VER_PIXELS + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH; // Razem 806
  
endpackage
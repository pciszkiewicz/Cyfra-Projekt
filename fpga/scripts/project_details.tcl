# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
# Modified: Piotr Ciszkiewicz
#
# Description:
# Project detiles required for generate_bitstream.tcl
# Make sure that project_name, top_module and target are correct.
# Provide paths to all the files required for synthesis and implementation.
# Depending on the file type, it should be added in the corresponding section.
# If the project does not use files of some type, leave the corresponding section commented out.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Tytuł projektu zgodnie z listą kontrolną
set project_name vga_project

# Nazwa głównego modułu syntezowalnego
set top_module top_vga_basys3

# Urządzenie docelowe: Basys 3
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#

# Pliki ograniczeń projektowych (.xdc)
set xdc_files {
    constraints/top_vga_basys3.xdc
    constraints/clk_wiz_0.xdc
}

# Pliki SystemVerilog - logika gry i potok VGA
# vga_pkg.sv musi być pierwszy ze względu na importy!
set sv_files {
    ../rtl/vga_pkg.sv
    ../rtl/vga_if.sv
    ../rtl/vga_timing.sv
    ../rtl/edge_detector.sv
    ../rtl/crate_lut.sv
    ../rtl/crates_rom.sv
    ../rtl/map_rom.sv
    ../rtl/lfsr.sv
    ../rtl/cam_translation.sv
    ../rtl/bullet_ctl.sv
    ../rtl/collision_det.sv
    ../rtl/crates_collision_det.sv
    ../rtl/uart_tx.sv
    ../rtl/uart_rx.sv
    ../rtl/uart_packet_ctl.sv
    ../rtl/draw_start_screen.sv
    ../rtl/draw_char_select.sv
    ../rtl/draw_map.sv
    ../rtl/draw_crates.sv
    ../rtl/draw_entities.sv
    ../rtl/draw_hud.sv
    ../rtl/draw_mouse.sv
    ../rtl/player_ctl.sv
    ../rtl/game_fsm.sv
    ../rtl/game_logic_top.sv
    ../rtl/top_vga.sv
    rtl/top_vga_basys3.sv
}

# Pliki Verilog - Generator zegara (IP Vivado)
set verilog_files {
    rtl/clk_wiz_0.v
    rtl/clk_wiz_0_clk_wiz.v
}

# Pliki VHDL - Kontrolery myszy i interfejs PS/2
set vhdl_files {
    ../rtl/MouseCtl.vhd
    ../rtl/Ps2Interface.vhd
    ../rtl/MouseDisplay.vhd
}

# Pliki inicjalizacji pamięci ROM
set mem_files {
    ../rtl/memory/crates_data.mem
    ../rtl/memory/map_walls.mem
}
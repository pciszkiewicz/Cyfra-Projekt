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
    ../rtl/video/vga_pkg.sv
    ../rtl/video/vga_if.sv
    ../rtl/video/vga_timing.sv
    ../rtl/utils/edge_detector.sv
    ../rtl/memory_ctrl/crate_lut.sv
    ../rtl/memory_ctrl/crates_rom.sv
    ../rtl/memory_ctrl/map_rom.sv
    ../rtl/utils/lfsr.sv
    ../rtl/game/bullet_ctl.sv
    ../rtl/game/collision_det.sv
    ../rtl/game/crates_collision_det.sv
    ../rtl/io/uart_tx.sv
    ../rtl/io/uart_rx.sv
    ../rtl/io/uart_packet_ctl.sv
    ../rtl/video/draw_start_screen.sv
    ../rtl/video/draw_char_select.sv
    ../rtl/video/draw_map.sv
    ../rtl/video/draw_crates.sv
    ../rtl/video/draw_entities.sv
    ../rtl/video/draw_hud.sv
    ../rtl/video/draw_mouse.sv
    ../rtl/game/player_ctl.sv
    ../rtl/game/game_fsm.sv
    ../rtl/game/game_logic_top.sv
    ../rtl/top/top_vga.sv
    rtl/top_vga_basys3.sv
}

# Pliki Verilog - Generator zegara (IP Vivado)
set verilog_files {
    rtl/clk_wiz_0.v
    rtl/clk_wiz_0_clk_wiz.v
}

# Pliki VHDL - Kontrolery myszy i interfejs PS/2
set vhdl_files {
    ../rtl/io/MouseCtl.vhd
    ../rtl/io/Ps2Interface.vhd
    ../rtl/video/MouseDisplay.vhd
}

# Pliki inicjalizacji pamięci ROM
set mem_files {
    ../rtl/memory/crates_data.mem
    ../rtl/memory/map_walls.mem
    ../rtl/memory/bullet_blue.mem
    ../rtl/memory/bullet_red.mem
    ../rtl/memory/crate_sprite.mem
    ../rtl/memory/crosshair.mem
    ../rtl/memory/enemy_sprite.mem
    ../rtl/memory/floor_sprite.mem
    ../rtl/memory/loot_dmg.mem
    ../rtl/memory/loot_heal.mem
    ../rtl/memory/loot_speed.mem
    ../rtl/memory/player_sprite.mem
    ../rtl/memory/wall_sprite.mem
}
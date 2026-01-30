# ============================================================
# create_project.tcl
#
# Minimal Vivado project creation script for Gain Module
# Focus: RTL + Testbench (Simulation & Synthesis)
#
# Tested with Vivado 2024.1
# Target board: Kria KV260 (xck26-sfvc784-2LV-c)
# ============================================================

# Project name
set proj_name "gain"

# Create project
create_project $proj_name ./$proj_name -part xck26-sfvc784-2LV-c -force

# Board (optional, safe to keep)
set_property board_part xilinx.com:kv260_som:part0:1.4 [current_project]

# ------------------------------------------------------------
# Add RTL sources
# ------------------------------------------------------------
add_files -norecurse ../rtl/gain_core.v
add_files -norecurse ../rtl/axis_gain_wrapper.v

# Set RTL top (wrapper)
set_property top axis_gain_wrapper [get_filesets sources_1]

# ------------------------------------------------------------
# Add simulation sources
# ------------------------------------------------------------
add_files -fileset sim_1 -norecurse ../tb/tb_gain_core.sv
add_files -fileset sim_1 -norecurse ../tb/tb_axis_gain_wrapper.sv

# Set simulation top
set_property top tb_axis_gain_wrapper [get_filesets sim_1]

# ------------------------------------------------------------
# Simulator settings
# ------------------------------------------------------------
set_property simulator_language Mixed [current_project]
set_property xsim.simulate.runtime 1ms [get_filesets sim_1]

puts "INFO: Vivado project '$proj_name' created successfully."

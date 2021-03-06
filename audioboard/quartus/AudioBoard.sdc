#************************************************************
# THIS IS A WIZARD-GENERATED FILE.                           
#
# Version 13.1.0 Build 162 10/23/2013 SJ Web Edition
#
#************************************************************

# Copyright (C) 1991-2013 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.

# Clock constraints
create_clock -name "ClkSys" -period 20.000ns [get_ports {ClkSys}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

# false path constraints
set_false_path -from "ClkSys" -to [get_ports {UartTx}]
set_false_path -from [get_ports {UartRx}] -to "ClkSys"
set_false_path -from [get_ports {KEY*}] -to "ClkSys"
set_false_path -from "ClkSys" -to [get_ports {LED*}]
set_false_path -from "ClkSys" -to [get_ports {AudioScl}]
set_false_path -from "ClkSys" -to [get_ports {AudioSda}]
set_false_path -from [get_ports {AudioSda}] -to "ClkSys"

# tsu/th constraints

# tco constraints

# tpd constraints


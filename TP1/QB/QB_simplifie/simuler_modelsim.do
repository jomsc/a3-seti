# A lancer dans ModelSim : do C:/VHDL/sqrt_structurel/simuler_modelsim.do
# Dossier Windows local sans accent conseille pour ModelSim 2020.1.
# Ce script utilise le dossier dans lequel il se trouve.
set dossier [file dirname [file normalize [info script]]]
cd $dossier
onerror {abort}
if {![file isdirectory work]} {vlib work}
vmap work [file join $dossier work]
vcom -93 -work work registre.vhd
vcom -93 -work work mux2_1.vhd
vcom -93 -work work additionneur.vhd
vcom -93 -work work chemin_donnees.vhd
vcom -93 -work work unite_controle.vhd
vcom -93 -work work sqrt_struct.vhd
vcom -93 -work work tb_sqrt_struct.vhd
vsim -voptargs=+acc work.tb_sqrt_struct
add wave sim:/tb_sqrt_struct/clk
add wave sim:/tb_sqrt_struct/reset
add wave sim:/tb_sqrt_struct/start
add wave -radix unsigned sim:/tb_sqrt_struct/A
add wave -radix unsigned sim:/tb_sqrt_struct/S
add wave sim:/tb_sqrt_struct/done
add wave sim:/tb_sqrt_struct/DUT/CU/current_state
add wave -radix unsigned sim:/tb_sqrt_struct/DUT/CU/i
add wave -radix signed sim:/tb_sqrt_struct/DUT/DP/r_q
add wave -radix signed sim:/tb_sqrt_struct/DUT/DP/r_next
add wave sim:/tb_sqrt_struct/DUT/sig_RC0
add wave sim:/tb_sqrt_struct/DUT/sig_RC1
# Le banc arrete son horloge a la fin : run -all se termine seul.
run -all
wave zoom full

transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2 {E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2/Divs.v}
vlog -vlog01compat -work work +incdir+E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2 {E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2/PLL.v}
vlog -sv -work work +incdir+E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2 {E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2/DAC_POLLING.sv}
vlog -sv -work work +incdir+E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2 {E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2/UART.sv}
vlog -sv -work work +incdir+E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2 {E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2/main.sv}

vlog -vlog01compat -work work +incdir+E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2/simulation/modelsim {E:/WORKSPACE/WIFI_OSC/FPGA/SPI_TEST_2/simulation/modelsim/FPGA_EP2C.vt}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  FPGA_EP2C_vlg_tst

add wave *
view structure
view signals
run -all

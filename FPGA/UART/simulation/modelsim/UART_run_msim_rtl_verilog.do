transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/john/Desktop/UART {C:/Users/john/Desktop/UART/UART_BASE.v}
vlog -vlog01compat -work work +incdir+C:/Users/john/Desktop/UART {C:/Users/john/Desktop/UART/shift.v}
vlog -vlog01compat -work work +incdir+C:/Users/john/Desktop/UART {C:/Users/john/Desktop/UART/shiftv2.v}
vcom -93 -work work {C:/Users/john/Desktop/UART/UART_RX_TX.vhd}


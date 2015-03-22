transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+E:/WORKSPACE/FPGA/FPGA2AR9331 {E:/WORKSPACE/FPGA/FPGA2AR9331/FPGA2AR9331.v}


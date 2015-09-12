vlog -work work E:/WORKSPACE/STM32F4/STM32F4xx_DSP_StdPeriph_Lib_V1.3.0/Project/FPGA/SPI_TEST_1/simulation/modelsim/Waveform.vwf.vt
vsim -novopt -c -t 1ps -L cycloneive_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate work.FPGA_EP2C_vlg_vec_tst
onerror {resume}
add wave {FPGA_EP2C_vlg_vec_tst/i1/clk_in}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[15]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[14]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[13]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[12]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[11]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[10]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[9]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[8]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[7]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[6]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[5]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[4]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[3]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[2]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[1]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/data_in[0]}
add wave {FPGA_EP2C_vlg_vec_tst/i1/en}
add wave {FPGA_EP2C_vlg_vec_tst/i1/mosi}
add wave {FPGA_EP2C_vlg_vec_tst/i1/rst_n}
add wave {FPGA_EP2C_vlg_vec_tst/i1/sclk}
run -all

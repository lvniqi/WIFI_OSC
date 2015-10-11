vlog -work work E:/WORKSPACE/FPGA/TEST_FIFO/simulation/modelsim/Waveform_counter.vwf.vt
vsim -novopt -c -t 1ps -L cycloneive_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate work.fifo_counter_vlg_vec_tst
onerror {resume}
add wave {fifo_counter_vlg_vec_tst/i1/counter}
add wave {fifo_counter_vlg_vec_tst/i1/counter[15]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[14]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[13]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[12]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[11]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[10]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[9]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[8]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[7]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[6]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[5]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[4]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[3]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[2]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[1]}
add wave {fifo_counter_vlg_vec_tst/i1/counter[0]}
add wave {fifo_counter_vlg_vec_tst/i1/clk}
add wave {fifo_counter_vlg_vec_tst/i1/r_en}
add wave {fifo_counter_vlg_vec_tst/i1/w_en}
run -all

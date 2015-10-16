

`define ENABLE_CLOCK_INPUTS
`define ENABLE_DAC_SPI_INTERFACE
`define ENABLE_AR9331_INTERFACE
`define ENABLE_74HC4051_INTERFACE
`define ENABLE_TEST_IO_INTERFACE
`define ENABLE_AD9288_INTERFACE
module main(
	/* Clock inputs, SYS_CLK = 25MHz*/	
`ifdef ENABLE_CLOCK_INPUTS
	input SYS_CLK,
`endif

`ifdef	ENABLE_DAC_SPI_INTERFACE
	/* DAC, 12-bit, SPI interface (AD5320) */
	output AD5320_SCLK,
	output AD5320_SDATA,
	output AD5320_SYNCn,
`endif

`ifdef	ENABLE_AR9331_INTERFACE
	/* AR9331, WIFI SOC */
	output GPIO_8,
	output GPIO_9,
`endif

`ifdef	ENABLE_74HC4051_INTERFACE
	/* AR9331, WIFI SOC */
	output [2:0] HC4051_POS,
`endif

`ifdef	ENABLE_TEST_IO_INTERFACE
	/*test I/O 8bit*/
	inout [7:0] TEST_IO,
`endif
`ifdef	ENABLE_AD9288_INTERFACE
	output AD_CLKA,
	output AD_CLKB
`endif	
);
wire CLK_100M;
//100M锁相环
PLL(
.inclk0(SYS_CLK),
.c0(CLK_100M)
);
/*//SPI输出
SPI_OUT(
	.clk(SYS_CLK),
	.en(1),
	.rst_n(1),
	.data_in(2048),
	.sclk(AD5320_SCLK),
	.dout(AD5320_SDATA),
	.sync_n(AD5320_SYNCn),
	.isIDLE(GPIO_8),
	.isEND(GPIO_9)
	);
assign HC4051_POS = 0;*/
//DAC轮询刷新
wire DAC_CLK;
//8个寄存器组
reg [11:0] dac_data[0:7];
initial begin
	dac_data[0] <= 1024;
	dac_data[1] <= 1024;
	dac_data[2] <= 1536;
	dac_data[3] <= 2048;
	dac_data[4] <= 512;
	dac_data[5] <= 896;
	dac_data[6] <= 1536;
	dac_data[7] <= 2048;
end
Div #(.N(18))(.clk_in(SYS_CLK),.clk_div(DAC_CLK));
DAC_POLLING(
	.en(1),
	.clk_core(DAC_CLK),
	.rst_n(1),
	.data_in(dac_data),
	.sclk(AD5320_SCLK),
	.dout(AD5320_SDATA),
	.sync_n(AD5320_SYNCn),
	.pos(HC4051_POS)
);
//UART测试
wire [7:0] dout;
wire uart2reg_ready;
wire [6:0] uart2reg_address;
wire [15:0] uart2reg_data;
/*UART(
	.clk(SYS_CLK),
	.rst_n(1),
	.din(dout),
	//.din(uart2reg_dout[23:16]),
	//TXD
	.wr_en(1),
	.txd(TEST_IO[1]),
	.txd_busy(TEST_IO[0]),
	//RXD
	.rxd(TEST_IO[2]),
	.rdy_clr(1),
	.rdy(TEST_IO[3]),
	.dout(dout),
	//REG
	.reg_ready(uart2reg_ready),
	.reg_address(uart2reg_address),
	.reg_data(uart2reg_data)
);

always@(posedge uart2reg_ready)begin
	if(uart2reg_address == 7'hff)begin
		dac_data[uart2reg_data[14:12]]
			<= uart2reg_data[11:0];
	end
end*/

assign TEST_IO[4] = uart2reg_ready;
assign TEST_IO[5] = dout[0];
assign TEST_IO[7] = SYS_CLK;
assign AD_CLKA = SYS_CLK;
assign AD_CLKB = SYS_CLK;
endmodule 
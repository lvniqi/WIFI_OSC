

`define ENABLE_CLOCK_INPUTS
`define ENABLE_DAC_SPI_INTERFACE
`define ENABLE_AR9331_INTERFACE
`define ENABLE_74HC4051_INTERFACE
`define ENABLE_TEST_IO_INTERFACE
`define ENABLE_AD9288_INTERFACE
`define ENABLE_AR9331_INTERFACE
`define ENABLE_UART_INTERFACE
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
	input AR9331_NEXT,
	output AR9331_EN,
	output [7:0] AR9331_DATA,
`endif

`ifdef	ENABLE_74HC4051_INTERFACE
	/* AR9331, WIFI SOC */
	output [2:0] HC4051_POS,
`endif

`ifdef	ENABLE_TEST_IO_INTERFACE
	/*test I/O 8bit*/
	inout logic [7:0] TEST_IO,
`endif

`ifdef	ENABLE_AD9288_INTERFACE
	input [7:0] AD_DATA_A,
	output AD_CLKA,
	output AD_CLKB,
`endif
	
`ifdef	ENABLE_AR9331_INTERFACE
	output CH1_AC_DC,
`endif

`ifdef ENABLE_UART_INTERFACE
	input UART_RXD,
	output UART_TXD
`endif
);
wire CLK_200M;
//100M锁相环
PLL(
.inclk0(SYS_CLK),
.c0(CLK_200M)
);
//DAC轮询刷新
wire DAC_CLK;
//8个寄存器组 用于DAC输出
reg [11:0] dac_data[0:7];
//2个寄存器组 用于ADC频率选择
reg [15:0] adc_freq[0:1];
//DAC分频器
Div #(.N(8))(.clk_in(SYS_CLK),.clk_div(DAC_CLK));
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
reg adc_en_u = 0;
wire [7:0] dout;
wire uart2reg_ready;
//wire [6:0] uart2reg_address;
wire [7:0] uart2reg_address;
wire [7:0] uart2reg_sub_address;
wire [15:0] uart2reg_data;

logic [47:0]regs;
wire reg_o_busy;
UART(
	.clk(SYS_CLK),
	.rst_n(1),
	//TXD
	.txd(UART_TXD),
	//RXD
	.rxd(UART_RXD),
	.rdy_clr(1),
	//.rdy(TEST_IO[3]),
	//.dout(dout),
	//UART2REG
	.reg_ready(uart2reg_ready),
	.reg_address(uart2reg_address),
	.reg_sub_address(uart2reg_sub_address),
	.reg_data(uart2reg_data),
	//REG2UART
	.reg_o_en(1),
	.reg_o_address(8'hc3),
	.reg_o_regs(regs),
	.reg_o_busy(reg_o_busy)
);
//寄存器写入模块
always@(posedge uart2reg_ready)begin
	//DAC寄存器
	if(uart2reg_address == 8'hff)begin
		dac_data[uart2reg_sub_address[2:0]]
			<= uart2reg_data[11:0];
	end
	//ADC频率
	if(uart2reg_address == 8'hfe)begin
		adc_freq[uart2reg_sub_address[0]]
			<= uart2reg_data[15:0];
	end
	//复位
	if(uart2reg_address == 8'h00)begin
		adc_en_u <= uart2reg_data[0];
	end
end

//assign TEST_IO[4] = uart2reg_ready;
//assign TEST_IO[5] = dout[0];
//assign TEST_IO[7] = SYS_CLK;
wire rclk;
wire clear;
wire [31:0] len;
wire [7:0] q;
wire adc_en;
wire adc_clk;
wire adc_trigger;
ADC(
	.clk(CLK_200M),
	.data(AD_DATA_A),
	.trigger(adc_trigger),
	//.is_ingore(adc_trigger),
	.adc_freq(adc_freq[0]),
	.clk_o(AD_CLKA),
	//FIFO
	.r_clk(rclk),
	.clear(clear),
	.len(len),
	.data_out(q),
	.send_en(adc_en),
	//freq
	.freq_data(regs)
);

FPGA2AR9331 (
		.clk(CLK_200M),
		.en(adc_en&&adc_en_u),
		.rst_n(adc_en_u),
		.data_in(q),
		.ack(AR9331_NEXT),
		.clk_out(AR9331_EN),
		.len_in(len),
		.data_out(TEST_IO),
		.r_clk(rclk),
		.isWAIT(clear)
);

assign GPIO_8 = 1'b1;
assign CH1_AC_DC = 1;
endmodule 
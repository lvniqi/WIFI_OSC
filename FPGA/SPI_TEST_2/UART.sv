//串口模块
module UART(
	input clk,
	input rst_n,
	//TXD
	input [7:0] din,
	input wr_en,
	output txd,
	output txd_busy,
	//RXD
	input rxd,
	input rdy_clr,
	output rdy,
	output [7:0] dout
);
	wire tx_en_clk;
	wire rx_en_clk;
	UART_BAUD_GEN(
	.clk(clk),
	.tx_en(tx_en_clk),
	.rx_en(rx_en_clk)
	);
	UART_TXD(
		.din(din),
		.wr_en(wr_en),
		.clk(clk),
		.clken(tx_en_clk),
		.txd(txd),
		.txd_busy(txd_busy)
	);
	UART_RXD(
		.rxd(rxd),
		.rdy(rdy),
		.rdy_clr(rdy_clr),
		.clk(clk),
		.clk_en(rx_en_clk),
		.data(dout)
	);
	
endmodule 

/*
 * 波特率发生器 16倍采样
 * 输入频率25MHz 输出比特率115200
 */
module UART_BAUD_GEN(input clk,
		     output rx_en,
		     output tx_en);
parameter CLK_INPUT = 25000000;
parameter UART_BAUD = 115200;
parameter RX_ACC_MAX = CLK_INPUT / (UART_BAUD * 16);
parameter TX_ACC_MAX = CLK_INPUT / UART_BAUD;
parameter RX_ACC_WIDTH = $clog2(RX_ACC_MAX);
parameter TX_ACC_WIDTH = $clog2(TX_ACC_MAX);
reg [RX_ACC_WIDTH - 1:0] rx_acc = 0;
reg [TX_ACC_WIDTH - 1:0] tx_acc = 0;

assign rx_en = (rx_acc == 5'd0);
assign tx_en = (tx_acc == 9'd0);

always @(posedge clk) begin
	if (rx_acc == RX_ACC_MAX[RX_ACC_WIDTH - 1:0])
		rx_acc <= 0;
	else
		rx_acc <= rx_acc + 5'b1;
end

always @(posedge clk) begin
	if (tx_acc == TX_ACC_MAX[TX_ACC_WIDTH - 1:0])
		tx_acc <= 0;
	else
		tx_acc <= tx_acc + 9'b1;
end
endmodule

//串口发射模块
module UART_TXD(input wire [7:0] din,
		   input wire wr_en,
		   input wire clk,
		   input wire clken,
		   output reg txd,
		   output wire txd_busy);

initial begin
	 txd = 1'b1;
end

parameter STATE_IDLE	= 2'b00;
parameter STATE_START= 2'b01;
parameter STATE_DATA	= 2'b10;
parameter STATE_STOP	= 2'b11;

reg [7:0] data = 8'h00;
reg [2:0] bitpos = 3'h0;
reg [1:0] state = STATE_IDLE;

always @(posedge clk) begin
	case (state)
	STATE_IDLE: begin
		if (wr_en) begin
			state <= STATE_START;
			data <= din;
			bitpos <= 3'h0;
		end
	end
	STATE_START: begin
		if (clken) begin
			txd <= 1'b0;
			state <= STATE_DATA;
		end
	end
	STATE_DATA: begin
		if (clken) begin
			if (bitpos == 3'h7)
				state <= STATE_STOP;
			else
				bitpos <= bitpos + 3'h1;
			txd <= data[bitpos];
		end
	end
	STATE_STOP: begin
		if (clken) begin
			txd <= 1'b1;
			state <= STATE_IDLE;
		end
	end
	default: begin
		txd <= 1'b1;
		state <= STATE_IDLE;
	end
	endcase
end
assign txd_busy = (state != STATE_IDLE);
endmodule

//串口接收模块
module UART_RXD(input wire rxd,
		//数据准备好
		output reg rdy,
		//清空
		input wire rdy_clr,
		//时钟
		input wire clk,
		//使能时钟
		input wire clk_en,
		//输出数据
		output reg [7:0] data);

initial begin
	rdy = 0;
	data = 8'b0;
end

parameter RX_STATE_START	= 2'b00;
parameter RX_STATE_DATA		= 2'b01;
parameter RX_STATE_STOP		= 2'b10;

reg [1:0] state = RX_STATE_START;
reg [3:0] sample = 0;
reg [3:0] bitpos = 0;
reg [7:0] scratch = 8'b0;

always @(posedge clk) begin
	if (rdy_clr)
		rdy <= 0;

	if (clk_en) begin
		case (state)
		RX_STATE_START: begin
			/*
			* Start counting from the first low sample, once we've
			* sampled a full bit, start collecting data bits.
			*/
			if (!rxd || sample != 0)
				sample <= sample + 4'b1;

			if (sample == 15) begin
				state <= RX_STATE_DATA;
				bitpos <= 0;
				sample <= 0;
				scratch <= 0;
			end
		end
		RX_STATE_DATA: begin
			sample <= sample + 4'b1;
			if (sample == 4'h8) begin
				scratch[bitpos[2:0]] <= rxd;
				bitpos <= bitpos + 4'b1;
			end
			if (bitpos == 8 && sample == 15)
				state <= RX_STATE_STOP;
		end
		RX_STATE_STOP: begin
			/*
			 * Our baud clock may not be running at exactly the
			 * same rate as the transmitter.  If we thing that
			 * we're at least half way into the stop bit, allow
			 * transition into handling the next start bit.
			 */
			if (sample == 15 || (sample >= 8 && !rxd)) begin
				state <= RX_STATE_START;
				data <= scratch;
				rdy <= 1'b1;
				sample <= 0;
			end else begin
				sample <= sample + 4'b1;
			end
		end
		default: begin
			state <= RX_STATE_START;
		end
		endcase
	end
end

endmodule

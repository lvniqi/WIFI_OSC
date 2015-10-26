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
	output [7:0] dout,
	//REG
	output reg_ready,
	output wire [7:0] reg_address,
	output wire [7:0] reg_sub_address,
	output wire [15:0] reg_data
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
	UART2REG(
		.rdy_in(rdy),
		.din(dout),
		.ready(reg_ready),
		.address(reg_address),
		.sub_address(reg_sub_address),
		.data(reg_data)
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
		rx_acc <= rx_acc + 1;
end

always @(posedge clk) begin
	if (tx_acc == TX_ACC_MAX[TX_ACC_WIDTH - 1:0])
		tx_acc <= 0;
	else
		tx_acc <= tx_acc + 1;
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
	if (clk_en) begin
		case (state)
		RX_STATE_START: begin
			/*
			* Start counting from the first low sample, once we've
			* sampled a full bit, start collecting data bits.
			*/
			if (rdy_clr)
				rdy <= 0;
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

//8bit address 8bit subaddress 16bit data
module UART2REG(
	input rdy_in,
	input [7:0] din,
	output reg ready = 0,
	output wire [7:0] address,
	output wire [7:0] sub_address,
	output wire [15:0] data
);
	reg [31:0] reg_save;
	assign address = {reg_save[31:25],din[7]};
	assign sub_address = {reg_save[23:17],din[6]};
	assign data = {reg_save[15:9],din[5],reg_save[7:1],din[4]};
	always @(posedge rdy_in) begin
		if(din[3:0] == 4'hf) begin
			ready <= 1'b1;
		end
		else begin
			reg_save <= {reg_save[23:0],din};
			ready <= 1'b0;
		end
	end
endmodule 

//1byte address 6byte data 1byte flag
module REG2UART(
	input en,
	input clk,
	input [7:0] address,
	input [47:0] regs,
	output [7:0] dout,
	input busy,
	output o_en=0,
	output isBusy
);
	//状态机
	reg [2:0] current_state=IDLE;
	reg [2:0] next_state=IDLE;
	//计数器
	reg [3:0] counter = 7;
	//数据
	reg [7:0] data[0:7];
	
	parameter IDLE	= 0;
	parameter SAVEING_DATA = 1;
	parameter SENDING_START = 2;
	parameter SENDING_ADD = 3;
	parameter SENDING_END = 5;
	
	//状态转换
	always_ff@(posedge clk)begin
		current_state <= next_state;
	end
	//第二个进程，组合逻辑always模块，描述状态转移条件判断
	always_comb begin
		next_state = IDLE;
		case(current_state)
			IDLE:
				if(en)
					next_state = SAVEING_DATA;
				else
					next_state = IDLE;
			SAVEING_DATA:
				next_state = SENDING_START;
			SENDING_START:
				if(busy)
					next_state = SENDING_ADD;
				else
					next_state = SENDING_START;
			SENDING_ADD:
				next_state = SENDING_END;
			SENDING_END:
				if(!busy)begin
					if(counter >= 8)
						next_state = IDLE;
					else 
						next_state = SENDING_START;
				end
				else
					next_state = SENDING_END;
			default:
				next_state = IDLE;
		endcase
	end
	
	always_ff@(posedge clk)begin
		case(current_state)
			IDLE:begin
				o_en <= 0;
				counter <= 0;
				isBusy <= 0;
			end
			SAVEING_DATA:begin
				data[0] <= {address[7:1],1'b0};
				data[1] <= {regs[47:41],1'b0};
				data[2] <= {regs[39:33],1'b0};
				data[3] <= {regs[31:25],1'b0};
				data[4] <= {regs[23:17],1'b0};
				data[5] <= {regs[15:9],1'b0};
				data[6] <= {regs[7:1],1'b0};
				data[7] <= {address[0],regs[40],
								regs[32],regs[24],
								regs[16],regs[8],
								regs[0],1'b1};
				
				counter <= 0;
				isBusy <= 1;
			end
			SENDING_START:begin
				o_en <= 1;
				dout <= data[counter];
			end
			SENDING_ADD:begin
				o_en <= 0;
				counter <= counter+1'b1;
			end
			SENDING_END:begin
			end
		endcase
	end
	
endmodule 
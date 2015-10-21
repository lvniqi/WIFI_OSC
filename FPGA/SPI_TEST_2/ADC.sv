module ADC(
	input clk,
	input [7:0]data,
	output fifo,
	output trigger,
	output clk_a,
	//FIFO
	input r_clk,
	input clear,
	output [31:0] len,
	output [7:0] data_out,
	output send_en
);
	//上升下降沿触发器
	ADC_TRIGGER(
	.clk(clk),
	.data(data),
	.max(150),
	.min(100),
	.trigger(trigger)
	);
	//FIFO控制块
	ADC_FIFO_CONTROL(
	.clk(clk),
	.data(data),
	.trigger(trigger),
	//读取
	.r_clk(r_clk),
	.clear(clear),
	.data_out(data_out),
	.len(len),
	.isFull(send_en)
	);
	assign clk_a = clk;
endmodule
 
module ADC_TRIGGER(
	input clk,
	input [7:0] data,
	input [7:0] max,
	input [7:0] min,
	output reg trigger
);
	always@(posedge clk)begin
		if(data>max)
			trigger = 1;
		else if(data < min)
			trigger = 0;
	end
endmodule 
module ADC_FIFO_CONTROL #(parameter LEN=3000)(
	//写入
	input clk,
	input trigger,
	input [7:0] data,
	//读取
	input r_clk,
	input clear,
	output [7:0] data_out,
	output logic [31:0] len,
	output logic isFull = 0,
	output logic isW = 1
);
	logic wait_trigger;
	wire [31:0] len_cache;
	ADC_FIFO(
		//写入
		.data(data),
		.wrclk(clk),
		.wrreq(isW),
		.wrusedw(len_cache),
		//读取
		.rdreq(isFull),
		.q(data_out),
		.rdclk(r_clk),
		
	);
	logic [1:0] trigger_save;
	always@(posedge clk)begin
		trigger_save <= {trigger_save[0],trigger};
		end
	assign trigger_t = (trigger_save == 2'b01);
	//等待触发
	always@(posedge clk or posedge clear)begin
		if(clear)begin
			isFull <= 0;
		end
		else if(clk)begin
			if(len_cache > LEN-2)begin
				isW <= 0;
				isFull <= 1;
				len <= len_cache+1;
			end
			if(trigger_t&&~isFull)begin
				isW <= 1;
			end
		end
	end
endmodule 

module ADC_FIFO_CONTROL_2 #(parameter LEN=3000)(
	//写入
	input clk,
	input trigger,
	input [7:0] data,
	//读取
	input r_clk,
	input clear,
	output [7:0] data_out,
	output logic [31:0] len,
	output logic isFull = 0,
	output logic isW = 1
);
	//长度缓冲
	wire [31:0] len_cache;
	//FIFO缓冲
	ADC_FIFO(
		//写入
		.data(data),
		.wrclk(clk),
		.wrreq(isW),
		.wrusedw(len_cache),
		//读取
		.rdreq(isFull),
		.q(data_out),
		.rdclk(r_clk),
	);
	
	//状态机
	reg [1:0] current_state=IDLE;
	reg [1:0] next_state=IDLE;
	parameter IDLE	= 2'b00;
	parameter WAIT_TRIGGER = 2'b01;
	parameter SAVING = 2'b11;
	parameter SENDING = 2'b10;
	//状态转换
	always_ff@(posedge clk)begin
		current_state <= next_state;
	end
	//第二个进程，组合逻辑always模块，描述状态转移条件判断
	always_comb begin
		next_state = IDLE;
		case(current_state)
			//空闲等待触发
			IDLE:
				if(trigger == 0)
					next_state = WAIT_TRIGGER;
				else 
					next_state = IDLE;
			//等待触发
			WAIT_TRIGGER:
				if(trigger == 1)
					next_state = SAVING;
				else
					next_state = WAIT_TRIGGER;
			//存入FIFO
			SAVING:
				if(len_cache > LEN-2)
					next_state = SENDING;
				else
					next_state = SAVING;
			//发送数据
			SENDING:
				if(clear)
					next_state = IDLE;
				else
					next_state = SENDING;
		endcase
	end
	always_ff@(posedge clk)begin
		case(current_state)
			IDLE:begin
				isW <= 0;
				isFull <= 0;
			end
			WAIT_TRIGGER:begin
				isW <= 0;
				isFull <= 0;
			end
			SAVING:begin
				isW <= 1;
				isFull <= 0;
				len <= len_cache+1;
			end
			SENDING:begin
				isW <= 0;
				isFull <= 1;
			end
		endcase
	end
	
endmodule 
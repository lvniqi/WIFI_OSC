module ADC(
	input clk,
	input [7:0]data,
	output fifo,
	output clk_a,
	//触发器
	output trigger,
	output is_ingore,
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
	//判断是否忽略触发器
	ADC_TRIGGER_I(
	.clk(clk),
	.trigger(trigger),
	.is_ingore(is_ingore)
	);
	//FIFO控制块
	ADC_FIFO_CONTROL(
	.clk(clk),
	.data(data),
	//触发
	.trigger(trigger),
	.isIngore(is_ingore),
	//读取
	.r_clk(r_clk),
	.clear(clear),
	.data_out(data_out),
	.len(len),
	.isFull(send_en)
	);
	assign clk_a = clk;
endmodule
//触发器模块
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
//忽略触发器？
module ADC_TRIGGER_I#(parameter DELAY = 2500000)(
	input clk,
	input trigger,
	output reg is_ingore
);
	reg [31:0] counter;
	reg trigger_save;
	always@(posedge clk)begin
		if(trigger_save != trigger)begin
			trigger_save <= trigger;
			counter <= 0;
			is_ingore <=0;
		end
		else begin
			if(counter >= DELAY)begin
				is_ingore <= 1;
			end
			else begin
				counter <= counter+1;
				is_ingore <=0;
			end
		end
	end
endmodule 
module ADC_FIFO_CONTROL #(parameter LEN=3000)(
	//写入
	input clk,
	input [7:0] data,
	
	//触发
	input isIngore,
	input trigger,
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
	reg [2:0] current_state=IDLE;
	reg [2:0] next_state=IDLE;
	parameter IDLE	= 0;
	parameter WAIT_TRIGGER = 1;
	parameter SAVING = 2;
	parameter SAVE_LEN = 3;
	parameter SENDING = 4;
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
				if(isIngore == 1)
					next_state = SAVING;
				else if(trigger == 0)
					next_state = WAIT_TRIGGER;
				else 
					next_state = IDLE;
			//等待触发
			WAIT_TRIGGER:
				if(trigger == 1||isIngore == 1)
					next_state = SAVING;
				else
					next_state = WAIT_TRIGGER;
			//存入FIFO
			SAVING:
				if(len_cache > LEN-2)
					next_state = SAVE_LEN;
				else
					next_state = SAVING;
			//保存长度
			SAVE_LEN:
				next_state = SENDING;
			//发送数据
			SENDING:
				if(clear)
					next_state = IDLE;
				else
					next_state = SENDING;
			default:
				next_state = IDLE;
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
			end
			SAVE_LEN:begin
				isW <= 0;
				isFull <= 0;
				len <= len_cache;
			end
			SENDING:begin
				isW <= 0;
				isFull <= 1;
			end
		endcase
	end
	
endmodule 
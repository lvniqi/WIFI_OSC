module ADC(
	input clk,
	input [7:0]data,
	output fifo,
	output clk_o,
	//分频系数
	input [15:0] adc_freq,	
	//触发器
	output trigger,
	output is_ingore,
	//FIFO
	input r_clk,
	input clear,
	output [31:0] len,
	output [7:0] data_out,
	output send_en,
	//测频器
	output [47:0] freq_data,
	output freq_busy
);
	wire adc_clk;
	wire main_clk;
	//ADC时钟
	Div_c(.clk_in(clk),.clk_div(adc_clk),.div_step(adc_freq));
	//主时钟1MHZ
	Div #(.N(200))(.clk_in(clk),.clk_div(main_clk));
	//上升下降沿触发器
	ADC_TRIGGER(
	.clk(adc_clk),
	.data(data),
	.max(150),
	.min(100),
	.trigger(trigger)
	);
	//测频模块
	GET_FREQ(
	.clk_main(main_clk),
	.clk_test(trigger),
	.freq_data(freq_data),
	.isBusy(freq_busy)
	);
	//判断是否忽略触发器
	ADC_TRIGGER_I(
	.clk(main_clk),
	.trigger(trigger),
	.is_ingore(is_ingore)
	);
	//FIFO控制块
	ADC_FIFO_CONTROL(
	.clk(adc_clk),
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
	assign clk_o = adc_clk;
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
module ADC_TRIGGER_I#(parameter DELAY = 100000)(
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
//测频模块状态机
module GET_FREQ(
	input en,rst_n,
	input clk_main,clk_test,
	output [47:0] freq_data,
	output isBusy
);
	reg freq_control = 0;
	wire freq_ready;
	wire clk_en;
	//开关时钟20HZ
	Div #(.N(50000))(.clk_in(clk_main),.clk_div(clk_en));
	GET_FREQ_EQUAL(
	//.en(freq_control),
	.en(1),
	.clk_en(clk_en),
	.clk_base(clk_main),
	.clk_test(clk_test),
	.base_count(freq_data[47:24]),
	.test_count(freq_data[23:0]),
	.isReady(freq_ready)
	);
	//状态机
	reg [1:0] current_state=IDLE;
	reg [1:0] next_state=IDLE;
	parameter IDLE	= 0;
	//状态转换
	always_ff@(posedge clk_main)begin
		current_state <= next_state;
	end
	
endmodule 
//等精度测频模块
module GET_FREQ_EQUAL(
					input en,input clk_en,
					input clk_base,input clk_test,
					output reg[23:0] base_count,
					output reg[23:0] test_count,
					output reg isReady = 0);
	reg[23:0] base_count_hide;
	reg[23:0] test_count_hide;
	reg isCount = 0;
	//门控
	always@(posedge clk_test)begin
		if(clk_en)
			isCount <= 1;
		else begin
			isCount <= 0;
		end
	end
	//标准时钟计数
	always@(posedge clk_base)begin
		if(isCount)begin
			base_count_hide<= base_count_hide+1;
		end
		else 
			base_count_hide <= 0;
		
	end
	//测试时钟计数
	always@(posedge clk_test)begin
		if(isCount)begin
			test_count_hide<= test_count_hide+1;
		end
		else 
			test_count_hide = 0;
		
	end
	//保存数据
	always@(negedge isCount or negedge en)begin
		if(!en)begin
			isReady <= 0;
		end
		else begin
			test_count  <= test_count_hide;
			base_count  <= base_count_hide;
			isReady <= 1;
		end
	end
endmodule 
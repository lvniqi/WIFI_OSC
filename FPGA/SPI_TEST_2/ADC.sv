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
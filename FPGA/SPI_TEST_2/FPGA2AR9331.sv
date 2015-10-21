/*
* 保存MCU地址
* module SAVE_ADDR
* */

`define DELAY_LEN (1000)
module FPGA2AR9331(input clk,input rst_n,
					 input [7:0]data_in,//tttttttttttttt
					 input en,
					 input[31:0] len_in,
					 input ack,
					 output reg clk_out,
					 output reg [7:0]data_out,
					 output [4:0]status,
					 output isWAIT,
					 //读fifo时钟
					 output reg r_clk
					 );
	//状态
	parameter [4:0] IDLE = 3'd0,
					SEND_START_SAVE = 1,SEND_START = 2,
					SEND_START_2 = 3,SEND_START_3 = 4,
					SEND_ING_0 = 5,SEND_ING_1 = 6,SEND_ING_2 = 7,
					SEND_ING_3 = 8,SEND_ING_4 = 9,
					SEND_END = 10,DELAY_1 = 11,DELAY_2 = 12,DELAY_3 = 13;
	reg [4:0] current_state=IDLE,next_state=IDLE;
	reg ack_save;
	reg [31:0] len;
	//计数器延时
	reg [31:0] delay_counter;
	assign status = ~current_state;
	assign isWAIT = (current_state == DELAY_3);
	//wire [7:0]data_in;
	//fifo_control(.clk(r_clk),.data(data_in));
	//第一个进程，同步时序always模块，用于状态转移
	always @ (posedge clk or negedge rst_n) begin   
		if(!rst_n) begin 
			current_state <= IDLE;
			end
		else if(clk) begin 
			current_state <= next_state;//注意，使用的是非阻塞赋值
			end
		end
	//第二个进程，组合逻辑always模块，描述状态转移条件判断
	always@(current_state or en or ack or len or delay_counter) begin
		next_state = IDLE;
		if(!rst_n) begin
			next_state = IDLE;
		end
		else begin
			case (current_state)
				//空闲状态
				IDLE: begin 
					if(en)
						next_state = SEND_START_SAVE;
					else
						next_state = IDLE;
					end
				//保存数据先
				SEND_START_SAVE:begin
					next_state = SEND_START;
					end
				//开始发送 发送状态数据
				SEND_START: begin
					next_state = SEND_START_2;
					end
				//开始发送 发送状态数据
				SEND_START_2: begin
					next_state = SEND_START_3;
					end
				//开始发送 发送状态数据
				SEND_START_3: begin
					next_state = SEND_ING_0;
					end
				//读取数据
				SEND_ING_0:begin
					next_state = SEND_ING_1;
					end
				//等待反馈
				SEND_ING_1: begin
					if(ack != ack_save)
						next_state = SEND_ING_2;
					else
						next_state = SEND_ING_1;
					end
				//计数器减一
				SEND_ING_2:begin
					next_state = SEND_ING_3;
					end
				SEND_ING_3: begin
					next_state = SEND_ING_4;
					end
				//发送下一个数据
				SEND_ING_4:begin
					if(len == 8'b0)
						next_state = SEND_END;
					else
						next_state = SEND_ING_0;
					end
				//发送结束
				SEND_END: begin
					if(ack != ack_save)
						next_state = DELAY_1;
					else
						next_state = SEND_END;
					end
				DELAY_1: begin
						next_state = DELAY_2;
					end
				DELAY_2: begin
					if(ack != ack_save)
						next_state = DELAY_3;
					else
						next_state = DELAY_2;
					end
				DELAY_3:begin
					if(delay_counter >= `DELAY_LEN)
						next_state = IDLE;
					else
						next_state = DELAY_3;
					end
				default:
						next_state = IDLE;
				endcase
			end
		end
	//第三个进程，组合逻辑always模块，描述状态转移条件判断
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			clk_out <= 1'bz;
			ack_save <= ack;
			data_out <= 8'hzz;
			r_clk <= 0;
			end
		else begin
			case(current_state)
				IDLE:begin
					ack_save <= ack;
					data_out <= 8'hzz;
					end
				SEND_START_SAVE:begin
					ack_save <= ack;
					//帧头
					data_out <= 54;
					delay_counter <= 0;
					//同步先
					r_clk <= 1;
					end
				SEND_START:begin
					len <= len_in;
					clk_out <= 1'b1;
					//同步先
					r_clk <= 0;
					end
				SEND_START_2:begin
					//同步先
					r_clk <= 1;
					end
				SEND_START_3:begin
					//同步先
					r_clk <= 0;
					end
				SEND_ING_0:begin
					r_clk <= 1;
					end
				SEND_ING_1:begin
					r_clk <= 0;
					end
				SEND_ING_2:begin
					ack_save <= ack;
					len <=  len-1'b1;
					clk_out <= ~clk_out;
					data_out <= data_in;
					end
				DELAY_1:begin
					data_out <= 8'hzz;
					ack_save <= ack;
					end
				DELAY_3:begin
					delay_counter = delay_counter+1'b1;
					clk_out <= 1'b0;
					end
				endcase
		end
	end
endmodule 

module fifo_control(input clk,
						  output reg[7:0] data,
						  output reg isfull);
	always@(posedge clk)begin
		data <= data+1;
		end
endmodule 
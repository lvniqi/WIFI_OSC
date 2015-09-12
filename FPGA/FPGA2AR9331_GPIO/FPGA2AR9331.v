/*
* 保存MCU地址
* module SAVE_ADDR
* */

`define DELAY_LEN (0+2)
module FPGA2AR9331(input clk,input rst_n,
					 //input [7:0]data_in,//tttttttttttttt
					 input en,
					 //input[7:0] len_in,
					 input ack,
					 output reg clk_out,
					 output reg [7:0]data_out
					 
					 );
	//状态
	parameter [4:0] IDLE = 3'd0,SEND_START = 1,SEND_ING_0 = 2,    
					SEND_ING_1 = 3,SEND_ING_2 = 4,SEND_END = 5,
					DELAY_1 = 6,DELAY_2 = 7,DELAY_3 = 8;
	reg [4:0] current_state=IDLE,next_state=IDLE;
	reg ack_save;
	reg [7:0] len;
	//计数器延时
	reg [4:0] delay_counter;
	
	//控制fifo时钟
	reg ctrl_clk;
	wire [7:0]data_in;
	fifo_control(.clk(ctrl_clk),.data(data_in));
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
	always@(posedge clk) begin
		next_state = IDLE;
		case (current_state)
			//空闲状态
			IDLE: begin 
				if(en)
					next_state = SEND_START;
				else
					next_state = IDLE;
				end
			//开始发送 发送状态数据
			SEND_START: begin
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
			//发送下一个数据
			SEND_ING_2: begin
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
			DELAY_3:
				if(delay_counter<2)
					next_state = IDLE;
				else
					next_state = DELAY_3;
			default:
					next_state = IDLE;
			endcase
		end
	//第三个进程，组合逻辑always模块，描述状态转移条件判断
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			end
		else begin
			case(next_state)
				IDLE:begin
					ack_save <= ack;
					data_out <= 8'hzz;
					delay_counter <= `DELAY_LEN;
					end
				SEND_START:begin
					//len <= len_in;
					len <= 8'h6;
					data_out <= 0;
					clk_out <= 1'b1;
					ack_save <= ack;
					end
				SEND_ING_0:begin
					ctrl_clk <= 1;
					end
				SEND_ING_1:begin
					ctrl_clk <= 0;
					end
				SEND_ING_2:begin
					if(ack != ack_save) begin
						clk_out <= !clk_out;
						len <=  len-1'b1;
						ack_save <= ack;
						end
					data_out <= data_in;
					end
				DELAY_1:begin
					data_out <= 8'hzz;
					ack_save <= ack;
					end
				DELAY_3:begin
					clk_out <= 1'b0;
					delay_counter <= delay_counter-1;
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
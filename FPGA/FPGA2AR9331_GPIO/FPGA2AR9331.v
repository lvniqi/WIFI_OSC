/*
* 保存MCU地址
* module SAVE_ADDR
* */
module FPGA2AR9331(input clk,input rst_n,
					 //input [7:0]data_in,//tttttttttttttt
					 input en,
					 //input[7:0] len_in,
					 input ack,output reg clk_out, output reg [7:0]data_out
					 );
	//状态
	parameter [4:0] IDLE = 3'd0,SEND_START = 1,    
					SEND_ING_1 = 2,SEND_ING_2 = 3,SEND_END = 4,DELAY_1 = 5,DELAY_2 = 6;
	//reg [1:0] current_state
	reg [4:0] current_state,next_state;
	reg ack_save,clk_out_temp;
	
	reg [7:0] data_out_temp;
	reg [7:0] len,len_temp;
	assign clk_n = !clk;
	//第一个进程，同步时序always模块，用于状态转移
	always @ (posedge clk or negedge rst_n) begin   
		if(!rst_n) begin 
			current_state <= IDLE;
			end
		else if(clk == 1) begin 
			current_state <= next_state;//注意，使用的是非阻塞赋值
			end
		end
	//第二个进程，组合逻辑always模块，描述状态转移条件判断
	always@(posedge clk) begin
		case (current_state)
			IDLE: begin 
				if(en)begin
					//len = len_in;
					len = 8'h44;
					data_out = 0;
					next_state = SEND_START;
					end
				end
			SEND_START: begin
				clk_out = 1'b1;
				ack_save = ack;
				next_state = SEND_ING_1;
				end
			SEND_ING_1: begin
				if(ack != ack_save)begin
						data_out_temp = data_out+1'b1;
						clk_out_temp = !clk_out;
						len_temp =  len-1'b1;
						next_state = SEND_ING_2;
					end
				end
			SEND_ING_2: begin
				data_out = data_out_temp;
				ack_save = ack;
				len = len_temp;
				if(len_temp == 8'b0)begin
					next_state = SEND_END;
					end
				else begin
					clk_out = clk_out_temp;
					next_state = SEND_ING_1;
					end
				end
				
			SEND_END: begin
				if(ack != ack_save)begin
					clk_out = 1'b0;
					clk_out_temp = 1'b0;
					next_state = DELAY_1;
					end
				end
			DELAY_1: begin
				next_state = DELAY_2;
				end
			DELAY_2: begin
				next_state = IDLE;
				end
			default:
					next_state = IDLE;
			endcase
		end
	//第三个进程，组合逻辑always模块，描述状态转移条件判断
endmodule 
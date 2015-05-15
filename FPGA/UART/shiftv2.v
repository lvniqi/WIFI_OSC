module shift_registerv2( 
        input clk,
        input en,
        input rst_n,
        input [31:0]data_in,
        input has_done,
        output reg[7:0] data_out,
        output reg command); 
   //define state
   parameter [1:0] IDLE=2'b00,START=2'b01,WAIT=2'b10,WAIT_2=2'b11;
   reg [1:0] current_state=IDLE,next_state=IDLE;
	reg [31:0] data_cache;
	wire real_en = en&has_done&(current_state == IDLE);
	//缓冲数据
	always@(posedge real_en)begin
		data_cache <= data_in;
		end
	//状态转换
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			current_state<= IDLE;
		else
			current_state<= next_state;
		end
	//发送个数 计数器
	reg [2:0] count = 0;
	//第二个进程，组合逻辑always模块，描述状态转移条件判断
	always@(current_state or real_en or has_done or rst_n)begin
		next_state = IDLE;
		if(!rst_n)
			next_state = IDLE;
		else begin
			case(current_state)
				//空闲状态
				IDLE:begin
					//外部使能 进入发送
					if(real_en)begin
						next_state = START;
						end
					else
						next_state = IDLE;
					end
				START:begin
					//正在发送，进入下一状态
					if(!has_done)begin
						next_state = WAIT;
						end
					else
						next_state = START;
					end
				WAIT:begin
					//数据发送完成
					if(has_done)
						next_state = WAIT_2;
					else
						next_state = WAIT;
					end
				WAIT_2:begin
					if(count >= 5)
						next_state = IDLE;
					else
						next_state = START;
					end
				default:next_state = IDLE;
				endcase
			end
		end
	//第三个进程，同步时序always模块，格式化描述次态寄存器输出
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
			command <= 0;
			count <= 0;
			data_out <= 8'bz;
			end
		else begin
			case(next_state)
				IDLE: begin
					command <= 0;
					count <= 0;
					end
				START:begin
					case (count)
						3'b000:
							data_out <= data_cache[31:24];
						3'b001:
							data_out <= data_cache[23:16];
						3'b010:
							data_out <= data_cache[15:8];
						3'b011:
							data_out <= data_cache[7:0];
						3'b100:
							data_out <= 8'b1;
						default:
							data_out <= 8'bz;
						endcase
					command <= 1;
					end
				WAIT: begin
					command <= 0;
					end
				WAIT_2: begin
					count <= count + 1'b1;
					command <= 0;
					end
				default:begin
					data_out <= 8'bz;
					command <= 0;
					end
				endcase
			end
		end
	endmodule 
module select_addr(input en,input [31:0]data_in,output reg rst_data_send=1);
	always@(*)
		if(data_in=={7'b0,1'b1,24'b0}&&en)begin
			rst_data_send = 0;
			end
		else 
			rst_data_send = 1;
	endmodule 
`timescale 1ns / 1ps
//DAC轮询刷新
module DAC_POLLING(
	input en,
	input [11:0] data_in[2:0],
	input clk_core,rst_n,
	output sclk,dout,sync_n,
	output [2:0]pos
);
	//define state
   parameter [1:0] IDLE=2'b00,SEND=2'b01,COUNT = 2'b11,END = 2'b10;
	parameter POS_LEN = 8;
	//parameter 
	reg [1:0] current_state=IDLE;
	reg [1:0] next_state=IDLE;
	reg [2:0] counter=0;
	//spi频率
	wire clk_spi;
	//dac数据
	reg [11:0] dac_data = 2048;
	//测试用 测试dac数据
	wire [11:0] dac_data_t;
	TEST_DAC_DATA(.pos(counter),.data(dac_data_t));
	//4分频器模块
	Div #(.N(8))(.clk_in(clk_core),.clk_div(clk_spi));
	//spi运行中状态
	wire spi_isIdle;
	wire spi_isEnd;
	reg spi_en = 0;
	//SPI输出模块
	SPI_OUT(
		.clk(clk_spi),
		.en(spi_en),
		.rst_n(rst_n),
		.data_in({4'b0,dac_data}),
		.sclk(sclk),
		.dout(dout),
		.sync_n(sync_n),
		.isIDLE(spi_isIdle),
		.isEND(spi_isEnd)
	);
	//状态转换
	always@(posedge clk_core or negedge rst_n)begin
		if(!rst_n)
			current_state<= IDLE;
		else
			current_state<= next_state;
		end
	//第二个进程，组合逻辑always模块，描述状态转移条件判断
	always@(current_state or rst_n or en 
				or spi_isIdle or spi_isEnd)begin
		next_state = IDLE;
		if(!rst_n)
			next_state = IDLE;
		else begin
			case(current_state)
				//空闲状态
				IDLE:
					//外部使能 进入发送
					if(en)
						next_state = SEND;
					else
						next_state = IDLE;
				//发送
				SEND:
					//如果发送完成 进入延时
					if(spi_isEnd)
						next_state = COUNT;
					else
						next_state = SEND;
				//减少计数
				COUNT:
						next_state = END;
				//结束
				END:
					//如果空闲
					if(spi_isIdle)
						next_state = IDLE;
					else
						next_state = END;
						
				default:next_state = IDLE;
			endcase
		end
	end
	//第三个进程，同步时序always模块，格式化描述次态寄存器输出
	always@(posedge clk_core or negedge rst_n)begin
		if(!rst_n)begin
		end
		else begin
			case(next_state)
				IDLE: begin
					pos <= 7;
					//dac_data <= 2048;
					spi_en <= 0;
				end
				SEND: begin
					spi_en <= 1;
				end
				COUNT: begin
					spi_en <= 0;
					pos <= counter;
					counter <= counter+1'b1;
				end
				END:begin
					dac_data <= dac_data_t;
				end
				default:begin
					
				end
			endcase
		end
	end
endmodule

`define SPI_LEN 16
module SPI_OUT( 
		  input clk,
        input [`SPI_LEN-1:0]data_in,
		  input rst_n,
		  input en,
		  output reg sclk,dout,sync_n,
		  //空闲状态
		  output isIDLE,
		  //延时输出状态
		  output isEND
		  );
   //define state
   parameter [1:0] IDLE=2'b00,SEND=2'b01,SEND_n = 2'b10,END = 2'b11;
   reg [1:0] current_state=IDLE;
	reg [1:0] next_state=IDLE;
	reg [4:0] counter=`SPI_LEN;
	reg [`SPI_LEN-1:0] data_in_save;
	assign isIDLE = (next_state == IDLE);
	assign isEND = (next_state == END);
	//状态转换
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)
			current_state<= IDLE;
		else
			current_state<= next_state;
	end
	//第二个进程，组合逻辑always模块，描述状态转移条件判断
	always@(current_state or sclk  or rst_n or en or counter)begin
		next_state = IDLE;
		if(!rst_n)
			next_state = IDLE;
		else begin
			case(current_state)
				//空闲状态
				IDLE:begin
					//外部使能 进入发送
					if(en)begin
						next_state = SEND_n;
					end
					else
						next_state = IDLE;
				end
				SEND:begin
					if(counter==5'd0)
						next_state=END;
					else if(!sclk)//正在发送，进入下一状态
						next_state = SEND_n;
					else
						next_state = SEND;
				end
				SEND_n:begin
					if(sclk)
						next_state = SEND;
					else
						next_state = SEND_n;
				end
				END:begin
					if(counter>5'd40)
						next_state=IDLE;
					else
						next_state = END;
				end
				default:next_state = IDLE;
			endcase
		end
	end
	//第三个进程，同步时序always模块，格式化描述次态寄存器输出
	always@(posedge clk or negedge rst_n)begin
		if(!rst_n)begin
		end
		else begin
			case(next_state)
				IDLE: begin
					data_in_save <= data_in;
					counter <=`SPI_LEN;
					sclk <= 1'b1;
					sync_n <= 1'b1;
				end
				SEND:begin
					sclk <= 1'b0;
					counter <= counter-1'b1;
				end
				SEND_n:begin
					sclk <= 1'b1;
					dout <= data_in_save[counter-1];
					sync_n <= 1'b0;
				end
				END:begin
					sclk <= 1'b1;
					sync_n <= 1'b1;
					counter <= counter+1'b1;
				end
				default:begin
				end
			endcase
		end
	end
endmodule 
	
module TEST_DAC_DATA(
	input [2:0] pos,
	output reg [11:0] data
);
	always@(*)
		case(pos)
			3'd0:data<=0;
			3'd1:data<=256;
			3'd2:data<=512;
			3'd3:data<=768;
			3'd4:data<=1024;
			3'd5:data<=1280;
			3'd6:data<=1536;
			3'd7:data<=1792;
		endcase
endmodule 
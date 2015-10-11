/*
* 8分频测试
* */
module Div(input clk_in,output reg clk_div);
	//分频数
	parameter N=8;
	reg [8:0]cnt=0;
	always@(posedge clk_in)begin
		if(cnt==N/2-1) begin
			clk_div <= !clk_div;
			cnt<=0;
		end
		else
			cnt <= cnt + 1'b1;
	end
endmodule
/*
* 4分频器
* */
module Divs_4(input clk,output reg clk_div4);
	//分频数
	parameter N=4;
	reg [26:0]cnt;
	always@(posedge clk)begin
		if(cnt==N/2-1) begin
			clk_div4 <= !clk_div4;
			cnt<=0;
		end
		else
			cnt <= cnt + 1'b1;
	end
endmodule 
/*
* 2分频器
* */
module Divs_2(input clk,output reg clk_div2);
	//分频数
	parameter N=2;
	reg [26:0]cnt;
	always@(posedge clk)begin
		if(cnt==N/2-1) begin
			clk_div2 <= !clk_div2;
			cnt<=0;
		end
		else
			cnt <= cnt + 1'b1;
	end
endmodule
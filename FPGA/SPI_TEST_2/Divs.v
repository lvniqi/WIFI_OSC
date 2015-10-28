/*
* 偶数分频
* */
module Div(input clk_in,output reg clk_div);
	//分频数
	parameter N=8;
	reg [23:0]cnt=0;
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
* 偶数分频
* */
module Div_c(input clk_in,output reg clk_div,
				 input [15:0] div_step);
	//分频数
	reg [15:0]cnt=0;
	always@(posedge clk_in)begin
		if(cnt>=div_step) begin
			clk_div <= !clk_div;
			cnt<=0;
		end
		else
			cnt <= cnt + 1'b1;
	end
endmodule
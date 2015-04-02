module UART_CLK(input clk,output reg bclk);
	reg [4:0] count = 0;
	always@(posedge clk)begin 
		count <= count +1'b1;
		if(count >=7) begin
			bclk <= !bclk;
			count <= 0;
		end
		end
endmodule 


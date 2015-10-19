module ADC(
	input clk,
	input [7:0]data,
	output fifo,
	output trigger,
	output clk_a
);
	ADC_TRIGGER(
	.clk(clk),
	.data(data),
	.max(200),
	.min(180),
	.trigger(trigger)
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
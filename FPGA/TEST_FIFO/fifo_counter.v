//单时钟FIFO 控制器
module fifo_counter(input wclk_in,rclk_in,
						  input rst_n,read,
						  input [7:0] data_in,
							output [15:0] counter,
							output [7:0] q);
	assign clk_run = read?rclk_in:wclk_in;
	assign wclk_out = wclk_in;
	assign rclk_out = clk_run;
	reg w_en;
	reg r_en;
	test_fifo(
		.clock(clk_run),
		.data(data_in),
		.rdreq(r_en),
		.wrreq(w_en),
		.q(q),
		.usedw(counter)
		);
	//计数
	//控制使能
	always@(*)begin
		if(read)begin
			if(counter >0)begin
				w_en <= 1'b0;
				r_en <= 1'b1;
				end
			end
		else if(counter >= 10)begin
			w_en<= 1'b1;
			r_en<= 1'b1;
			end
		else begin
			w_en<= 1'b1;
			r_en<= 1'b0;
			end
		end
endmodule 

//双时钟FIFO 控制器
module fifo_counter_d(input wclk_in,rclk_in,
						  input rst_n,
						  input write,read,
						  input [7:0] data_in,
							output wire rclk_out,wclk_out,
							output reg w_en=0,output reg r_en=0,
							output reg [15:0] counter=0,
							output [7:0] q,
							output [3:0] usedw);
	assign clk_run = read?rclk_in:wclk_in;
	assign wclk_out = wclk_in;
	assign rclk_out = clk_run;
	
	wire full;
	test_fifo_d(
		.data(data_in),
		.wrclk(wclk_in),
		.wrreq(w_en),
		.wrfull(full),
		
		.rdclk(rclk_in),
		.rdreq(r_en),
		.q(q),
		
		.wrusedw(usedw)
		);
	//满停止
	always@(posedge wclk_in)begin
		end
endmodule 
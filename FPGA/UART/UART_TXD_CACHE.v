module UART_TXD_CACHE(input T_com_in,
							 input clk,
							 input [7:0] T_BUF_in,
							 output T_com,
							 output reg[7:0]  T_BUF);
	always@(posedge T_com)
		T_BUF<=T_BUF_in;
	reg [2:0] com_reg;
	assign T_com = T_com_in;
	always@(posedge clk)begin
		com_reg <= {com_reg[1:0],T_com_in};
		end
endmodule 
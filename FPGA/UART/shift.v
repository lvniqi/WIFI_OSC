/*
*  yi wei ji cun qi 
*/
module shift_register( 
        input clk,input [7:0]data_in,
        output reg [31:0] data_out,
        output reg  done); 
   //define state
	reg [39:0] data = 39'b0;
   always @ (posedge clk) begin
		data={data[31:0],data_in};
		data_out = data[39:8];
		if(data[7:0] == 8'hff)
			done= 1;
		else 
			done= 0;
		end
endmodule 
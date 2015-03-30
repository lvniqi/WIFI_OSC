module shift_registerv2( 
        input clk,
        input en,
        input reset,
        input [31:0]data_in,
        input has_done,
        output reg[7:0] data_out,
        output done_test,
        output reg done); 
   //define state
   parameter [2:0] IDLE=0,START=1,WAIT=2,WAIT_2=3;
   reg [2:0] next_state=0,current_state=0;
   reg [7:0]  data_out_temp;//
   reg [31:0] data_in_temp,data_in_temp2;
   reg [3:0] cnt=0,cnt_temp = 0;
   assign done_test = reset;
   always @ (posedge clk or negedge reset) begin
		if(!reset)begin
			current_state <= IDLE;
			end
		else begin
			current_state <= next_state;
			end
		end
	always @(*) begin
		case (current_state)
			IDLE:begin
				done=0;
				cnt=0;
				cnt_temp=0;
				if(en==1) begin
					data_in_temp=data_in;
					next_state=START;
					end
				end
			START:begin	
				data_out=data_in_temp[7:0];
				done=1;
				data_in_temp2 = {8'b0,data_in_temp[31:8]};//you  yi 8 bit.....
				next_state=WAIT;
				cnt_temp = cnt+1'b1;				
				end
			WAIT:begin
				if(cnt_temp==4) begin
				    next_state=IDLE;
				    end
				else begin
					cnt=cnt_temp;
					data_in_temp = data_in_temp2;
					next_state=WAIT_2;
					done=0;
					end
				end
			WAIT_2:begin//waitting has done
				if(has_done)
					next_state=START;
				end
				default:
					next_state=IDLE;
			endcase
			end
endmodule
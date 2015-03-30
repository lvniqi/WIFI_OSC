/*
*  yi wei ji cun qi 
*/
module shift_register( 
        input clk,input [7:0]data_in,
        output [31:0] data_out,
        output done); 
   //define state
	reg [39:0] data;
	assign data_out = data[39:8];
	assign done = (data[7:0] == 8'hff);
   always @ (posedge clk) begin
		data={data[31:0],data_in};
		end
endmodule 
/*
module shift_register( 
        input en,reset,input [7:0]data_in,
        output reg[31:0] data_out,
        output reg done); 
   //define state
   reg [7:0]  data_out_temp;//
   reg [31:0] data_out_temp2=32'h0000;
   reg cnt=0;
   always @ (posedge en) begin
		data_out_temp=data_in;
		if(data_out_temp==8'hff) begin
			data_out=data_out_temp2;
			done=1;
			cnt=0;
			end
		else begin
			cnt=cnt+1;
				if(cnt==1)begin
					data_out_temp2[7:0]=data_out_temp;
					end
				if(cnt==2)begin
					data_out_temp2[15:8]=data_out_temp;
					end
				if(cnt==3)begin
					data_out_temp2[23:16]=data_out_temp;
					end
				if(cnt==4)begin
					data_out_temp2[31:24]=data_out_temp;
					end 
		        end//if error what
		end
endmodule
 //  first process
   /*
   always @ (posedge clk or negedge reset) begin
		if(!reset) begin
			current_state <= R_IDLE;
            cnt=0;
			end
		else begin
			current_state <= next_state;//注意，使用的是非阻塞赋值
	        end
	     end
   always @(posedge clk) begin
        case (current_state)
			R_IDLE: begin
				done=0;
				cnt=0;
				if(en==1) begin
					data_out_temp=data_in;
					next_state=R_START;
					end
				else
					next_state<=R_IDLE;
				end
			R_START:begin
				if(data_out_temp!=8'hff) begin
					//data_out_temp2[7:0] = data_out_temp;//..........................
					//next_state<=R_IDLE;
					next_state<=R_ING;
					end
				else
					next_state<=R_STOP;
                end
            R_ING: begin
			//	cnt=cnt+8;
            //    data_out_temp2[cnt+7:cnt] = data_out_temp;
				next_state<=R_IDLE;
				end
            R_STOP:begin
                done=1;
				data_out=data_out_temp2;		
                next_state=R_IDLE;
                end
            default:
                next_state=R_IDLE;
         endcase
         end
endmodule
*/
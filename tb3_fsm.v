`timescale 1ns / 1ps

module tb_FSM();

reg clk = 1'b0;

reg feedback = 1'b0;
reg get = 1'b0;
reg [7:0] get_index = 8'b0;
reg set = 1'b0;
reg [7:0] set_index = 8'b0;
reg reset = 1'b0;
reg [7:0] reset_index = 8'b0;

wire prediction;

integer loop_index = 0;
integer index = 0;

initial
begin
	while(1)
	begin
		#1; clk = 1'b1;
		#1; clk = 1'b0;
	end
end

always @(posedge clk)
begin
	// test get
	case(loop_index)
	        1:reset = 1'b1;
            2:reset = 1'b0;
	// test get
		4:get = 1'b1;
	    5:get = 1'b0;
	
	// test set
		6:
			begin
				set = 1'b1;
				feedback = 1'b1;
			end
	    7:
            begin
                set = 1'b0;
                feedback = 1'b0;
            end
        
        8:
          begin
            set = 1'b1;
            //feedback = 1'b1;
          end
        9:
          begin
            set = 1'b0;
            feedback = 1'b0;
          end        
	
	// test get-after-set
		10:get = 1'b1;
		11:get = 1'b0;
	
	// test reset
		14:reset = 1'b1;
		15:reset = 1'b0;
	
	// test get-after-reset
		16:get = 1'b1;
		17:get = 1'b0;

	endcase
	if (loop_index == 20)
	begin
	   if (index < 3)
	       begin
	       index = index + 1;
	       end
	   else
	       begin
	       index = 0;
	       end
	   loop_index = 0;
	   get_index = index;
	   set_index = index;
       reset_index = index;
    end
       

	loop_index = loop_index + 1;
end

	two_bit_counter DUT
	(
		.clk(clk),
		.feedback(feedback),
		.get(get),
		.get_index(get_index),
		.set(set),
		.set_index(set_index),
		.reset(reset),
		.reset_index(reset_index),
		.prediction(prediction)
	);

	endmodule


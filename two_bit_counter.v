`timescale 1ns / 1ps


// 2-bit state machine, for each address in the BTB
module two_bit_counter(
	input clk,
	input feedback,			// x_predict_res
	input fb_valid,			// flag that the x_predict_res we are reading is valid
	input [7:0] index,      // Index of which entry we are currently working on
	output reg prediction	// taken - not-taken bit
);
reg [1:0] state[3:0];   // TODO: make this parameterizable

always wait(fb_valid)
	// Update the state with the feedback from EX stage that is now available
begin
	if (feedback == 1'b1)
	begin
	   case(state[index])
	   2'b00: state[index] = 2'b01;
	   2'b01: state[index] = 2'b10;
	   2'b10: state[index] = 2'b11;
	   endcase
    end
    else // ?
    begin
       case(state[index])
       2'b01: state[index] = 2'b00;
       2'b11: state[index] = 2'b10;
       2'b10: state[index] = 2'b01;
       endcase
    end
       
end

always @(posedge clk)
begin

	assign prediction = state[1];
end

endmodule

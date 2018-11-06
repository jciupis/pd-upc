`timescale 1ns / 1ps

module two_bit_counter(
	input clk,
	input feedback,		      // Flag that indicates if an executed branch instruction was taken (1) or not taken (0).
	input set,                // Flag that indicates that the entry pointed to by index should be updated.
	input [7:0] set_index,    // Index of an entry to update.
	input reset,              // Flag that indicates that the entry pointed to by index should be reset.
	input [7:0] reset_index,  // Index of an entry to reset.
	output prediction	      // Flag that indicates if the branch is predicted to be taken (1) or not taken (0).
);

// TODO: make this parameterizable
reg [1:0] state [3:0];        // Array of predictor's state machines; each entry corresponds to a single PC stored in the predictor.

// Resetting process.
always @(posedge clk)
begin
    if (reset == 1'b1)
    begin
        // Initialize the state as weakly not taken.
        state[reset_index] = 2'b01;
    end
end

// Updating process.
always @(posedge clk)
begin
    if (set == 1'b1)
    begin
        if (feedback == 1'b1)
            case (state[set_index])
                2'b00: state[set_index] = 2'b01;
                2'b01: state[set_index] = 2'b10;
                2'b10: state[set_index] = 2'b11;
            endcase
        else
            case (state[set_index])
                2'b01: state[set_index] = 2'b00;
                2'b10: state[set_index] = 2'b01;
                2'b11: state[set_index] = 2'b10;
            endcase
    end
end

// TODO: Allow for returning a proper prediction by adding more inputs (get + get_index ?). 
assign prediction = 1'b0;

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.10.2018 12:40:03
// Design Name: 
// Module Name: branch_predictor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module branch_predictor(
    input clk,
    input [31:0] target_addr,        // TODO: check the core design to know when it can be used
    input [31:0] f_pc,               // (FETCH)  Address to make a prediction for.
    input [31:0] d_pc,               // (DECODE) If the decoded instruction is a branch, this input contains the PC value of the branch instruction.
    input d_is_branch,               // (DECODE) Flag that indicates if the decoded instruction is a branch.
    input x_predict_res,             // (EXEC)   Flag that indicates if the branch was actually taken.
    output [31:0] f_predict_addr,    // (FETCH)  Address that is predicted.
    output f_predict_valid           // (FETCH)  Flag that indicates if the prediction made should be used.
    );
    
    reg [31:0] in_addr_array [3:0];  // Table of stored PC values containing a branch instruction.
    reg [31:0] out_addr_array [3:0]; // Table of predicted target branches for the stored PC values.
    reg [31:0] tmp_out_addr = 31'b0; // Helper address of a temporary target branch.
    reg tmp_out_valid = 1'b0;        // Helper flag that indicates if a prediction is valid.
    reg addr_found = 1'b0;           // Flag that indicates if a given PC appears in the in_addr_array table.
    
    
    // (FETCH) Return a prediction if provided PC appears in the in_addr_array table.
    integer index;
    always @(posedge clk)
    begin
        // Initialize temporary outputs.
        tmp_out_addr <= 31'b0;
        tmp_out_valid <= 1'b0;
        
        // Iterate over stored PC values to check for provided PC.
        for (index = 0; index < 3; index = index + 1)
        begin
            if (f_pc == in_addr_array[index])
            begin
                tmp_out_addr = out_addr_array[index];
                tmp_out_valid = 1'b1;
                
                // TODO: this variable should be set to 0 after it's handled
                addr_found = 1'b1;
            end
        end
    end
    
    // (DECODE) Update in_addr_array if provided PC actually was a branch instruction.
    // TODO: If the PC provided in FETCH was not a branch, this step should be ignored.
    //       If the PC provided in FETCH was a branch and it appears in in_addr_array, this step should be ignored.
    //       If the PC probided in FETCH was a branch and it doesn't appear in in_addr_array, the PC provided
    //        in DECODE should be inserted in the in_addr_array and corresponding out_addr_array entry should be reset.
    
    // (EXEC) Update given branch's state machine according to result of the branch instruction.
    // TODO: Two-bit state machine should be implemented and its state should be changed appropriately.
    
    assign f_predict_addr  = tmp_out_addr;
    assign f_predict_valid = tmp_out_valid;

endmodule

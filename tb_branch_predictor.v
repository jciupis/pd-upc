`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.11.2018 12:22:59
// Design Name: 
// Module Name: tb_branch_predictor
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


module tb_branch_predictor(

    );

    reg clk = 1'b0;
    
    reg [31:0] target_addr = 32'b0;
    reg [31:0] f_pc = 32'b0;
    reg [31:0] d_pc = 32'b0;
    reg d_is_branch = 1'b0;
    reg x_predict_res = 1'b0;
    wire [31:0] f_predict_addr;
    wire f_predict_valid;
    
    integer loop_index = 0;
    
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
        loop_index = loop_index + 1;
        
        d_is_branch = 1'b0;       // Clear DECODE flag.
        x_predict_res = 1'b0;     // Clear EXEC feedback flag.
        d_pc = f_pc;              // DECODE PC is the PC from previous FETCH stage.
        f_pc = f_pc + 1;          // Fetch next instruction.
        
        if (loop_index == 1)
        begin
            d_is_branch = 1'b1;   // Every fourth instruction is a branch.
        end
        
        if (loop_index == 3)
        begin
            x_predict_res = 1'b1; // Two clocks after every branch instruction positive feedback follows.
        end 
        
        if (loop_index == 4)
        begin
            loop_index = 0;       // Wrap loop index after every 4 iterations.
        end
        
    end
    
    branch_predictor DUT
    (
        .clk(clk),
        .target_addr(target_addr),
        .f_pc(f_pc),
        .d_pc(d_pc),
        .d_is_branch(d_is_branch),
        .x_predict_res(x_predict_res),
        .f_predict_addr(f_predict_addr),
        .f_predict_valid(f_predict_valid)
    );
    
endmodule
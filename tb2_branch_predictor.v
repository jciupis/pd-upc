`timescale 1ns / 1ps

module tb_branch_predictor();

    reg clk = 1'b0;
    
    reg [31:0] d_target_addr = 32'b0; //From the DECODE stage
    reg [31:0] f_pc = 32'h0ff0;
    reg [31:0] d_pc = 32'b0;
    reg d_is_branch = 1'b0;
    reg x_predict_res = 1'b0;
    wire [31:0] f_predict_addr;
    wire f_predict_valid;
    reg providing_fb = 1'b0;    // For debug purposes, to see the correct (relative) signal timings 
    
    integer loop_index = 0;
    integer inst_visit_cnt = 1;  //dirty way to separate the first & second visit of specific cmds
    integer jump_tmp = 0;
    //integer s4 = 5; //Unused for the time being TODO: emulate actual register values to end the loop!
    //integer s5 = 1;
    
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
        providing_fb = 1'b0;
        d_is_branch = 1'b0;       // Clear DECODE flag indicating if the instruction was a branch.
        x_predict_res = 1'b0;     // Clear EXEC feedback flag.
        d_pc = f_pc;              // DECODE PC is the PC from previous FETCH stage.        
        case (inst_visit_cnt)
        1:
        begin
            case(f_pc)
            'h1008: // Changed because as 'reg' it will appear on the next cycle 
                begin
                d_is_branch = 1'b1; // For PC 0x1008
                d_target_addr = 'h1010;
                end
            'h100c:
                begin
                d_is_branch = 1'b1; // For PC 0x100c
                d_target_addr = 'h1014;
                end
             
            'h1010: x_predict_res = 0;
            'h1014:
                begin
                d_is_branch = 1'b1; // For PC 0x1014
                d_target_addr = 'h1000;
                x_predict_res = 1; // For PC 0x100c
                providing_fb = 1'b1;
                //d_pc = f_pc; //emulate normal behaviour
                end
            'h1018:
                begin
                f_pc = 'h1014; // Jump to 1014
                jump_tmp = 1;
                inst_visit_cnt = 2;
                end
            endcase
        end // case inst_visit_cnt : 1
        2:
        begin
           case(f_pc)
            'h1014:
                begin
                d_is_branch = 1'b1; //expect to find address in table!
                d_target_addr = 'h1000;
                x_predict_res = 0;
                providing_fb = 1'b1;
                end
            'h101c:
                begin
                x_predict_res = 1; //For PC 0x1014
                providing_fb = 1'b1;
                inst_visit_cnt = 3; //reset this as we can go to default case
                jump_tmp = 1;
                f_pc = 'h1000;
                end
            endcase
        end
        3:
        begin
            case(f_pc)
            'h100c:
                begin
                jump_tmp = 1;
                d_is_branch = 1'b1;
                d_target_addr = 'h1014;
                f_pc = 'h1014;
                end
            'h1014:
                begin
                jump_tmp = 1;
                d_is_branch = 1'b1;
                d_target_addr = 'h1000;
                f_pc = 'h1000;
                inst_visit_cnt = 0;
                end
            endcase
        end
        default:
        begin
            case (f_pc)
            // TODO:Use a waiting_feedback counter to determine what to do in 1000-4
            'h1000: // feedback for inst 1008 available)
                begin
                x_predict_res = 0;
                providing_fb = 1'b1;
                end
            'h1004:
                begin
                x_predict_res = 1; //feedback for inst 100c
                providing_fb = 1'b1;
                end
            'h1008:
                begin
                x_predict_res = 1; //feedback for inst 1014
                providing_fb = 1'b1;
                end
            'h100c: 
                begin
                d_is_branch = 1'b1;
                d_target_addr = 'h1014;
                jump_tmp = 1;
                f_pc = 'h1014;
                end
            'h1014:
                begin
                d_is_branch = 1'b1;
                jump_tmp = 1;
                f_pc = 'h1000;
                end
            endcase
        end
      endcase
     
        if (jump_tmp != 1) f_pc = f_pc + 4;          // Fetch next instruction.
        else jump_tmp = 0;              
    end
    
    branch_predictor DUT
    (
        .clk(clk),
        .target_addr(d_target_addr),
        .f_pc(f_pc),
        .d_pc(d_pc),
        .d_is_branch(d_is_branch),
        .x_predict_res(x_predict_res),
        .f_predict_addr(f_predict_addr),
        .f_predict_valid(f_predict_valid)
    );
    
endmodule
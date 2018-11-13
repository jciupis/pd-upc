`timescale 1ns / 1ps

module branch_predictor(
    input clk,
    input [31:0] f_pc,               // (FETCH)  Address to make a prediction for.
    input [31:0] d_pc,               // (DECODE) If the decoded instruction is a branch, this input contains the PC value of the branch instruction.
    input d_is_branch,               // (DECODE) Flag that indicates if the decoded instruction is a branch.
    input [31:0] d_target_addr,      // (DECODE) Target address of the branch instruction.
    input x_predict_res,             // (EXEC)   Flag that indicates if the branch was actually taken.
    output [31:0] f_predict_addr,    // (FETCH)  Address that is predicted.
    output f_predict_valid           // (FETCH)  Flag that indicates if the prediction made should be used.
    );

    // Helper variables.
    reg [31:0] f_out_addr = 32'b0;   // Address of target branch predicted in FETCH stage.
    reg f_addr_found = 1'b0;         // Flag that indicates if a PC from FETCH stage appears in the in_addr_array table.
    reg f_fsm_get = 0;               // Flag that indicates if the f_fsm_index entry shoud be read.
    reg [7:0] f_fsm_index = 8'b0;    // Index of an entry in the state machine to read state/prediction.
    reg d_addr_found = 1'b0;         // Latched f_addr_found flag available in DECODE stage.
    reg d_fsm_reset = 1'b0;          // Flag that indicates that a given state machine entry should be reset.
    reg [7:0] d_fsm_index = 8'b0;    // Index of an entry in state machine to modify.
    reg x_branch_processed = 1'b0;   // Flag that indicates that a branch instruction was processed and execution feedback is valid.
    reg x_fsm_set [2:0];             // Flag that indicates that a given state machine entry should be updated. Array for buffering/delay
    reg [7:0] x_fsm_index [2:0];     // Index of an entry in state machine to update in EXEC stage, with the array acting as a buffer
    reg x_feedback = 1'b0;           // Variable to latch/buffer the x_predict_res feedback from the CPU
                                     // We are experiencing timing issues between the feedback, set and set_index
                                     // signals, so until we find a better solution we work around it with this
                                     // not-so-elegant buffering. This happens because the predictor expects the feedback
                                     // cycles earlier than the CPU is ready to provide it.

    wire fsm_prediction;             // Gets the output of the predictor state machine.
    integer entry_to_replace = 0;    // Index of address table entry to replace.

    // Predictor's variables.
    reg [31:0] in_addr_array [3:0];  // Table of stored PC values containing a branch instruction.
    reg [31:0] out_addr_array [3:0]; // Table of predicted target branches for the stored PC values.
    two_bit_counter state_machine    // The branch predictor's 2bit state machine.
    (
        .clk(clk),
        .feedback(x_feedback),
        .get(f_fsm_get),
        .get_index(f_fsm_index),
        .set(x_fsm_set[2]),
        .set_index(x_fsm_index[2]),
        .reset(d_fsm_reset),
        .reset_index(d_fsm_index),
        .prediction(fsm_prediction)
    );

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // (FETCH) Return a prediction if provided PC appears in the in_addr_array table. //////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    integer f_index;
    integer d_index;
    integer index;

    initial
    begin
    for (index = 0; index < 3; index = index + 1)
        begin
        x_fsm_set[index] = 1'b0;
        x_fsm_index[index] = 8'b0;
        end
    end

    always @(posedge clk)
    begin
        // Initialize temporary outputs.
        f_addr_found = 1'b0;
        f_fsm_get = 1'b0;
        x_fsm_index[2] = x_fsm_index[1];
        x_fsm_index[1] = x_fsm_index[0];

        // Iterate over stored PC values to check for provided PC.
        for (f_index = 0; f_index < 4; f_index = f_index + 1)
        begin
            if (f_pc == in_addr_array[f_index])
            begin
                // Utilize the state machine.
                f_fsm_index = f_index;
                f_fsm_get = 1'b1;

                f_out_addr = out_addr_array[f_index];

                // This variable is set to 0 after it's handled.
                f_addr_found = 1'b1;

            end
        end
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // (DECODE) Update in_addr_array if provided PC actually was a branch instruction. /////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk)
    begin
        d_fsm_reset = 1'b0;
        d_addr_found = 1'b0;

        if (d_is_branch == 1'b1)
        begin
            // EXEC stage feedback is valid.
            x_branch_processed = 1'b1;

            for (d_index = 0; d_index < 4; d_index = d_index + 1)
            begin
                if (d_pc == in_addr_array[d_index])
                begin
                    d_addr_found = 1'b1;
                    // Latch index of the state machine entry to be updated when the EXEC stage feedback is provided.
                    x_fsm_index[0] = d_index;
                end
            end

            // A new branch instruction discovered. Insert it into the address table.
            if (d_addr_found == 1'b0)
            begin
                // Wrap up after the end of the array.
                if (entry_to_replace == 4)
                begin
                    entry_to_replace = 0;
                end

                // Initialize the predictor for the specified address.
                in_addr_array[entry_to_replace] = d_pc;

                // Get the decoded branch target address
                out_addr_array[entry_to_replace] = d_target_addr;
                d_fsm_index = entry_to_replace;
                d_fsm_reset = 1'b1;
                x_fsm_index[0] = entry_to_replace;

                // Select next entry to be replaced.
                entry_to_replace = entry_to_replace + 1;

            end
            // Otherwise ignore this step.
        end
        // Otherwise ignore this step.
    end

    ////////////////////////////////////////////////////////////////////////////////////////////////
    // (EXEC) Update given branch's state machine according to result of the branch instruction.  //
    ////////////////////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk)
    begin
        x_fsm_set[2] = x_fsm_set[1];
        x_fsm_set[1] = x_fsm_set[0];
        x_fsm_set[0] = 1'b0;
        x_feedback = x_predict_res;

        // Branch instruction was processed. Predictor's state machine must be updated.
        if (x_branch_processed == 1'b1)
        begin
            x_branch_processed = 1'b0;

            // Index of the entry to be updated is already set.
            x_fsm_set[0] = 1'b1;
        end
    end

    assign f_predict_addr  = f_out_addr;
    assign f_predict_valid = f_addr_found & fsm_prediction;

endmodule

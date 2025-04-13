//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module round_robin_arbiter_with_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests,
    output logic [1:0] grants
);
    // Task:
    // Implement a "arbiter" module that accepts up to two requests
    // and grants one of them to operate in a round-robin manner.
    //
    // The module should maintain an internal register
    // to keep track of which requester is next in line for a grant.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // requests -> 01 00 10 11 11 00 11 00 11 11
    // grants   -> 01 00 10 01 10 00 01 00 10 01

    logic selector;
    
    always_comb begin
        case (requests)
            2'b00: grants = 2'b00;
            2'b01: grants = 2'b01;
            2'b10: grants = 2'b10;
            default: grants = selector ? 2'b01 : 2'b10; 
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            selector <= 1'b0;
        end else begin
            case (requests)
                2'b01: selector <= 1'b0;
                2'b10: selector <= 1'b1;
                2'b11: selector <= ~selector;
                default: selector <= selector;
            endcase
        end
    end

endmodule
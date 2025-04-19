module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                       clk,
    input                       rst,

    input  [ n_inputs - 1 : 0 ] up_vlds,
    input  [ n_inputs - 1 : 0 ]
           [ width    - 1 : 0 ] up_data,

    output logic                      down_vld,
    output logic [ width   - 1 : 0 ]  down_data
);

    // Task:
    //
    // Implement a module that accepts many outputs of the computational blocks
    // and outputs them one by one in order. Input signals "up_vlds" and "up_data"
    // are coming from an array of non-pipelined computational blocks.
    // These external computational blocks have a variable latency.
    //
    // The order of incoming "up_vlds" is not determent, and the task is to
    // output "down_vld" and corresponding data in a round-robin manner,
    // one after another, in order.
    //
    // Comment:
    // The idea of the block is kinda similar to the "parallel_to_serial" block
    // from Homework 2, but here block should also preserve the output order.

    logic [width-1:0] fifo_queue [$];

    always_ff @(posedge clk) begin
        if (rst) begin
            fifo_queue = {};
            down_vld   <= 1'b0;
            down_data  <= '0;
        end else begin
            for (int i = 0; i < n_inputs; i++) begin
                if (up_vlds[i]) begin
                    fifo_queue.push_back(up_data[i]);
                end
            end
            if (fifo_queue.size() > 0) begin
                down_vld   <= 1'b1;
                down_data  <= fifo_queue.pop_front();
            end else begin
                down_vld   <= 1'b0;
                down_data  <= '0;
            end
        end
    end

endmodule
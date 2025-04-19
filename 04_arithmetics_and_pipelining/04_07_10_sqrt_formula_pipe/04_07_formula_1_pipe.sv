//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    // Task:
    //
    // Implement a pipelined module formula_1_pipe that computes the result
    // of the formula defined in the file formula_1_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_1_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    wire        sqrt_a_vld, sqrt_b_vld, sqrt_c_vld;
    wire [15:0] sqrt_a_res, sqrt_b_res, sqrt_c_res;

    isqrt #( .n_pipe_stages(4) ) isqrt_a_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (arg_vld),
        .x      (a),
        .y_vld  (sqrt_a_vld),
        .y      (sqrt_a_res)
    );

    isqrt #( .n_pipe_stages(4) ) isqrt_b_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (arg_vld),
        .x      (b),
        .y_vld  (sqrt_b_vld),
        .y      (sqrt_b_res)
    );

    isqrt #( .n_pipe_stages(4) ) isqrt_c_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (arg_vld),
        .x      (c),
        .y_vld  (sqrt_c_vld),
        .y      (sqrt_c_res)
    );

    assign res_vld = sqrt_a_vld;

    assign res = sqrt_a_res + sqrt_b_res + sqrt_c_res;

endmodule


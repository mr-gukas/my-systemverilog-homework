//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_fifos
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
    // Implement a pipelined module formula_2_pipe_using_fifos that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
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
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 04_10_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    // Stage 1: compute sqrt(c)
    wire                 stage1_vld;
    wire      [15:0]     stage1_data;
    isqrt #(.n_pipe_stages(16)) u_isqrt1 (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (arg_vld),
        .x      (c),
        .y_vld  (stage1_vld),
        .y      (stage1_data)
    );

    // FIFO for b to align with stage1 output
    wire                 b_fifo_push = arg_vld;
    wire                 b_fifo_pop  = stage1_vld;
    wire      [31:0]     b_fifo_rdata;
    wire                 b_fifo_empty, b_fifo_full;
    flip_flop_fifo_with_counter #(.width(32), .depth(16)) fifo_b (
        .clk         (clk),
        .rst         (rst),
        .push        (b_fifo_push),
        .pop         (b_fifo_pop),
        .write_data  (b),
        .read_data   (b_fifo_rdata),
        .empty       (b_fifo_empty),
        .full        (b_fifo_full)
    );

    // Stage 2: compute sqrt(b + stage1_data)
    wire                 stage2_vld;
    wire      [15:0]     stage2_data;
    wire      [31:0]     stage2_in = b_fifo_rdata + {{16{1'b0}}, stage1_data};
    isqrt #(.n_pipe_stages(16)) u_isqrt2 (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (stage1_vld),
        .x      (stage2_in),
        .y_vld  (stage2_vld),
        .y      (stage2_data)
    );

    // FIFO for a to align with stage2 output
    wire                 a_fifo_push = arg_vld;
    wire                 a_fifo_pop  = stage2_vld;
    wire      [31:0]     a_fifo_rdata;
    wire                 a_fifo_empty, a_fifo_full;
    flip_flop_fifo_with_counter #(.width(32), .depth(16)) fifo_a (
        .clk         (clk),
        .rst         (rst),
        .push        (a_fifo_push),
        .pop         (a_fifo_pop),
        .write_data  (a),
        .read_data   (a_fifo_rdata),
        .empty       (a_fifo_empty),
        .full        (a_fifo_full)
    );

    // Stage 3: compute sqrt(a + stage2_data) and drive outputs
    wire [31:0] stage3_in = a_fifo_rdata + {{16{1'b0}}, stage2_data};
    isqrt #(.n_pipe_stages(16)) u_isqrt3 (
        .clk   (clk),
        .rst   (rst),
        .x_vld(stage2_vld),
        .x     (stage3_in),
        .y_vld (res_vld),
        .y     (res[15:0])
    );
    assign res[31:16] = 16'b0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
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
    // Implement a pipelined module formula_2_pipe that computes the result
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
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    wire        sqrt_c_vld;
    wire [15:0] sqrt_c_res;
    
    wire        sqrt_bc_vld;
    wire [15:0] sqrt_bc_res;
    
    logic [31:0] a_reg [0:7]; 
    logic [31:0] b_reg [0:3]; 
    
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 8; i++) 
                a_reg[i] <= 0;
            for (int i = 0; i < 4; i++) 
                b_reg[i] <= 0;
        end else begin
            if (arg_vld) begin
                a_reg[0] <= a;
                b_reg[0] <= b;
            end
            
            for (int i = 1; i < 8; i++) 
                a_reg[i] <= a_reg[i-1];
            
            for (int i = 1; i < 4; i++) 
                b_reg[i] <= b_reg[i-1];
        end
    end
    
    isqrt #(.n_pipe_stages(4)) isqrt_c_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (arg_vld),
        .x      (c),
        .y_vld  (sqrt_c_vld),
        .y      (sqrt_c_res)
    );
    
    isqrt #(.n_pipe_stages(4)) isqrt_bc_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (sqrt_c_vld),
        .x      (b_reg[3] + {16'b0, sqrt_c_res}),
        .y_vld  (sqrt_bc_vld),
        .y      (sqrt_bc_res)
    );
    
    isqrt #(.n_pipe_stages(4)) isqrt_abc_inst (
        .clk    (clk),
        .rst    (rst),
        .x_vld  (sqrt_bc_vld),
        .x      (a_reg[7] + {16'b0, sqrt_bc_res}),
        .y_vld  (res_vld),
        .y      (res[15:0])
    );
    
    assign res[31:16] = 16'b0;

endmodule
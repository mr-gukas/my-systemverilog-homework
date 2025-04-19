//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    // Task:
    //
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    typedef enum logic [1:0] {
        S_IDLE,
        S_SQRT_A,
        S_SQRT_B,
        S_SQRT_C
    } state_t;
    
    state_t state, next_state;
    
    logic [31:0] a_reg, b_reg, c_reg;
    logic [31:0] result_acc;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always_comb begin
        next_state = state;
        
        case (state)
            S_IDLE: if (arg_vld) next_state = S_SQRT_A;
            S_SQRT_A: if (isqrt_y_vld) next_state = S_SQRT_B;
            S_SQRT_B: if (isqrt_y_vld) next_state = S_SQRT_C;
            S_SQRT_C: if (isqrt_y_vld) next_state = S_IDLE;
        endcase
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            a_reg <= 0;
            b_reg <= 0;
            c_reg <= 0;
        end else if (arg_vld && state == S_IDLE) begin
            a_reg <= a;
            b_reg <= b;
            c_reg <= c;
        end
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            result_acc <= 0;
            res_vld <= 0;
            res <= 0;
        end else begin
            if (isqrt_y_vld) begin
                if (state == S_SQRT_A) 
                    result_acc <= {16'b0, isqrt_y};
                else if (state == S_SQRT_B)
                    result_acc <= result_acc + {16'b0, isqrt_y};
                else if (state == S_SQRT_C) begin
                    res <= result_acc + {16'b0, isqrt_y};
                    res_vld <= 1;
                end
            end else begin
                res_vld <= 0;
            end
        end
    end
    
    // Логика входов isqrt
    always_comb begin
        isqrt_x_vld = 0;
        isqrt_x = 0;
        
        case (state)
            S_IDLE: begin
                isqrt_x_vld = arg_vld;
                isqrt_x = a;
            end
            S_SQRT_A: begin
                isqrt_x_vld = isqrt_y_vld;
                isqrt_x = b_reg;
            end
            S_SQRT_B: begin
                isqrt_x_vld = isqrt_y_vld;
                isqrt_x = c_reg;
            end
        endcase
    end

endmodule
//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_impl_2_fsm
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

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

    // Task:
    // Implement a module that calculates the formula from the `formula_1_fn.svh` file
    // using two instances of the isqrt module in parallel.
    //
    // Design the FSM to calculate an answer and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


    typedef enum logic [2:0] {
        ST_IDLE,      
        ST_CALC_AB,   
        ST_CALC_C,    
        ST_DONE       
    } state_t;

    state_t state, next_state;

    logic [31:0] a_reg, b_reg, c_reg; 
    logic [15:0] sqrt_a_reg, sqrt_b_reg; 
    logic sqrt_a_ready, sqrt_b_ready; 

    always_comb
    begin
        next_state = state; 

        case (state)
            ST_IDLE: begin
                if (arg_vld) begin
                    next_state = ST_CALC_AB;
                end
            end
            ST_CALC_AB: begin
                if (sqrt_a_ready && sqrt_b_ready) begin
                    next_state = ST_CALC_C;
                end
            end
            ST_CALC_C: begin
                if (isqrt_1_y_vld) begin 
                    next_state = ST_DONE;
                end
            end
            ST_DONE: begin
                next_state = ST_IDLE;
            end
            default: next_state = ST_IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        isqrt_1_x_vld = 1'b0;
        isqrt_1_x     = 32'bx; 
        isqrt_2_x_vld = 1'b0;
        isqrt_2_x     = 32'bx; 
        res_vld       = 1'b0;

        case (state)
            ST_IDLE: begin
                isqrt_1_x_vld = arg_vld;
                isqrt_1_x     = a;
                isqrt_2_x_vld = arg_vld;
                isqrt_2_x     = b;
            end
            ST_CALC_AB: begin
                if (sqrt_a_ready && sqrt_b_ready) begin
                    isqrt_1_x_vld = 1'b1;
                    isqrt_1_x     = c_reg; 
                end
            end
            ST_CALC_C: begin
            end
            ST_DONE: begin
                res_vld = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            a_reg <= 32'b0;
            b_reg <= 32'b0;
            c_reg <= 32'b0;
            sqrt_a_reg <= 16'b0;
            sqrt_b_reg <= 16'b0;
            sqrt_a_ready <= 1'b0;
            sqrt_b_ready <= 1'b0;
            res <= 32'b0;
        end else begin
            if (state == ST_IDLE && arg_vld) begin
                a_reg <= a;
                b_reg <= b;
                c_reg <= c;
                sqrt_a_ready <= 1'b0; 
                sqrt_b_ready <= 1'b0;
                res <= 32'b0; 
            end

            if (state == ST_CALC_AB) begin
                if (isqrt_1_y_vld) begin
                    sqrt_a_reg <= isqrt_1_y;
                    sqrt_a_ready <= 1'b1;
                end
                if (isqrt_2_y_vld) begin
                    sqrt_b_reg <= isqrt_2_y;
                    sqrt_b_ready <= 1'b1;
                end
                if (sqrt_a_ready && sqrt_b_ready) begin
                   res <= 32'(sqrt_a_reg) + 32'(sqrt_b_reg);
                end
            end

            if (state == ST_CALC_C && isqrt_1_y_vld) begin
                 res <= res + 32'(isqrt_1_y); 
            end
        end
    end

endmodule
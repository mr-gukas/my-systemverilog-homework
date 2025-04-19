//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_fsm
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
    // Implement a module that calculates the formula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


    enum logic [1:0] 
    {
        st_idle,       
        st_wait_c_res, 
        st_wait_b_res, 
        st_wait_a_res  
    }
    state, next_state;

    logic [31:0] reg_a, reg_b, reg_c;
    logic [15:0] sqrt_res_c; // Result of isqrt(c)
    logic [15:0] sqrt_res_b; // Result of isqrt(b + sqrt_res_c)

    always_comb
    begin
        next_state  = state;
        isqrt_x_vld = 1'b0;
        isqrt_x     = 32'bx; 

        case (state)
            st_idle:
            begin
                if (arg_vld)
                begin
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = c; // Use input 'c' directly
                    next_state  = st_wait_c_res;
                end
            end

            st_wait_c_res:
            begin
                if (isqrt_y_vld)
                begin
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = reg_b + 32'(isqrt_y); 
                    next_state  = st_wait_b_res;
                end
            end

            st_wait_b_res:
            begin
                if (isqrt_y_vld)
                begin
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = reg_a + 32'(isqrt_y); 
                    next_state  = st_wait_a_res;
                end
            end

            st_wait_a_res:
            begin
                if (isqrt_y_vld)
                begin
                    next_state = st_idle;
                end
            end
        endcase
    end

    always_ff @ (posedge clk)
    begin
        if (rst)
            state <= st_idle;
        else
            state <= next_state;
    end

    always_ff @ (posedge clk)
    begin
        if (rst)
        begin
            sqrt_res_c <= '0;
            sqrt_res_b <= '0;
        end
        else
        begin
            if (state == st_idle && arg_vld)
            begin
                reg_a <= a;
                reg_b <= b;
                reg_c <= c;
            end

            if (state == st_wait_c_res && isqrt_y_vld)
            begin
                sqrt_res_c <= isqrt_y;
            end

            if (state == st_wait_b_res && isqrt_y_vld)
            begin
                sqrt_res_b <= isqrt_y;
            end
        end
    end

    logic final_res_ready;
    assign final_res_ready = (state == st_wait_a_res && isqrt_y_vld);

    always_ff @ (posedge clk)
    begin
        if (rst)
            res_vld <= 1'b0;
        else
            res_vld <= final_res_ready; 
    end

    always_ff @ (posedge clk)
    begin
        if (rst)
        begin
            res <= 32'b0; // Clear result on reset
        end
        else if (final_res_ready)
        begin
            res <= 32'(isqrt_y);
        end
    end

endmodule
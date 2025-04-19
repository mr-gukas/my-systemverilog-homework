//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    localparam [FLEN-1:0] FOUR = 64'h4010000000000000;

    typedef enum logic [3:0] {
        S_IDLE,
        S_CHECK_INPUT,
        S_CALC_B_SQ,
        S_WAIT_B_SQ,
        S_CALC_AC,
        S_WAIT_AC,
        S_CALC_4AC,
        S_WAIT_4AC,
        S_CALC_SUB,
        S_WAIT_SUB,
        S_DONE
    } state_t;

    state_t state_reg, state_next;

    logic [FLEN-1:0] a_reg, b_reg, c_reg;
    logic [FLEN-1:0] b_sq_reg, ac_reg, four_ac_reg;
    logic [FLEN-1:0] res_reg;
    logic err_accum_reg, err_accum_next;

    logic            mult_up_valid;
    logic [FLEN-1:0] mult_a, mult_b;
    logic            mult_down_valid;
    logic [FLEN-1:0] mult_result;
    logic            mult_busy;
    logic            mult_error;

    logic            sub_up_valid;
    logic [FLEN-1:0] sub_a, sub_b;
    logic            sub_down_valid;
    logic [FLEN-1:0] sub_result;
    logic            sub_busy;
    logic            sub_error;

    f_mult mult_unit (
        .clk        (clk),
        .rst        (rst),
        .a          (mult_a),
        .b          (mult_b),
        .up_valid   (mult_up_valid),
        .res        (mult_result),
        .down_valid (mult_down_valid),
        .busy       (mult_busy),
        .error      (mult_error)
    );

    f_sub sub_unit (
        .clk        (clk),
        .rst        (rst),
        .a          (sub_a),
        .b          (sub_b),
        .up_valid   (sub_up_valid),
        .res        (sub_result),
        .down_valid (sub_down_valid),
        .busy       (sub_busy),
        .error      (sub_error)
    );

    function logic is_invalid_float (input [FLEN-1:0] val);
      localparam NE = (FLEN == 64) ? 11 : (FLEN == 32) ? 8 : 11;
      return &val[FLEN-2 : FLEN-1-NE];
    endfunction

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg     <= S_IDLE;
            a_reg         <= '0;
            b_reg         <= '0;
            c_reg         <= '0;
            b_sq_reg      <= '0;
            ac_reg        <= '0;
            four_ac_reg   <= '0;
            res_reg       <= '0;
            err_accum_reg <= 1'b0;
        end else begin
            state_reg     <= state_next;
            err_accum_reg <= err_accum_next;

            if (state_reg == S_IDLE && arg_vld) begin
                a_reg <= a;
                b_reg <= b;
                c_reg <= c;
            end

            if (state_reg == S_WAIT_B_SQ && mult_down_valid) begin
                b_sq_reg <= mult_result;
            end
            if (state_reg == S_WAIT_AC && mult_down_valid) begin
                ac_reg <= mult_result;
            end
            if (state_reg == S_WAIT_4AC && mult_down_valid) begin
                four_ac_reg <= mult_result;
            end
            if (state_reg == S_WAIT_SUB && sub_down_valid) begin
                res_reg <= sub_result;
            end
        end
    end

    always_comb begin
        state_next      = state_reg;
        res_vld         = 1'b0;
        mult_up_valid   = 1'b0;
        sub_up_valid    = 1'b0;
        mult_a          = 'x;
        mult_b          = 'x;
        sub_a           = 'x;
        sub_b           = 'x;
        err_accum_next  = err_accum_reg;

        case (state_reg)
            S_IDLE: begin
                err_accum_next = 1'b0;
                if (arg_vld) begin
                    state_next = S_CHECK_INPUT;
                end
            end

            S_CHECK_INPUT: begin
                err_accum_next = is_invalid_float(a_reg) | is_invalid_float(b_reg) | is_invalid_float(c_reg);
                state_next = S_CALC_B_SQ;
            end

            S_CALC_B_SQ: begin
                mult_up_valid = 1'b1;
                mult_a        = b_reg;
                mult_b        = b_reg;
                state_next    = S_WAIT_B_SQ;
            end

            S_WAIT_B_SQ: begin
                if (mult_down_valid) begin
                    err_accum_next = err_accum_reg | mult_error;
                    state_next     = S_CALC_AC;
                end
            end

            S_CALC_AC: begin
                mult_up_valid = 1'b1;
                mult_a        = a_reg;
                mult_b        = c_reg;
                state_next    = S_WAIT_AC;
            end

            S_WAIT_AC: begin
                if (mult_down_valid) begin
                    err_accum_next = err_accum_reg | mult_error;
                    state_next     = S_CALC_4AC;
                end
            end

            S_CALC_4AC: begin
                mult_up_valid = 1'b1;
                mult_a        = FOUR;
                mult_b        = ac_reg;
                state_next    = S_WAIT_4AC;
            end

            S_WAIT_4AC: begin
                if (mult_down_valid) begin
                    err_accum_next = err_accum_reg | mult_error;
                    state_next     = S_CALC_SUB;
                end
            end

            S_CALC_SUB: begin
                sub_up_valid = 1'b1;
                sub_a        = b_sq_reg;
                sub_b        = four_ac_reg;
                state_next   = S_WAIT_SUB;
            end

            S_WAIT_SUB: begin
                if (sub_down_valid) begin
                    err_accum_next = err_accum_reg | sub_error;
                    state_next     = S_DONE;
                end
            end

            S_DONE: begin
                res_vld    = 1'b1;
                state_next = S_IDLE;
            end

            default: state_next = S_IDLE;
        endcase
    end

    assign res          = res_reg;
    assign res_negative = res_reg[FLEN-1];
    assign err          = err_accum_reg;
    assign busy         = (state_reg != S_IDLE);

endmodule
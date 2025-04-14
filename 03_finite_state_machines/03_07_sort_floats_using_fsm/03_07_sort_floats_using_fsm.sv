//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    typedef enum logic [1:0] {
        S_IDLE,
        S_CMP1, // compare a, b
        S_CMP2, // compare w1, c
        S_CMP3  // compare w0, x1 
    } state_t;

    state_t state_reg, state_next;

    logic [FLEN - 1:0] a_reg, b_reg, c_reg;
    logic [FLEN - 1:0] w0_reg, w1_reg;
    logic [FLEN - 1:0] x1_reg, x2_reg; 
    logic err_reg, err_next;           
    logic [0:2][FLEN - 1:0] sorted_comb; 

    logic [FLEN - 1:0] w0_comb, w1_comb;
    logic [FLEN - 1:0] x1_comb, x2_comb;
    logic [FLEN - 1:0] s0_comb, s1_comb;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= S_IDLE;
            a_reg     <= '0;
            b_reg     <= '0;
            c_reg     <= '0;
            w0_reg    <= '0;
            w1_reg    <= '0;
            x1_reg    <= '0;
            x2_reg    <= '0;
            err_reg   <= 1'b0;
        end else begin
            state_reg <= state_next;
            err_reg   <= err_next; 

            if (state_reg == S_IDLE && valid_in) begin
                a_reg <= unsorted[0];
                b_reg <= unsorted[1];
                c_reg <= unsorted[2];
            end

            case (state_reg)
                S_CMP1: begin
                    w0_reg <= w0_comb;
                    w1_reg <= w1_comb;
                end
                S_CMP2: begin
                    x1_reg <= x1_comb;
                    x2_reg <= x2_comb;
                end
                default: ; 
            endcase
        end
    end

    always_comb begin
        state_next  = state_reg;
        valid_out   = 1'b0;
        f_le_a      = 'x;
        f_le_b      = 'x;
        err_next    = err_reg; 
        sorted      = 'x;      

        if (f_le_res) begin // a <= b ?
            w0_comb = a_reg;
            w1_comb = b_reg;
        end else begin
            w0_comb = b_reg;
            w1_comb = a_reg;
        end

        if (f_le_res) begin // w1 <= c ?
            x1_comb = w1_reg;
            x2_comb = c_reg;
        end else begin
            x1_comb = c_reg;
            x2_comb = w1_reg;
        end

        if (f_le_res) begin // w0 <= x1 ?
            s0_comb = w0_reg;
            s1_comb = x1_reg;
        end else begin
            s0_comb = x1_reg;
            s1_comb = w0_reg;
        end

        case (state_reg)
            S_IDLE: begin
                err_next = 1'b0; 
                if (valid_in) begin
                    state_next = S_CMP1;
                end
            end
            S_CMP1: begin
                f_le_a   = a_reg;
                f_le_b   = b_reg;
                err_next = f_le_err; 
                state_next = S_CMP2;
            end
            S_CMP2: begin
                f_le_a   = w1_reg; 
                f_le_b   = c_reg;
                err_next = err_reg | f_le_err; 
                state_next = S_CMP3;
            end
            S_CMP3: begin
                f_le_a   = w0_reg; 
                f_le_b   = x1_reg; 
                err_next = err_reg | f_le_err; 
                valid_out = 1'b1;
                sorted[0] = s0_comb;
                sorted[1] = s1_comb;
                sorted[2] = x2_reg; 
                state_next = S_IDLE;
            end
            default: state_next = S_IDLE;
        endcase
    end

    assign busy = (state_reg != S_IDLE);
    assign err = err_next; 

endmodule

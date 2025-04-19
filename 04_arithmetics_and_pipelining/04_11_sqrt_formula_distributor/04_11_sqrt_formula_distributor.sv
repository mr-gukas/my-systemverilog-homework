module sqrt_formula_distributor
# (
    parameter formula = 1,
              impl    = 1
)
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output logic        res_vld,
    output logic [31:0] res
);

    // Task:
    //
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.

    localparam NUM_CHAN = (formula == 1) ? 13 : 49;
    
    logic [31:0] arg_in_a  [NUM_CHAN];
    logic [31:0] arg_in_b  [NUM_CHAN];
    logic [31:0] arg_in_c  [NUM_CHAN];
    logic        arg_valid [NUM_CHAN];
    
    logic [31:0] res_out   [NUM_CHAN];
    logic        res_valid [NUM_CHAN];
    
    logic [7:0] channel_idx;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            channel_idx <= 0;
        end else begin
            if (channel_idx == (NUM_CHAN - 1))
                channel_idx <= 0;
            else
                channel_idx <= channel_idx + 1;
        end
    end
    
    always_comb begin
        for (int j = 0; j < NUM_CHAN; j++) begin
            arg_valid[j] = 1'b0;
        end
        
        arg_in_a[channel_idx]  = a;
        arg_in_b[channel_idx]  = b;
        arg_in_c[channel_idx]  = c;
        arg_valid[channel_idx] = arg_vld;
        
        res     = res_out[channel_idx];
        res_vld = res_valid[channel_idx];
    end

    generate
        genvar i;
        if (formula == 1) begin : gen_formula1
            for (i = 0; i < NUM_CHAN; i = i + 1) begin
                formula_1_impl_1_top u_formula1 (
                    .clk    (clk),
                    .rst    (rst),
                    .a      (arg_in_a[i]),
                    .b      (arg_in_b[i]),
                    .c      (arg_in_c[i]),
                    .arg_vld(arg_valid[i]),
                    .res_vld(res_valid[i]),
                    .res    (res_out[i])
                );
            end
        end else if (formula == 2) begin : gen_formula2
            for (i = 0; i < NUM_CHAN; i = i + 1) begin
                formula_2_top u_formula2 (
                    .clk    (clk),
                    .rst    (rst),
                    .a      (arg_in_a[i]),
                    .b      (arg_in_b[i]),
                    .c      (arg_in_c[i]),
                    .arg_vld(arg_valid[i]),
                    .res_vld(res_valid[i]),
                    .res    (res_out[i])
                );
            end
        end
    endgenerate

endmodule
module float_discriminant_distributor (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);

    // Task:
    //
    // Implement a module that will calculate the discriminant based
    // on the triplet of input number a, b, c. The module must be pipelined.
    // It should be able to accept a new triple of arguments on each clock cycle
    // and also, after some time, provide the result on each clock cycle.
    // The idea of the task is similar to the task 04_11. The main difference is
    // in the underlying module 03_08 instead of formula modules.
    //
    // Note 1:
    // Reuse your file "03_08_float_discriminant.sv" from the Homework 03.
    //
    // Note 2:
    // Latency of the module "float_discriminant" should be clarified from the waveform.

    localparam NUM_UNITS = 11;  // кол-во экземпляров модуля, исходя из латентности модуля
 
    logic                  unit_arg_vld   [NUM_UNITS-1:0];
    logic [FLEN - 1:0]     unit_a         [NUM_UNITS-1:0];
    logic [FLEN - 1:0]     unit_b         [NUM_UNITS-1:0];
    logic [FLEN - 1:0]     unit_c         [NUM_UNITS-1:0];
    
    logic                  unit_res_vld   [NUM_UNITS-1:0];
    logic [FLEN - 1:0]     unit_res       [NUM_UNITS-1:0];
    logic                  unit_res_neg   [NUM_UNITS-1:0];
    logic                  unit_err       [NUM_UNITS-1:0];
    logic                  unit_busy      [NUM_UNITS-1:0];
    
    logic [$clog2(NUM_UNITS)-1:0] in_idx;  // for new requests, on the next free module
    logic [$clog2(NUM_UNITS)-1:0] out_idx; // for res, on module we get results from 
    logic [NUM_UNITS-1:0]         unit_has_task;  
    logic [NUM_UNITS-1:0]         results_ready;  
    
    genvar i;
    generate
        for (i = 0; i < NUM_UNITS; i++) begin : disc_units
            float_discriminant disc_unit (
                .clk         (clk),
                .rst         (rst),
                .arg_vld     (unit_arg_vld[i]),
                .a           (unit_a[i]),
                .b           (unit_b[i]),
                .c           (unit_c[i]),
                .res_vld     (unit_res_vld[i]),
                .res         (unit_res[i]),
                .res_negative(unit_res_neg[i]),
                .err         (unit_err[i]),
                .busy        (unit_busy[i])
            );
        end
    endgenerate
    
    always_ff @(posedge clk) begin
        if (rst) begin
            in_idx <= 0;
            out_idx <= 0;
            unit_has_task <= 0;
            results_ready <= 0;
            res_vld <= 0;
        end
        else begin
            res_vld <= 0;
            
            if (arg_vld && !busy) begin
                unit_has_task[in_idx] <= 1'b1;
                in_idx <= (in_idx == NUM_UNITS-1) ? 0 : in_idx + 1;
            end
            
            for (int j = 0; j < NUM_UNITS; j++) begin
                if (unit_res_vld[j]) begin
                    results_ready[j] <= 1'b1;
                end
            end
            
            if (unit_has_task[out_idx] && results_ready[out_idx]) begin
                res_vld <= 1'b1;
                res <= unit_res[out_idx];
                res_negative <= unit_res_neg[out_idx];
                err <= unit_err[out_idx];
                
                unit_has_task[out_idx] <= 1'b0;
                results_ready[out_idx] <= 1'b0;
                out_idx <= (out_idx == NUM_UNITS-1) ? 0 : out_idx + 1;
            end
        end
    end
    
    always_comb begin
        for (int j = 0; j < NUM_UNITS; j++) begin
            unit_arg_vld[j] = 1'b0;
            unit_a[j] = 'x;
            unit_b[j] = 'x;
            unit_c[j] = 'x;
        end
        
        if (arg_vld && !busy) begin
            unit_arg_vld[in_idx] = 1'b1;
            unit_a[in_idx] = a;
            unit_b[in_idx] = b;
            unit_c[in_idx] = c;
        end
        
        busy = &unit_has_task;
    end
    
endmodule
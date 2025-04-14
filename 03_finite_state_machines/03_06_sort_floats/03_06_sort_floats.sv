//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module sort_two_floats_ab (
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,

    output logic [FLEN - 1:0] res0,
    output logic [FLEN - 1:0] res1,
    output                    err
);

    logic a_less_or_equal_b;

    f_less_or_equal i_floe (
        .a   ( a                 ),
        .b   ( b                 ),
        .res ( a_less_or_equal_b ),
        .err ( err               )
    );

    always_comb begin : a_b_compare
        if ( a_less_or_equal_b ) begin
            res0 = a;
            res1 = b;
        end
        else
        begin
            res0 = b;
            res1 = a;
        end
    end

endmodule

//----------------------------------------------------------------------------
// Example - different style
//----------------------------------------------------------------------------

module sort_two_floats_array
(
    input        [0:1][FLEN - 1:0] unsorted,
    output logic [0:1][FLEN - 1:0] sorted,
    output                         err
);

    logic u0_less_or_equal_u1;

    f_less_or_equal i_floe
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err                 )
    );

    always_comb
        if (u0_less_or_equal_u1)
            sorted = unsorted;
        else
              {   sorted [0],   sorted [1] }
            = { unsorted [1], unsorted [0] };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_three_floats (
    input        [0:2][FLEN - 1:0] unsorted,
    output logic [0:2][FLEN - 1:0] sorted,
    output                         err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order.
    // The module should be combinational with zero latency.
    // The solution can use up to three instances of the "f_less_or_equal" module.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    logic [FLEN - 1:0] w0, w1; 
    logic [FLEN - 1:0] x1, x2; 
    logic [FLEN - 1:0] s0, s1; 

    logic u0_le_u1; // unsorted[0] <= unsorted[1]
    logic w1_le_u2; // w1 <= unsorted[2]
    logic w0_le_x1; // w0 <= x1

    logic err01, err12, err01_again;

    f_less_or_equal i_floe_01 (
        .a   ( unsorted[0] ),
        .b   ( unsorted[1] ),
        .res ( u0_le_u1    ),
        .err ( err01       )
    );

    f_less_or_equal i_floe_12 (
        .a   ( w1          ), 
        .b   ( unsorted[2] ),
        .res ( w1_le_u2    ),
        .err ( err12       )
    );

    f_less_or_equal i_floe_01_again (
        .a   ( w0          ), 
        .b   ( x1          ), 
        .res ( w0_le_x1    ),
        .err ( err01_again )
    );

    always_comb begin
        if (u0_le_u1) begin
            w0 = unsorted[0];
            w1 = unsorted[1];
        end else begin
            w0 = unsorted[1];
            w1 = unsorted[0];
        end
    end

    always_comb begin
        if (w1_le_u2) begin
            x1 = w1;
            x2 = unsorted[2];
        end else begin
            x1 = unsorted[2];
            x2 = w1;
        end
    end

    always_comb begin
        if (w0_le_x1) begin
            s0 = w0;
            s1 = x1;
        end else begin
            s0 = x1;
            s1 = w0;
        end
    end

    assign sorted[0] = s0;
    assign sorted[1] = s1;
    assign sorted[2] = x2; 

    assign err = err01 | err12 | err01_again;

endmodule

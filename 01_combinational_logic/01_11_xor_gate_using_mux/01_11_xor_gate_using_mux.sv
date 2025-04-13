//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module xor_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement xor gate using instance(s) of mux,
  // constants 0 and 1, and wire connections

  wire not_b;
  wire mux_out;

  mux not_b_mux (
    .d0(1'b1),
    .d1(1'b0),
    .sel(b),
    .y(not_b)
  );

  // Then use another mux to implement XOR logic
  mux xor_mux (
    .d0(b),     
    .d1(not_b), 
    .sel(a),
    .y(o)
  );

endmodule

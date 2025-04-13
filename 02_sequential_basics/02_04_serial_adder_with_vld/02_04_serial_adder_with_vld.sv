//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_adder_with_vld
(
  input  clk,
  input  rst,
  input  vld,
  input  a,
  input  b,
  input  last,
  output sum
);

  // Task:
  // Implement a module that performs serial addition of two numbers
  // (one pair of bits is summed per clock cycle).
  //
  // It should have input signals a and b, and output signal sum.
  // Additionally, the module have two control signals, vld and last.
  //
  // The vld signal indicates when the input values are valid.
  // The last signal indicates when the last digits of the input numbers has been received.
  //
  // When vld is high, the module should add the values of a and b and produce the sum.
  // When last is high, the module should output the sum and reset its internal state, but
  // only if vld is also high, otherwise last should be ignored.
  //
  // When rst is high, the module should reset its internal state.
  
  logic current_sum;
  logic carry_generate;
  logic carry_in, carry_out;

  // Combinational logic for sum and carry
  assign current_sum   = a ^ b ^ carry_in;
  assign carry_generate = a & b;
  assign carry_out     = carry_generate | (carry_in & (a ^ b));

  // Sequential logic for carry propagation
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      carry_in <= 1'b0;
    end
    else if (vld) begin
      if (last) begin
        carry_in <= 1'b0;  // Reset carry on last valid input
      end
      else begin
        carry_in <= carry_out;  // Propagate carry to next cycle
      end
    end
  end

  assign sum = current_sum;

endmodule
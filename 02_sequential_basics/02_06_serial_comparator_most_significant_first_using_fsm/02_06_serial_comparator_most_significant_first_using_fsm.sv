//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module serial_comparator_least_significant_first_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);

  // States
  enum logic[1:0]
  {
     st_equal       = 2'b00,
     st_a_less_b    = 2'b01,
     st_a_greater_b = 2'b10
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    case (state)
      st_equal       : if (~ a &   b) new_state = st_a_less_b;
                  else if (  a & ~ b) new_state = st_a_greater_b;
      st_a_less_b    : if (  a & ~ b) new_state = st_a_greater_b;
      st_a_greater_b : if (~ a &   b) new_state = st_a_less_b;
    endcase

    // verilator lint_on  CASEINCOMPLETE
  end

  // Output logic
  assign a_eq_b      = (a == b) & (state == st_equal);
  assign a_less_b    = (~ a &   b) | (a == b & state == st_a_less_b);
  assign a_greater_b = (  a & ~ b) | (a == b & state == st_a_greater_b);

  always_ff @ (posedge clk)
    if (rst)
      state <= st_equal;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_comparator_most_significant_first_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  input  b,
  output a_less_b,
  output a_eq_b,
  output a_greater_b
);

  // Task:
  // Implement a serial comparator module similar to the previus exercise
  // but use the Finite State Machine to evaluate the result.
  // Most significant bits arrive first.

  typedef enum logic [1:0] {
    st_equal,      
    st_less,       
    st_greater     
  } state_t;

  state_t current_state, next_state;

  always_comb begin
    next_state = current_state;
    case (current_state)
      st_equal: begin
        if (a < b)
          next_state = st_less;
        else if (a > b)
          next_state = st_greater;
        else
          next_state = st_equal;
      end
      st_less:    next_state = st_less;
      st_greater: next_state = st_greater;
      default:    next_state = st_equal;
    endcase
  end

  assign a_eq_b      = (current_state == st_equal) && (a == b);
  assign a_less_b    = (current_state == st_less) || ((current_state == st_equal) && (a < b));
  assign a_greater_b = (current_state == st_greater) || ((current_state == st_equal) && (a > b));

  always_ff @(posedge clk) begin
    if (rst)
      current_state <= st_equal;
    else
      current_state <= next_state;
  end

endmodule

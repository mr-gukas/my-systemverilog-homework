//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      serial_valid,
    input                      serial_data,

    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);
    // Task:
    // Implement a module that converts serial data to the parallel multibit value.
    //
    // The module should accept one-bit values with valid interface in a serial manner.
    // After accumulating 'width' bits, the module should assert the parallel_valid
    // output and set the data.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    
    logic [width - 1:0] shift_reg;
    logic [$clog2(width + 1) - 1:0] bit_count;

    always_ff @(posedge clk) begin
        if (rst) begin
            shift_reg      <= '0;
            bit_count      <= '0;
            parallel_valid <= 1'b0;
            parallel_data  <= '0;
        end else begin
            if (serial_valid) begin
                shift_reg <= {serial_data, shift_reg[width - 1:1]};
                if (bit_count == width - 1) begin
                    parallel_valid <= 1'b1;
                    parallel_data  <= {serial_data, shift_reg[width - 1:1]};
                    bit_count      <= '0;
                end else begin
                    parallel_valid <= 1'b0;
                    bit_count      <= bit_count + 1;
                end
            end else begin
                parallel_valid <= 1'b0;
            end
        end
    end

endmodule
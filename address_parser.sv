module address_parser #(
    parameter int ROW_BITS = 8,  // log2(ROWS)
    parameter int COL_BITS = 4,  // log2(COLS)
    parameter int PADDR_BITS = 19
) (
    input  logic [PADDR_BITS-1:0] mem_bus_addr_in,
    output  logic [16:0] addr_out,  // [row][col]. Needs two cycles.
    output logic [1:0] bg_out,     // Bank group id
    output logic [1:0] ba_out      // Bank id
);

    localparam int buffer_bits = 17 - ROW_BITS - COL_BITS; // Assumed (row_bits + col_bits) <= 17. 

    // Address mapping strategy:
    // Lower bits: Column address (for row buffer locality)
    // Middle bits: Bank/Bank Group (for parallelism)
    // Upper bits: Row address

    
    logic [ROW_BITS-1:0] row;
    logic [COL_BITS-1:0] col;

    always_comb begin
        // Extract column bits (lowest order)
        col = mem_bus_addr_in[COL_BITS-1:0];
        
        // It is assumed that the # of bank groups AND # of banks
        //  per group are 4, since they each take 2 bits to index into
        ba_out = mem_bus_addr_in[COL_BITS+1:COL_BITS];
        bg_out = mem_bus_addr_in[COL_BITS+3:COL_BITS+2];
        
        // Row address takes the remaining upper bits
        // Note: We might not use all available row bits
        row = mem_bus_addr_in[COL_BITS + 4 + ROW_BITS - 1:COL_BITS+4];
        
        addr_out = {{(buffer_bits){1'b0}}, row, col}; // most significant bits ignored by the DRAM row
                                                    //  address selector if row_bits + col_bits < 17

    end

    // Assertions for parameter checking
    initial begin
        // Verify that we have enough input address bits
        assert (PADDR_BITS > (COL_BITS + 2 + 2))
        else $error("Input address bits insufficient for minimum addressing");

        assert (ROW_BITS + COL_BITS <= 17)
        else $error("Row and column bits are too much for the 17-bit address out");
    
    end

endmodule
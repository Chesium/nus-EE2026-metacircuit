`timescale 1ns / 1ps

// Fixed 18-column, nine-bit address domain. No division/modulo and no retiming.
// Removing 16*18 also preserves the original truncated row for addresses>=288.
module M5AddressCandidate(input wire [8:0] addr, output wire [8:0] position,
                          output wire [4:0] col, output wire [3:0] row, output wire [8:0] inverse);
    function [8:0] decode_position;
        input [8:0] value;
        reg [8:0] remainder;
        reg [3:0] quotient;
        begin
            remainder = value;
            quotient = 0;
            if (remainder >= 9'd288) remainder = remainder - 9'd288;
            if (remainder >= 9'd144) begin remainder = remainder - 9'd144; quotient[3] = 1; end
            if (remainder >= 9'd72) begin remainder = remainder - 9'd72; quotient[2] = 1; end
            if (remainder >= 9'd36) begin remainder = remainder - 9'd36; quotient[1] = 1; end
            if (remainder >= 9'd18) begin remainder = remainder - 9'd18; quotient[0] = 1; end
            decode_position = {quotient, remainder[4:0]};
        end
    endfunction
    assign position = decode_position(addr);
    assign col = position[4:0];
    assign row = position[8:5];
    assign inverse = addr[4:0] + addr[8:5] * 18;
endmodule

// Reference helpers are copied verbatim from the production source by the
// runner. This top exhausts the full two-state domain, including invalid cells.
module M5AddressEquivalence_test;
    reg [8:0] addr = 0;
    wire [8:0] reference_position, candidate_position;
    wire [4:0] reference_col, candidate_col;
    wire [3:0] reference_row, candidate_row;
    wire [8:0] reference_roundtrip, candidate_roundtrip, reference_inverse, candidate_inverse;
    wire inject = $test$plusargs("m5-inject-address-corruption");
    wire [8:0] observed_candidate = candidate_position ^ ((inject && addr == 9'd287) ? 9'd1 : 9'd0);
    M5AddressReference reference (.addr(addr), .position(reference_position),
        .col(reference_col), .row(reference_row), .roundtrip(reference_roundtrip),
        .candidate_position(candidate_position), .candidate_roundtrip(candidate_roundtrip), .inverse(reference_inverse));
`ifdef M5_USE_LIVE_ADDRESS_CANDIDATE
    M5AddressCandidateLive candidate
`else
    M5AddressCandidate candidate
`endif (.addr(addr), .position(candidate_position),
        .col(candidate_col), .row(candidate_row), .inverse(candidate_inverse));
    integer i, checks = 0, invalid_checks = 0;
    initial begin
        for (i = 0; i < 512; i++) begin
            addr = i;
            #1;
            if (observed_candidate !== reference_position ||
                candidate_col !== reference_col || candidate_row !== reference_row ||
                candidate_roundtrip !== reference_roundtrip || candidate_inverse !== reference_inverse)
                $fatal(1, "M5_ADDRESS_FAILURE addr=%0d reference=%h candidate=%h", i,
                       reference_position, observed_candidate);
            checks++;
            if (i >= 288) invalid_checks++;
        end
        $display("M5_ADDRESS_EQUIVALENCE checks=%0d invalid_checks=%0d helpers=4", checks, invalid_checks);
        $display("M5AddressEquivalence_test passed.");
        $finish;
    end
endmodule

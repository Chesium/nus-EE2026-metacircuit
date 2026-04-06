`timescale 1ns / 1ps

module CommandArbiter (
    input  wire        interaction_cmd_valid,
    input  wire [63:0] interaction_cmd_payload,
    input  wire        property_cmd_valid,
    input  wire [63:0] property_cmd_payload,
    output wire        arb_cmd_valid,
    output wire [63:0] arb_cmd_payload
);

  assign arb_cmd_valid = property_cmd_valid | interaction_cmd_valid;
  assign arb_cmd_payload = property_cmd_valid ? property_cmd_payload : interaction_cmd_payload;

endmodule

module key_select
(
input logic [9:0] switches,
output logic [23:0] output_key
);

assign output_key[9:0]=switches;
assign output_key[23:10]=14'b0;

endmodule
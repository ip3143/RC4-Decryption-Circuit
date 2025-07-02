module for_loop
(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       start,
  output logic       wren,
  output logic [7:0] data,
  output logic [7:0] addr,
  output logic       done
);

  // Internal memory array
  logic [7:0] i = 8'd0;
  logic [2:0] state;
  // Output signals
  assign done = state[2];
  assign data = i;
  assign addr = i;

  // State encoding
  parameter idle      = 3'b001;
  parameter add       = 3'b010;
  parameter finish    = 3'b100;

  // State transition logic
  always_ff @(posedge clk or posedge rst_n) 
  begin
    if (rst_n)
      begin
        state <= idle;
        i <= 8'd0;
      end
    else 
      begin
        case (state)
          idle:
            begin
              i <= 8'd0;
              wren <= 1'b1;
              if (start)
                state <= add;
              else
                state <= idle;
            end
          add:
            begin
              i <= i + 8'd1;
              state <= (i == 8'd255 ? finish : add);
            end
          finish:
          begin 
            wren <= 1'b0;
            i <= 8'd0;
          end
          default:state <= idle;
        endcase
      end
  end

endmodule
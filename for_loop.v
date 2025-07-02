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
  assign wren = state[1];
  assign data = i;
  assign addr = i;

  // State encoding
  parameter IDLE      = 3'b001;
  parameter ADD       = 3'b010;
  parameter FINISH    = 3'b100;

  // State transition logic
  always_ff @(posedge clk or posedge rst_n) 
  begin
    if (rst_n)
      begin
        state <= IDLE;
        i <= 8'd0;
      end
    else 
      begin
        case (state)
          IDLE:
            begin
              i <= 8'd0;
              if (start)
                state <= ADD;
              else
                state <= IDLE;
            end
          ADD:
            begin
              i <= i + 8'd1;
              state <= (i == 8'd255 ? FINISH : ADD);
            end
          FINISH:
          begin 
            i <= 8'd0;
          end
          default:state <= IDLE;
        endcase
      end
  end

endmodule
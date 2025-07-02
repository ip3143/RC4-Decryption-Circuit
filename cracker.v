module cracker
(
input logic clk,
input logic reset,
input logic start,
input logic [7:0] ram_data,
output logic [4:0] ram_addr,
output logic [23:0] key,
output logic found,
output logic not_found,
output logic initialize
);
//State encoding
parameter   INIT       =4'b0001,
            WAIT1      =4'b0010,
            WAIT2      =4'b0011,
            WAIT3      =4'b0100,
            READ_CHAR  =4'b0101,
            CHECK_CHAR =4'b0110,
            INC_ADDR   =4'b0111,
            INC_KEY    =4'b1000,
            REINIT     =4'b1001,
            DONE       =4'b1011;

logic [3:0] state;

assign initialize = (state == REINIT);

//Temp buffer to read the data
logic [7:0] temp_store;

always_ff @(posedge clk or posedge reset) 
begin
    if (reset) //reset all values for a reset
    begin
        state <= INIT;
        ram_addr <= 5'd0;
        key <= 24'd0;
        found <= 1'b0;
        not_found <= 1'b0;
    end 
    else if (start) //once the decode is done, start doing stuff
    begin
        case (state)
            INIT: 
            begin
                ram_addr <= 5'd0;
                found <= 1'b0;
                not_found <= 1'b0;
                state <= WAIT1;
            end
            WAIT1: //3 wait states to make sure everything is good in the ram
            begin
                state <= WAIT2;
            end
            WAIT2: 
            begin
                state <= WAIT3;
            end
            WAIT3: 
            begin
                state <= READ_CHAR;
            end
            READ_CHAR: //Get the data from ram and check it
            begin
                temp_store <= ram_data;
                state <= CHECK_CHAR;
            end
            CHECK_CHAR: 
            begin//If the first char meets the test, then we move onto the next one
                if ((temp_store >= 8'd97 && temp_store <= 8'd122) || temp_store == 8'd32) state <= INC_ADDR;
                else state <= INC_KEY;
            end
            INC_ADDR: //Change the address to check the next char and break if all 32 bits are good
            begin
                ram_addr <= ram_addr + 5'd1;
                if (ram_addr == 5'd31)
                begin
                    state <= DONE;
                    found <= 1'b1;//let the LED know
                end
                else state <= WAIT1;//Go back and wait again
            end
            INC_KEY: 
            begin
                key <= key + 24'd1;//We failed the char test so go increment key and reset ram address
                ram_addr <= 5'd0;
                if (key < 24'h3FFFFF) state <= REINIT;
                else //If we dont get the right val with all possible keys, not found and set LED[9]
                begin
                    state <= DONE;
                    not_found <= 1'b1;
                end
            end
            REINIT: 
            begin
                state <= INIT;
            end
            DONE: 
            begin
                state <= DONE; // Stay in this state unless reset
            end
            default: state <= INIT;
        endcase
    end
end

endmodule
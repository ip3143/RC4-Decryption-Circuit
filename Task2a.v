module s_memory_shuffle
(
    input  logic        clk,
    input  logic        start,
    input  logic [23:0] secret_key,
    input  logic [7:0]  q,
    output logic [7:0]  addr,
    output logic [7:0]  data,
    output logic        wren,
    output logic        done
);

// State encoding
parameter IDLE       =12'b0000_0000_0001;
parameter START_STATE=12'b0000_0000_0010;
parameter KEY_SELECT =12'b0000_0000_0100;
parameter SI_READ    =12'b0000_0000_1000;
parameter SI_WAIT    =12'b0000_0001_0000;
parameter GET_J      =12'b0000_0010_0000;
parameter READ_SJ    =12'b0000_0100_0000;
parameter WAIT_SJ    =12'b0000_1000_0000;
parameter WRITE_SI   =12'b0001_0000_0000;
parameter WRITE_SJ   =12'b0010_0000_0000;
parameter INCREMENT  =12'b0100_0000_0000;
parameter FINISH     =12'b1000_0000_0000;
logic [11:0] state;

//Internal signals for i and j
logic [7:0] i, j, si, sj;
logic [7:0] key_byte;
logic [7:0] j_next;

//Assigning address and data based on the state
assign addr = (state == SI_READ || state == SI_WAIT || state == WRITE_SJ) ? i :
                (state == READ_SJ || state == WAIT_SJ || state == WRITE_SI) ? j : 8'd0;
assign data = (state == WRITE_SI) ? si :
                (state == WRITE_SJ) ? sj : 8'd0;

//Assigning wren and data based on state
assign wren = (state == WRITE_SI || state == WRITE_SJ);
assign done = (state == FINISH);

// Main FSM
always_ff @(posedge clk) 
begin
    if (!start) //Resetting parameters if start not asserted
    begin
        state <= IDLE;
        i <= 0;
        j <= 0;
        si <= 0;
        sj <= 0;
    end 
    else 
    begin
        case (state)
            IDLE: 
            begin
                state <= START_STATE;
            end
            START_STATE: 
            begin
                i <= 8'd0;
                j <= 8'd0;
                state <= KEY_SELECT;
            end
            KEY_SELECT: //implementing the index of the secret key
            begin
                key_byte <= (i % 3 == 0) ? secret_key[23:16] : (i % 3 == 1) ? secret_key[15:8] : secret_key[7:0];
                state <= SI_READ;
            end
            SI_READ: 
            begin
                state <= SI_WAIT;
            end
            SI_WAIT: 
            begin
                si <= q;
                state <= GET_J;
            end
            GET_J: 
            begin//Implementing the new value of j
                j_next = j + si + key_byte;
                j <= j_next;
                state <= READ_SJ;
            end
            READ_SJ: 
            begin
                state <= WAIT_SJ;
            end
            WAIT_SJ: 
            begin
                sj <= q;        //Getting new value of sj
                state <= WRITE_SI;
            end
            WRITE_SI:
            begin
                state <= WRITE_SJ;
            end
            WRITE_SJ: 
            begin
                state <= INCREMENT;
            end
            INCREMENT:
            begin
                if (i == 8'd255)  //The for component of the loop
                begin
                    state <= FINISH;
                end 
                else 
                begin //Go back around
                    i <= i + 1'b1;
                    state <= KEY_SELECT;
                end
            end
            FINISH: 
            begin
                state <= FINISH;
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule
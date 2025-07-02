module decrypter
(
input  logic        clk,
input  logic        start,
output logic        done,
//SRAM
input  logic [7:0]  q_s,
output logic [7:0]  char_s,
output logic [7:0]  addr_s,
output logic        wren_s,
//ROM
input  logic [7:0]  q_rom,
output logic [4:0]  addr_rom,
//RAM
output logic [4:0]  addr_ram,
output logic [7:0]  char_ram,
output logic        wren_ram
);


//state encoding for the FSM
logic [4:0] state;
parameter IDLE               = 5'b00000,
          LOAD_I             = 5'b00001,
          SET_I_ADDRESS      = 5'b00010,
          WAIT_I             = 5'b00011,
          READ_I             = 5'b00100,
          COMPUTE_J          = 5'b00101,
          SET_J_ADDRESS      = 5'b00110,
          WAIT_J             = 5'b00111,
          READ_J             = 5'b01000,
          SWAP_WRITE_J       = 5'b01001,
          ENABLE_WRITE_J     = 5'b01010,
          DISABLE_WRITE_J    = 5'b01011,
          SWAP_WRITE_I       = 5'b01100,
          ENABLE_WRITE_I     = 5'b01101,
          DISABLE_WRITE_I    = 5'b01110,
          COMPUTE_F_ADDRESS  = 5'b01111,
          SET_F_ADDRESS      = 5'b10000,
          WAIT_F             = 5'b10001,
          READ_F             = 5'b10010,
          SET_ROM_ADDRESS    = 5'b10011,
          WAIT_ROM           = 5'b10100,
          READ_ROM           = 5'b10101,
          SET_RAM_ADDRESS    = 5'b10110,
          WAIT_RAM           = 5'b10111,
          ENABLE_WRITE_RAM   = 5'b11000,
          DISABLE_WRITE_RAM  = 5'b11001,
          UPDATE_K           = 5'b11010,
          DONE               = 5'b11011;

assign done = (state == DONE);
assign wren_s = (state == ENABLE_WRITE_I || state == ENABLE_WRITE_J);
assign wren_ram = (state == ENABLE_WRITE_RAM);

//Our internal signals and counters
logic [7:0] i, j, si, sj, f, temp_data;
logic [4:0] k;
logic [8:0] f_address; //9 bits to account for overflow

always_ff @(posedge clk) 
begin
    if (!start) 
    begin//If start not asserted, keep everything at 0
        state <= IDLE;
        i <= 8'b0;
        j <= 8'b0;
        si <= 8'b0;
        sj <= 8'b0;
        k <= 5'b0;
        f <= 8'b0;
        addr_s <= 8'b0;
        addr_rom <= 5'b0;
        addr_ram <= 5'b0;
    end 
    else //Do the FSM implementation now
    begin
        case (state)
            IDLE: 
            begin
                i <= 8'b0;
                j <= 8'b0;
                k <= 5'b0;
                state <= LOAD_I;
            end
            LOAD_I: 
            begin//Increment i
                i <= i + 8'b1;
                state <= SET_I_ADDRESS;
            end
            SET_I_ADDRESS: 
            begin//start reading new si value
                addr_s <= i;
                state <= WAIT_I;
            end
            WAIT_I:
            begin
                state <= READ_I;
            end
            READ_I: 
            begin //finish reading new si value
                si <= q_s;
                state <= COMPUTE_J;
            end
            COMPUTE_J: //Compute new J value
            begin
                j <= j + si;
                state <= SET_J_ADDRESS;
            end
            SET_J_ADDRESS: //start reading sj
            begin
                addr_s <= j;
                state <= WAIT_J;
            end
            WAIT_J:
            begin
                state <= READ_J;
            end
            READ_J: //finish reading sj
            begin
                sj <= q_s;
                state <= SWAP_WRITE_J;
            end
            SWAP_WRITE_J: //switch the values and prepare to write into mem
            begin
                addr_s <= j;
                char_s <= si;
                state <= ENABLE_WRITE_J;
            end
            ENABLE_WRITE_J: 
            begin
                state <= DISABLE_WRITE_J;
            end
            DISABLE_WRITE_J: 
            begin
                state <= SWAP_WRITE_I;
            end
            SWAP_WRITE_I: //same thing now for I
            begin
                addr_s <= i;
                char_s <= sj;
                state <= ENABLE_WRITE_I;
            end
            ENABLE_WRITE_I: 
            begin
                state <= DISABLE_WRITE_I;
            end
            DISABLE_WRITE_I: 
            begin
                state <= COMPUTE_F_ADDRESS;
            end
            COMPUTE_F_ADDRESS: //calculate new f address
            begin
                f_address <= si + sj;
                state <= SET_F_ADDRESS;
            end
            SET_F_ADDRESS: //read from mem begin
            begin
                addr_s <= f_address;
                state <= WAIT_F;
            end
            WAIT_F: 
            begin
                state <= READ_F;
            end
            READ_F: //finish reading from mem
            begin
                f <= q_s;
                state <= SET_ROM_ADDRESS;
            end
            SET_ROM_ADDRESS: //now put the k address and get ready to read encrypted
            begin
                addr_rom <= k;
                state <= WAIT_ROM;
            end
            WAIT_ROM: 
            begin
                state <= READ_ROM;
            end
            READ_ROM: //read encrypted and calculate decrypt
            begin
                temp_data <= f ^ q_rom;
                state <=  SET_RAM_ADDRESS;
            end
            SET_RAM_ADDRESS: //prepare to put decrypt into RAM
            begin
                addr_ram <= k;
                char_ram <= temp_data;
                state <= WAIT_RAM;
            end
            WAIT_RAM: 
            begin
                state <= ENABLE_WRITE_RAM;   
            end
            ENABLE_WRITE_RAM: //write into RAM
            begin
                state <= DISABLE_WRITE_RAM;
            end
            DISABLE_WRITE_RAM: 
            begin
                state <= UPDATE_K;
            end
            UPDATE_K: //update new k values
            begin
                k <= k + 5'd1;
                if (k == 5'd31)
                begin
                    state <= DONE;
                end
                else 
                begin
                    state <= LOAD_I;
                end
            end
            DONE: state <= IDLE;
            default: state <= IDLE;
        endcase
    end
end
endmodule

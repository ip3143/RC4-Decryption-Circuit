module ksa
(
input  logic         CLOCK_50,         // Clock pin
input  logic [3:0]   KEY,              // Push button switches
input  logic [9:0]   SW,               // Slider switches
output logic [9:0]   LEDR,             // Red LEDs
output logic [6:0]   HEX0,
output logic [6:0]   HEX1,
output logic [6:0]   HEX2,
output logic [6:0]   HEX3,
output logic [6:0]   HEX4,
output logic [6:0]   HEX5
);

//Clock and Reset
logic clk, rst_n;
assign clk = CLOCK_50;
assign rst_n = ~KEY[3];

//Address
logic [7:0] addr_main;
logic [7:0] addr_init;
logic [7:0] addr_shfl;
logic [7:0] addr_deco;

//Data
logic [7:0] data_main;
logic [7:0] data_init;
logic [7:0] data_shfl;
logic [7:0] data_deco;

//Wren
logic wren_main;
logic wren_init;
logic wren_shfl;
logic wren_deco;

//Done
logic done_init;
logic done_shfl;
logic done_deco;

//q signal
logic [7:0] q;

//Key logic and module
logic [23:0] secret_key;
key_select key_selection //Basic key select module, not used for task 3
(
.switches(SW),
.output_key(secret_key)
);



//When writing to memory, use the done flags to decide which addr/data/wren is sent to the chip
assign addr_main = done_init ? (done_shfl ? addr_deco : addr_shfl) : addr_init;
assign data_main = done_init ? (done_shfl ? data_deco : data_shfl) : data_init;
assign wren_main = done_init ? (done_shfl ? wren_deco : wren_shfl) : wren_init;

s_memory s_mem_inst //Controlling on chip memory
(
.address(addr_main),
.clock(clk),
.data(data_main),
.wren(wren_main),
.q(q)
);

for_loop memory_init //Initializing module
(
.start(1'b1), //Set to 1 as the solution
.clk(clk),
.rst_n(rst_n|initialize), //Task 3 flag will reset the for_loop
.data(data_init),
.addr(addr_init),
.wren(wren_init),
.done(done_init)    
);

s_memory_shuffle shuffle_controller //Shuffling module
(
.clk          (clk),
.start        (done_init), 
.q            (q),
.secret_key   (attempted_key),
.data         (data_shfl),
.addr         (addr_shfl),
.wren         (wren_shfl),
.done         (done_shfl)
);

//ROM and associated signals
logic [4:0] encrypt_address;
logic [7:0] encrypt_data;
encrypt_ROM encrypted_message
(
.address(encrypt_address),
.clock(clk),
.q(encrypt_data)
);

//RAM output and associated signals
logic [4:0] decrypt_address;
logic [4:0] ram_store_address;
assign ram_store_address = done_deco ? crack_address : decrypt_address;
logic [7:0] decrypt_data;//Muxing the RAM address for reading and writing depending on task
logic wren_ram;
logic [7:0] decrypt_out;
decrypt_RAM decrypted_message
(
.address(ram_store_address),
.clock(clk),
.data(decrypt_data),
.wren(wren_ram),
.q(decrypt_out)
);

decrypter decrypt_controller //Decoding module
(
.clk(clk),
.start(done_shfl), 
.done(done_deco),
.q_s(q),
.char_s(data_deco),
.addr_s(addr_deco),
.wren_s(wren_deco),
.q_rom(encrypt_data),
.addr_rom(encrypt_address),
.addr_ram(decrypt_address),
.char_ram(decrypt_data),
.wren_ram(wren_ram)
);

//TASK 3 STUFF BELOW
//Internal signals
logic [23:0] attempted_key;
logic initialize;
logic [4:0] crack_address;
logic found;
//Hex logic
SevenSegmentDisplayDecoder HEX0DISPLAY(.ssOut(HEX0),.nIn(attempted_key[3:0]));
SevenSegmentDisplayDecoder HEX1DISPLAY(.ssOut(HEX1),.nIn(attempted_key[7:4]));
SevenSegmentDisplayDecoder HEX2DISPLAY(.ssOut(HEX2),.nIn(attempted_key[11:8]));
SevenSegmentDisplayDecoder HEX3DISPLAY(.ssOut(HEX3),.nIn(attempted_key[15:12]));
SevenSegmentDisplayDecoder HEX4DISPLAY(.ssOut(HEX4),.nIn(attempted_key[19:16]));
SevenSegmentDisplayDecoder HEX5DISPLAY(.ssOut(HEX5),.nIn(attempted_key[23:20]));
 
cracker crack_1 //cracking core
(
.clk(clk),
.reset(rst_n),
.start(done_deco), 
.key(attempted_key),
.found(found), //LEDs for found and not_found flags
.not_found(LEDR[9]),
.ram_data(decrypt_out),
.ram_addr(crack_address),
.initialize(initialize)
);

assign LEDR[1] = found;
assign LEDR[0] = found;
endmodule
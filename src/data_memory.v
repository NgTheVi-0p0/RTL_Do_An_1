module data_memory (
    input wire clk,
    input wire mem_write,       
    input wire [31:0] addr,     
    input wire [31:0] write_data, 
    input wire [2:0] load_sel,  
    input wire [2:0] store_sel, 
    output reg [31:0] read_data, 
    input wire [9:0] debug_addr,
    output wire [31:0] debug_val
);
    // 128 dòng x 32-bit
    reg [31:0] ram [0:127]; 

    // --- LOGIC GHI (STORE) ---
    always @(posedge clk) begin
        if (mem_write) begin
            case (store_sel)
                3'b000: begin // SB
                    case (addr[1:0])
                        2'b00: ram[addr[8:2]][7:0]   <= write_data[7:0];
                        2'b01: ram[addr[8:2]][15:8]  <= write_data[7:0];
                        2'b10: ram[addr[8:2]][23:16] <= write_data[7:0];
                        2'b11: ram[addr[8:2]][31:24] <= write_data[7:0];
                    endcase
                end
                3'b001: begin // SH
                    if (addr[1] == 1'b0)
                        ram[addr[8:2]][15:0]  <= write_data[15:0];
                    else
                        ram[addr[8:2]][31:16] <= write_data[15:0];
                end
                3'b010: begin // SW
                    ram[addr[8:2]] <= write_data;
                end
            endcase
        end
    end

    // --- LOGIC ĐỌC (LOAD) ---
    // Sử dụng addr[8:2] thống nhất
    wire [31:0] raw_word = ram[addr[8:2]]; 
    reg [7:0]  byte_to_load;
    reg [15:0] half_to_load;

    always @(*) begin
        case (addr[1:0])
            2'b00: byte_to_load = raw_word[7:0];
            2'b01: byte_to_load = raw_word[15:8];
            2'b10: byte_to_load = raw_word[23:16];
            2'b11: byte_to_load = raw_word[31:24];
        endcase

        half_to_load = (addr[1] == 1'b0) ? raw_word[15:0] : raw_word[31:16];

        case (load_sel)
            3'b000: read_data = {{24{byte_to_load[7]}}, byte_to_load};
            3'b001: read_data = {{16{half_to_load[15]}}, half_to_load};
            3'b010: read_data = raw_word;
            3'b100: read_data = {24'b0, byte_to_load};
            3'b101: read_data = {16'b0, half_to_load};
            default: read_data = raw_word;
        endcase
    end

    // Chỉ lấy 7 bit thấp của debug_addr để trỏ vào 128 dòng
    assign debug_val = ram[debug_addr[6:0]];

endmodule
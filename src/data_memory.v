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
    reg [31:0] ram [0:127]; 

    // --- LOGIC GHI ĐỒNG BỘ ---
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
                    if (addr[1] == 1'b0) ram[addr[8:2]][15:0]  <= write_data[15:0];
                    else                 ram[addr[8:2]][31:16] <= write_data[15:0];
                end
                3'b010: begin // SW
                    ram[addr[8:2]] <= write_data;
                end
            endcase
        end
    end

    assign debug_val = ram[debug_addr[6:0]];

    // --- LOGIC ĐỌC BẤT ĐỒNG BỘ (SỬA Ở ĐÂY) ---
    wire [31:0] raw_word = ram[addr[8:2]]; // Đọc trực tiếp ra luôn
    
    wire [7:0] byte_to_load;
    wire [15:0] half_to_load;

    // Chọn byte/half-word trực tiếp từ tín hiệu ngõ vào (không cần chốt)
    assign byte_to_load = (addr[1:0] == 2'b00) ? raw_word[7:0] :
                          (addr[1:0] == 2'b01) ? raw_word[15:8] :
                          (addr[1:0] == 2'b10) ? raw_word[23:16] : raw_word[31:24];
                          
    assign half_to_load = (addr[1] == 1'b0) ? raw_word[15:0] : raw_word[31:16];

    always @(*) begin
        case (load_sel)
            3'b000: read_data = {{24{byte_to_load[7]}}, byte_to_load};  // LB
            3'b001: read_data = {{16{half_to_load[15]}}, half_to_load}; // LH
            3'b010: read_data = raw_word;                               // LW
            3'b100: read_data = {24'b0, byte_to_load};                  // LBU
            3'b101: read_data = {16'b0, half_to_load};                  // LHU
            default: read_data = raw_word;
        endcase
    end
endmodule
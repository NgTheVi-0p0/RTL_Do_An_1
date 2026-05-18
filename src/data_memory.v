module data_memory (
    input wire clk,
    input wire mem_write,       
    input wire [31:0] addr,     
    input wire [31:0] write_data, 
    input wire [2:0] load_sel,  
    input wire [2:0] store_sel, 
    output reg [31:0] read_data, 
    input wire [9:0] debug_addr,
    output reg [31:0] debug_val // Chuyển sang reg để đồng bộ
);
    // 128 dòng x 32-bit
    reg [31:0] ram [0:127]; 

    // Thanh ghi tạm để lưu kết quả thô từ RAM
    reg [31:0] raw_word;
    reg [2:0]  load_sel_reg;
    reg [1:0]  addr_byte_sel_reg;

    // --- LOGIC GHI (STORE) VÀ ĐỌC THÔ ---
    always @(posedge clk) begin
        // 1. Logic Ghi
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

        // 2. Logic Đọc thô (Phải ở trong always clk này)
        raw_word <= ram[addr[8:2]];
        
        // Chốt lại các tín hiệu điều khiển để dùng ở chu kỳ sau (Load)
        load_sel_reg <= load_sel;
        addr_byte_sel_reg <= addr[1:0];

        // 3. Logic Debug đồng bộ
        debug_val <= ram[debug_addr[6:0]];
    end

    // --- LOGIC XỬ LÝ LOAD (Tổ hợp sau khi đã có raw_word) ---
    reg [7:0]  byte_to_load;
    reg [15:0] half_to_load;

    always @(*) begin
        // Chọn byte dựa trên địa chỉ đã chốt
        case (addr_byte_sel_reg)
            2'b00: byte_to_load = raw_word[7:0];
            2'b01: byte_to_load = raw_word[15:8];
            2'b10: byte_to_load = raw_word[23:16];
            2'b11: byte_to_load = raw_word[31:24];
        endcase

        half_to_load = (addr_byte_sel_reg[1] == 1'b0) ? raw_word[15:0] : raw_word[31:16];

        case (load_sel_reg)
            3'b000: read_data = {{24{byte_to_load[7]}}, byte_to_load}; // LB
            3'b001: read_data = {{16{half_to_load[15]}}, half_to_load}; // LH
            3'b010: read_data = raw_word;                               // LW
            3'b100: read_data = {24'b0, byte_to_load};                  // LBU
            3'b101: read_data = {16'b0, half_to_load};                  // LHU
            default: read_data = raw_word;
        endcase
    end

endmodule
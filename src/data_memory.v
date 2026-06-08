module data_memory (
    input wire clk,
    input wire mem_write,       
    input wire [31:0] addr,     
    input wire [31:0] write_data, 
    input wire [2:0] load_sel,  
    input wire [2:0] store_sel, 
    output reg [31:0] read_data, 
    input wire [9:0] debug_addr, // Giả sử debug_addr cũng là địa chỉ byte từ hệ thống
    output reg [31:0] debug_val 
);
    // 128 dòng x 32-bit (Word-aligned memory)
    reg [31:0] ram [0:127]; 

    // Thanh ghi tạm để lưu kết quả từ RAM và chốt tín hiệu điều khiển sang chu kỳ sau (Memory Stage)
    reg [31:0] raw_word;
    reg [2:0]  load_sel_reg;
    reg [1:0]  addr_byte_sel_reg;

    // Các biến phụ trợ phục vụ việc tính toán dữ liệu ghi đè kết hợp ghi từng byte (Byte-enables)
    wire [6:0] ram_index = addr[8:2];
    reg [31:0] updated_word;

    // --- LOGIC TỔ HỢP TÍNH TOÁN DỮ LIỆU SẼ GHI (Dùng để giải quyết lỗi đọc-ghi đồng thời) ---
    always @(*) begin
        // Mặc định lấy dữ liệu cũ trong RAM ra
        updated_word = ram[ram_index];
        
        if (mem_write) begin
            case (store_sel)
                3'b000: begin // SB (Store Byte)
                    case (addr[1:0])
                        2'b00: updated_word[7:0]   = write_data[7:0];
                        2'b01: updated_word[15:8]  = write_data[7:0];
                        2'b10: updated_word[23:16] = write_data[7:0];
                        2'b11: updated_word[31:24] = write_data[7:0];
                    endcase
                end
                3'b001: begin // SH (Store Halfword)
                    if (addr[1] == 1'b0)
                        updated_word[15:0]  = write_data[15:0];
                    else
                        updated_word[31:16] = write_data[15:0];
                end
                3'b010: begin // SW (Store Word)
                    updated_word = write_data;
                end
                default: updated_word = write_data;
            endcase
        end
    end

    // --- LOGIC GHI VÀ ĐỌC ĐỒNG BỘ (Bản chất phần cứng RAM khối) ---
    always @(posedge clk) begin
        // 1. Thực hiện ghi vào RAM dữ liệu đã được tính toán ở khối tổ hợp trên
        if (mem_write) begin
            ram[ram_index] <= updated_word;
        end

        // 2. Logic Đọc thô có tích hợp BYPASS 
        // Nếu chu kỳ này đang ghi, chu kỳ sau khối LOAD sẽ nhận ngay dữ liệu MỚI (updated_word)
        // Nếu chu kỳ này không ghi, RAM xuất dữ liệu lưu trữ bình thường
        raw_word <= updated_word;
        
        // Chốt lại các tín hiệu điều khiển để phục vụ tầng chỉnh sửa dữ liệu đọc (Aligner)
        load_sel_reg      <= load_sel;
        addr_byte_sel_reg <= addr[1:0];

        // 3. Logic Debug đồng bộ (Chuẩn hóa định dạng Word-aligned tương tự trục addr[8:2])
        debug_val <= ram[debug_addr[8:2]];
    end

    // --- LOGIC XỬ LÝ LOAD (Tổ hợp sau khi đã có dữ liệu thô raw_word ở chu kỳ sau) ---
    reg [7:0]  byte_to_load;
    reg [15:0] half_to_load;

    always @(*) begin
        // Trích xuất byte chính xác dựa trên cấu trúc căn lề địa chỉ chốt
        case (addr_byte_sel_reg)
            2'b00: byte_to_load = raw_word[7:0];
            2'b01: byte_to_load = raw_word[15:8];
            2'b10: byte_to_load = raw_word[23:16];
            2'b11: byte_to_load = raw_word[31:24];
        endcase

        // Trích xuất half-word chính xác
        half_to_load = (addr_byte_sel_reg[1] == 1'b0) ? raw_word[15:0] : raw_word[31:16];

        // Mở rộng dấu (Sign-extension) hoặc chèn zero (Zero-extension) tùy thuộc vào mã lệnh Load
        case (load_sel_reg)
            3'b000:  read_data = {{24{byte_to_load[7]}}, byte_to_load};  // LB
            3'b001:  read_data = {{16{half_to_load[15]}}, half_to_load}; // LH
            3'b010:  read_data = raw_word;                               // LW
            3'b100:  read_data = {24'b0, byte_to_load};                  // LBU
            3'b101:  read_data = {16'b0, half_to_load};                  // LHU
            default: read_data = raw_word;
        endcase
    end

endmodule
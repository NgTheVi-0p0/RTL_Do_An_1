module Register_File (
    input wire clk,
    input wire rst_n,        // Tín hiệu reset hệ thống (tích cực mức thấp)
    input wire reg_write,    // Tín hiệu cho phép ghi từ tầng WB
    input wire [4:0] rs1,    // Địa chỉ nguồn 1 (từ tầng ID)
    input wire [4:0] rs2,    // Địa chỉ nguồn 2 (từ tầng ID)
    input wire [4:0] rd,     // Địa chỉ đích (từ tầng WB)
    input wire [31:0] wd,    // Dữ liệu ghi (từ tầng WB)
    output wire [31:0] rd1,  // Dữ liệu đọc ra 1
    output wire [31:0] rd2,  // Dữ liệu đọc ra 2
    input wire [4:0] debug_addr,
    output wire [31:0] debug_val
);
    reg [31:0] rf [31:0];
    integer i;

    // --- 1. LOGIC GHI DỮ LIỆU VÀ RESET (ĐỒNG BỘ THEO CẠNH CLOCK) ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Khi reset, đưa tất cả 32 thanh ghi về giá trị 0
            for (i = 0; i < 32; i = i + 1) begin
                rf[i] <= 32'b0;
            end
        end 
        else if (reg_write && (rd != 5'b00000)) begin
            // Chỉ ghi khi có tín hiệu cho phép và không phải ghi vào thanh ghi x0
            rf[rd] <= wd;
        end
    end

    // --- 2. LOGIC ĐỌC DỮ LIỆU KHÔNG ĐỒNG BỘ (ASYNCHRONOUS READ) ---
    // Tích hợp mạch Internal Forwarding (Bypass luồng dữ liệu ghi thẳng sang ngõ ra đọc)
    // Quy ước RISC-V: Thanh ghi x0 luôn luôn cố định bằng 0 trong mọi tình huống.

    // Ngõ ra đọc thanh ghi rs1
    assign rd1 = (rs1 == 5'b0) ? 32'b0 :
                 ((reg_write && (rd == rs1)) ? wd : rf[rs1]);

    // Ngõ ra đọc thanh ghi rs2
    assign rd2 = (rs2 == 5'b0) ? 32'b0 :
                 ((reg_write && (rd == rs2)) ? wd : rf[rs2]);

    // Ngõ ra Debug (Đã sửa: Thêm Internal Forwarding để đồng bộ dạng sóng khi debug)
    assign debug_val = (debug_addr == 5'b0) ? 32'b0 :
                       ((reg_write && (rd == debug_addr)) ? wd : rf[debug_addr]);

endmodule
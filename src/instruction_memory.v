module instruction_memory (
    input wire clk,
    input wire we,            // Tín hiệu cho phép nạp lệnh từ bên ngoài (khi start=0)
    input wire [31:0] addr_ext, // Địa chỉ nạp lệnh từ bên ngoài
    input wire [31:0] din_ext,  // Dữ liệu lệnh nạp từ bên ngoài
    input wire [31:0] pc,       // Địa chỉ từ Program Counter của CPU
    output wire [31:0] instr    // Lệnh xuất ra cho CPU thực thi
);
    // Khởi tạo bộ nhớ 1024 dòng (4KB), mỗi dòng 32-bit
    reg [31:0] mem [0:1023];

    // Ghi lệnh vào bộ nhớ (quá trình nạp chương trình)
    always @(posedge clk) begin
        if (we)
            mem[addr_ext[11:2]] <= din_ext;
    end

    // Đọc lệnh dựa trên PC (Đọc không đồng bộ để tầng Fetch lấy lệnh ngay)
    // addr[11:2] vì địa chỉ RISC-V nhảy mỗi lần 4 đơn vị (byte-aligned)
    assign instr = mem[pc[11:2]];

endmodule
module instruction_memory (
    input wire clk,
    input wire we,              
    input wire [31:0] addr_ext, 
    input wire [31:0] din_ext,  
    input wire [31:0] pc,       
    output wire [31:0] instr    
);
    // 128 dòng x 32-bit = 512 Bytes
    reg [31:0] mem [0:127];

    // Ghi đồng bộ (Nạp chương trình)
    always @(posedge clk) begin
        if (we) begin
            mem[addr_ext[8:2]] <= din_ext; // Dùng bit 8 tới 2 (7 bits = 128 ô)
        end
    end

    // Đọc không đồng bộ (Fetch lệnh)
    // QUAN TRỌNG: Phải sửa pc[11:2] thành pc[8:2] để khớp với mảng 128
    assign instr = mem[pc[8:2]]; 

endmodule
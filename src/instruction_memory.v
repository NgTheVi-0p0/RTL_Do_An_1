module instruction_memory (
    input wire clk,
    input wire we,              
    input wire [31:0] addr_ext, 
    input wire [31:0] din_ext,  
    input wire [31:0] pc,       
    output reg [31:0] instr     // Đổi sang reg để đọc đồng bộ chuẩn RAM
);
    // 128 dòng x 32-bit = 512 Bytes
    reg [31:0] mem [0:127];

    // Ghi đồng bộ (Nạp chương trình ngoại vi)
    always @(posedge clk) begin
        if (we) begin
            mem[addr_ext[8:2]] <= din_ext; 
        end
    end

    // Đọc đồng bộ (Đúng kiến trúc Memory Block trên FPGA để tối ưu Area/Timing)
    always @(posedge clk) begin
        instr <= mem[pc[8:2]];
    end

endmodule
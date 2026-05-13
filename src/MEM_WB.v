// MEM_WB Pipeline Register (Memory to Write Back)
// Lưu trữ dữ liệu giữa giai đoạn MEM và WB trong pipeline 5 tầng

module MEM_WB (
    input  wire        clk,
    input  wire        rst_n,
    
    // Đầu vào từ MEM stage
    input  wire [31:0] mem_pc_plus4,
    input  wire [31:0] mem_alu_result,
    input  wire [31:0] mem_mem_data,
    input  wire [4:0]  mem_rd,
    input  wire        mem_regWrite,
    input  wire [1:0]  mem_write_back,
    
    // Đầu ra tới WB stage
    output reg[31:0] wb_pc_plus4,
    output reg  [31:0] wb_alu_result,
    output reg  [31:0] wb_mem_data,
    output reg  [4:0]  wb_rd,
    output reg         wb_regWrite,
    output reg  [1:0]  wb_write_back
);

    // Sử dụng 1 block tuần tự duy nhất
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset không đồng bộ (Asynchronous Reset)
            wb_pc_plus4   <= 32'h0000_0004;
            wb_alu_result <= 32'h0000_0000;
            wb_mem_data   <= 32'h0000_0000;
            wb_rd         <= 5'b00000;
            wb_regWrite   <= 1'b0;
            wb_write_back <= 2'b00;
        end 
        else begin
            // Truyền trực tiếp dữ liệu từ MEM sang WB
            wb_pc_plus4   <= mem_pc_plus4;
            wb_alu_result <= mem_alu_result;
            wb_mem_data   <= mem_mem_data;
            wb_rd         <= mem_rd;
            wb_regWrite   <= mem_regWrite;
            wb_write_back <= mem_write_back;
        end
    end

endmodule
// MEM_WB Pipeline Register (Memory to Write Back)
// Lưu trữ dữ liệu giữa giai đoạn MEM và WB trong pipeline 5 tầng

module MEM_WB (
    input  wire        clk,
    input  wire        rst_n,
    
    // Đầu vào từ MEM stage
    input  wire[31:0] mem_pc_plus4,
    input  wire [31:0] mem_alu_result,
    input  wire [31:0] mem_mem_data,
    input  wire [4:0]  mem_rd,
    input  wire        mem_regWrite,
    input  wire [1:0]  mem_write_back,
    
    // Đầu ra tới WB stage
    output reg  [31:0] wb_pc_plus4,
    output reg  [31:0] wb_alu_result,
    output reg  [31:0] wb_mem_data,
    output reg  [4:0]  wb_rd,
    output reg         wb_regWrite,
    output reg  [1:0]  wb_write_back
);

    // --- 1. Logic tổ hợp: Chọn giá trị tiếp theo ---
    reg[31:0] next_wb_pc_plus4, next_wb_alu_result, next_wb_mem_data;
    reg [4:0]  next_wb_rd;
    reg        next_wb_regWrite;
    reg [1:0]  next_wb_write_back;

    always @(*) begin
        // Stage cuối không có stall hay flush, chỉ truyền dữ liệu qua
        next_wb_pc_plus4   = mem_pc_plus4;
        next_wb_alu_result = mem_alu_result;
        next_wb_mem_data   = mem_mem_data;
        next_wb_rd         = mem_rd;
        next_wb_regWrite   = mem_regWrite;
        next_wb_write_back = mem_write_back;
    end

    // --- 2. Logic tuần tự: Ghi vào thanh ghi ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_pc_plus4   <= 32'h0000_0004;
            wb_alu_result <= 32'h0000_0000;
            wb_mem_data   <= 32'h0000_0000;
            wb_rd         <= 5'b00000;
            wb_regWrite   <= 1'b0;
            wb_write_back <= 2'b00;
        end 
        else begin
            wb_pc_plus4   <= next_wb_pc_plus4;
            wb_alu_result <= next_wb_alu_result;
            wb_mem_data   <= next_wb_mem_data;
            wb_rd         <= next_wb_rd;
            wb_regWrite   <= next_wb_regWrite;
            wb_write_back <= next_wb_write_back;
        end
    end

endmodule
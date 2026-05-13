// EX_MEM Pipeline Register (Execute to Memory)
// Lưu trữ dữ liệu giữa giai đoạn EX và MEM trong pipeline 5 tầng

module EX_MEM (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,         

    // Đầu vào từ EX stage
    input  wire [31:0] ex_pc_plus4,
    input  wire [31:0] ex_alu_result, 
    input  wire [31:0] ex_rs2_data,   
    input  wire[4:0]  ex_rd,         

    // Tín hiệu điều khiển từ EX stage
    input  wire        ex_regWrite,
    input  wire [2:0]  ex_load_sel,
    input  wire [2:0]  ex_store_sel,
    input  wire        ex_memWrite,
    input  wire [1:0]  ex_write_back,

    // Đầu ra tới MEM stage
    output reg  [31:0] mem_pc_plus4,
    output reg  [31:0] mem_alu_result,
    output reg[31:0] mem_rs2_data,
    output reg  [4:0]  mem_rd,

    // Tín hiệu điều khiển cho MEM stage
    output reg         mem_regWrite,
    output reg  [2:0]  mem_load_sel,
    output reg[2:0]  mem_store_sel,
    output reg         mem_memWrite,
    output reg[1:0]  mem_write_back
);

    // Sử dụng 1 block tuần tự duy nhất để tối ưu tổng hợp và tránh lỗi LEC
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset không đồng bộ (Asynchronous Reset)
            mem_pc_plus4   <= 32'h0;
            mem_alu_result <= 32'h0;
            mem_rs2_data   <= 32'h0;
            mem_rd         <= 5'b0;
            mem_regWrite   <= 1'b0;
            mem_load_sel   <= 3'b0;
            mem_store_sel  <= 3'b0;
            mem_memWrite   <= 1'b0;
            mem_write_back <= 2'b0;
        end 
        else if (flush) begin
            // Xóa đồng bộ (Synchronous Flush) - Bubble insertion
            mem_pc_plus4   <= 32'h0;
            mem_alu_result <= 32'h0;
            mem_rs2_data   <= 32'h0;
            mem_rd         <= 5'b0;
            mem_regWrite   <= 1'b0;
            mem_load_sel   <= 3'b0;
            mem_store_sel  <= 3'b0;
            mem_memWrite   <= 1'b0;
            mem_write_back <= 2'b0;
        end 
        else begin
            // Cập nhật giá trị mới từ EX sang MEM
            mem_pc_plus4   <= ex_pc_plus4;
            mem_alu_result <= ex_alu_result;
            mem_rs2_data   <= ex_rs2_data;
            mem_rd         <= ex_rd;
            mem_regWrite   <= ex_regWrite;
            mem_load_sel   <= ex_load_sel;
            mem_store_sel  <= ex_store_sel;
            mem_memWrite   <= ex_memWrite;
            mem_write_back <= ex_write_back;
        end
    end

endmodule
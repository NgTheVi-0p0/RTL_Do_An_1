module ID_EX (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,
    
    // Đầu vào từ ID stage
    input  wire [31:0] id_pc,
    input  wire[31:0] id_pc_plus4,
    input  wire [31:0] id_rs1_data,
    input  wire [31:0] id_rs2_data,
    input  wire [31:0] id_imm,
    input  wire [4:0]  id_rd,
    input  wire [4:0]  id_rs1,
    input  wire [4:0]  id_rs2,
    
    // Tín hiệu điều khiển vào
    input  wire        id_regWrite,
    input  wire [2:0]  id_imm_sel,
    input  wire        id_alu_srcA,
    input  wire        id_alu_srcB,
    input  wire [10:0] id_alu_ctrl,
    input  wire        id_branch,
    input  wire [2:0]  id_bropcode,
    input  wire [1:0]  id_jump,
    input  wire[2:0]  id_load_sel,
    input  wire [2:0]  id_store_sel,
    input  wire        id_memWrite,
    input  wire [1:0]  id_write_back,
    
    // Đầu ra tới EX stage
    output reg[31:0] ex_pc,
    output reg  [31:0] ex_pc_plus4,
    output reg  [31:0] ex_rs1_data,
    output reg[31:0] ex_rs2_data,
    output reg  [31:0] ex_imm,
    output reg  [4:0]  ex_rd,
    output reg[4:0]  ex_rs1,
    output reg  [4:0]  ex_rs2,
    
    // Tín hiệu điều khiển ra
    output reg         ex_regWrite,
    output reg  [2:0]  ex_imm_sel,
    output reg         ex_alu_srcA,
    output reg         ex_alu_srcB,
    output reg[10:0] ex_alu_ctrl,
    output reg         ex_branch,
    output reg[2:0]  ex_bropcode,
    output reg  [1:0]  ex_jump,
    output reg  [2:0]  ex_load_sel,
    output reg  [2:0]  ex_store_sel,
    output reg         ex_memWrite,
    output reg  [1:0]  ex_write_back
);

    // Sử dụng 1 block tuần tự duy nhất để dễ tổng hợp và Verify
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset không đồng bộ (Asynchronous Reset)
            ex_pc         <= 32'h0;
            ex_pc_plus4   <= 32'h4;
            ex_rs1_data   <= 32'h0;
            ex_rs2_data   <= 32'h0;
            ex_imm        <= 32'h0;
            ex_rd         <= 5'b0;
            ex_rs1        <= 5'b0;
            ex_rs2        <= 5'b0;
            ex_regWrite   <= 1'b0;
            ex_imm_sel    <= 3'b0;
            ex_alu_srcA   <= 1'b0;
            ex_alu_srcB   <= 1'b0;
            ex_alu_ctrl   <= 11'b0;
            ex_branch     <= 1'b0;
            ex_bropcode   <= 3'b0;
            ex_jump       <= 2'b0;
            ex_load_sel   <= 3'b0;
            ex_store_sel  <= 3'b0;
            ex_memWrite   <= 1'b0;
            ex_write_back <= 2'b0;
        end 
        else if (flush) begin
            // Xóa đồng bộ (Synchronous Flush)
            ex_pc         <= 32'h0;
            ex_pc_plus4   <= 32'h4;
            ex_rs1_data   <= 32'h0;
            ex_rs2_data   <= 32'h0;
            ex_imm        <= 32'h0;
            ex_rd         <= 5'b0;
            ex_rs1        <= 5'b0;
            ex_rs2        <= 5'b0;
            ex_regWrite   <= 1'b0;
            ex_imm_sel    <= 3'b0;
            ex_alu_srcA   <= 1'b0;
            ex_alu_srcB   <= 1'b0;
            ex_alu_ctrl   <= 11'b0;
            ex_branch     <= 1'b0;
            ex_bropcode   <= 3'b0;
            ex_jump       <= 2'b0;
            ex_load_sel   <= 3'b0;
            ex_store_sel  <= 3'b0;
            ex_memWrite   <= 1'b0;
            ex_write_back <= 2'b0;
        end 
        else if (!stall) begin
            // Chỉ cập nhật giá trị mới khi không bị Stall (Clock Enable)
            ex_pc         <= id_pc;
            ex_pc_plus4   <= id_pc_plus4;
            ex_rs1_data   <= id_rs1_data;
            ex_rs2_data   <= id_rs2_data;
            ex_imm        <= id_imm;
            ex_rd         <= id_rd;
            ex_rs1        <= id_rs1;
            ex_rs2        <= id_rs2;
            ex_regWrite   <= id_regWrite;
            ex_imm_sel    <= id_imm_sel;
            ex_alu_srcA   <= id_alu_srcA;
            ex_alu_srcB   <= id_alu_srcB;
            ex_alu_ctrl   <= id_alu_ctrl;
            ex_branch     <= id_branch;
            ex_bropcode   <= id_bropcode;
            ex_jump       <= id_jump;
            ex_load_sel   <= id_load_sel;
            ex_store_sel  <= id_store_sel;
            ex_memWrite   <= id_memWrite;
            ex_write_back <= id_write_back;
        end
        // Lưu ý: Nếu stall == 1 và flush == 0, Flip-flop sẽ tự động giữ nguyên giá trị cũ (không cần viết logic giữ).
    end

endmodule
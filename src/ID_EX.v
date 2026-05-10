// ID_EX Pipeline Register (Instruction Decode to Execute)
// Lưu trữ dữ liệu giữa giai đoạn ID và EX trong pipeline 5 tầng

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
    input  wire [2:0]  id_load_sel,
    input  wire [2:0]  id_store_sel,
    input  wire        id_memWrite,
    input  wire [1:0]  id_write_back,
    
    // Đầu ra tới EX stage
    output reg  [31:0] ex_pc,
    output reg  [31:0] ex_pc_plus4,
    output reg  [31:0] ex_rs1_data,
    output reg[31:0] ex_rs2_data,
    output reg  [31:0] ex_imm,
    output reg  [4:0]  ex_rd,
    output reg  [4:0]  ex_rs1,
    output reg  [4:0]  ex_rs2,
    
    // Tín hiệu điều khiển ra
    output reg         ex_regWrite,
    output reg  [2:0]  ex_imm_sel,
    output reg         ex_alu_srcA,
    output reg         ex_alu_srcB,
    output reg  [10:0] ex_alu_ctrl,
    output reg         ex_branch,
    output reg  [2:0]  ex_bropcode,
    output reg  [1:0]  ex_jump,
    output reg  [2:0]  ex_load_sel,
    output reg[2:0]  ex_store_sel,
    output reg         ex_memWrite,
    output reg[1:0]  ex_write_back
);

    // --- 1. Logic tổ hợp: Chọn giá trị tiếp theo ---
    reg [31:0] next_ex_pc, next_ex_pc_plus4, next_ex_rs1_data, next_ex_rs2_data, next_ex_imm;
    reg [4:0]  next_ex_rd, next_ex_rs1, next_ex_rs2;
    reg        next_ex_regWrite, next_ex_alu_srcA, next_ex_alu_srcB, next_ex_branch, next_ex_memWrite;
    reg [2:0]  next_ex_imm_sel, next_ex_bropcode, next_ex_load_sel, next_ex_store_sel;
    reg [1:0]  next_ex_jump, next_ex_write_back;
    reg[10:0] next_ex_alu_ctrl;

    always @(*) begin
        if (flush) begin
            next_ex_pc         = 32'h0;
            next_ex_pc_plus4   = 32'h4;
            next_ex_rs1_data   = 32'h0;
            next_ex_rs2_data   = 32'h0;
            next_ex_imm        = 32'h0;
            next_ex_rd         = 5'b0;
            next_ex_rs1        = 5'b0;
            next_ex_rs2        = 5'b0;
            next_ex_regWrite   = 1'b0;
            next_ex_imm_sel    = 3'b0;
            next_ex_alu_srcA   = 1'b0;
            next_ex_alu_srcB   = 1'b0;
            next_ex_alu_ctrl   = 11'b0;
            next_ex_branch     = 1'b0;
            next_ex_bropcode   = 3'b0;
            next_ex_jump       = 2'b0;
            next_ex_load_sel   = 3'b0;
            next_ex_store_sel  = 3'b0;
            next_ex_memWrite   = 1'b0;
            next_ex_write_back = 2'b0;
        end 
        else if (stall) begin
            next_ex_pc         = ex_pc;
            next_ex_pc_plus4   = ex_pc_plus4;
            next_ex_rs1_data   = ex_rs1_data;
            next_ex_rs2_data   = ex_rs2_data;
            next_ex_imm        = ex_imm;
            next_ex_rd         = ex_rd;
            next_ex_rs1        = ex_rs1;
            next_ex_rs2        = ex_rs2;
            next_ex_regWrite   = ex_regWrite;
            next_ex_imm_sel    = ex_imm_sel;
            next_ex_alu_srcA   = ex_alu_srcA;
            next_ex_alu_srcB   = ex_alu_srcB;
            next_ex_alu_ctrl   = ex_alu_ctrl;
            next_ex_branch     = ex_branch;
            next_ex_bropcode   = ex_bropcode;
            next_ex_jump       = ex_jump;
            next_ex_load_sel   = ex_load_sel;
            next_ex_store_sel  = ex_store_sel;
            next_ex_memWrite   = ex_memWrite;
            next_ex_write_back = ex_write_back;
        end 
        else begin
            next_ex_pc         = id_pc;
            next_ex_pc_plus4   = id_pc_plus4;
            next_ex_rs1_data   = id_rs1_data;
            next_ex_rs2_data   = id_rs2_data;
            next_ex_imm        = id_imm;
            next_ex_rd         = id_rd;
            next_ex_rs1        = id_rs1;
            next_ex_rs2        = id_rs2;
            next_ex_regWrite   = id_regWrite;
            next_ex_imm_sel    = id_imm_sel;
            next_ex_alu_srcA   = id_alu_srcA;
            next_ex_alu_srcB   = id_alu_srcB;
            next_ex_alu_ctrl   = id_alu_ctrl;
            next_ex_branch     = id_branch;
            next_ex_bropcode   = id_bropcode;
            next_ex_jump       = id_jump;
            next_ex_load_sel   = id_load_sel;
            next_ex_store_sel  = id_store_sel;
            next_ex_memWrite   = id_memWrite;
            next_ex_write_back = id_write_back;
        end
    end

    // --- 2. Logic tuần tự: Ghi vào thanh ghi ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
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
        else begin
            ex_pc         <= next_ex_pc;
            ex_pc_plus4   <= next_ex_pc_plus4;
            ex_rs1_data   <= next_ex_rs1_data;
            ex_rs2_data   <= next_ex_rs2_data;
            ex_imm        <= next_ex_imm;
            ex_rd         <= next_ex_rd;
            ex_rs1        <= next_ex_rs1;
            ex_rs2        <= next_ex_rs2;
            ex_regWrite   <= next_ex_regWrite;
            ex_imm_sel    <= next_ex_imm_sel;
            ex_alu_srcA   <= next_ex_alu_srcA;
            ex_alu_srcB   <= next_ex_alu_srcB;
            ex_alu_ctrl   <= next_ex_alu_ctrl;
            ex_branch     <= next_ex_branch;
            ex_bropcode   <= next_ex_bropcode;
            ex_jump       <= next_ex_jump;
            ex_load_sel   <= next_ex_load_sel;
            ex_store_sel  <= next_ex_store_sel;
            ex_memWrite   <= next_ex_memWrite;
            ex_write_back <= next_ex_write_back;
        end
    end

endmodule
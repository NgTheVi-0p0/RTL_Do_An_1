// IF_ID Pipeline Register (Instruction Fetch to Instruction Decode)
// Lưu trữ dữ liệu giữa giai đoạn IF và ID trong pipeline 5 tầng

module IF_ID (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,      // Tín hiệu dừng pipeline
    input  wire        flush,      // Tín hiệu xóa dữ liệu
    
    // Đầu vào từ IF stage
    input  wire [31:0] if_pc,
    input  wire [31:0] if_pc_plus4,
    input  wire[31:0] if_instr,
    
    // Đầu ra tới ID stage
    output reg  [31:0] id_pc,
    output reg  [31:0] id_pc_plus4,
    output reg  [31:0] id_instr
);

    // --- 1. Logic tổ hợp: Chọn giá trị tiếp theo ---
    reg [31:0] next_id_pc;
    reg [31:0] next_id_pc_plus4;
    reg [31:0] next_id_instr;

    always @(*) begin
        if (flush) begin
            next_id_pc       = 32'h0000_0000;
            next_id_pc_plus4 = 32'h0000_0004;
            next_id_instr    = 32'h0000_0013; // NOP (addi x0, x0, 0)
        end 
        else if (stall) begin
            next_id_pc       = id_pc;         // Giữ nguyên khi stall
            next_id_pc_plus4 = id_pc_plus4;
            next_id_instr    = id_instr;
        end 
        else begin
            next_id_pc       = if_pc;         // Cập nhật giá trị mới
            next_id_pc_plus4 = if_pc_plus4;
            next_id_instr    = if_instr;
        end
    end

    // --- 2. Logic tuần tự: Ghi vào thanh ghi ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_pc       <= 32'h0000_0000;
            id_pc_plus4 <= 32'h0000_0004;
            id_instr    <= 32'h0000_0013; // NOP
        end 
        else begin
            id_pc       <= next_id_pc;
            id_pc_plus4 <= next_id_pc_plus4;
            id_instr    <= next_id_instr;
        end
    end

endmodule
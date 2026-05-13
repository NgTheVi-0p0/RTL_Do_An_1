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
    input  wire [31:0] if_instr,
    
    // Đầu ra tới ID stage
    output reg  [31:0] id_pc,
    output reg  [31:0] id_pc_plus4,
    output reg  [31:0] id_instr
);

    // Sử dụng 1 block tuần tự duy nhất
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset không đồng bộ (Asynchronous Reset)
            id_pc       <= 32'h0000_0000;
            id_pc_plus4 <= 32'h0000_0004;
            id_instr    <= 32'h0000_0013; // NOP (addi x0, x0, 0)
        end 
        else if (flush) begin
            // Xóa đồng bộ (Synchronous Flush) - Ghi đè bằng lệnh NOP
            id_pc       <= 32'h0000_0000;
            id_pc_plus4 <= 32'h0000_0004;
            id_instr    <= 32'h0000_0013; // NOP
        end 
        else if (!stall) begin
            // Chỉ cập nhật giá trị mới khi không bị Stall (Clock Enable)
            id_pc       <= if_pc;
            id_pc_plus4 <= if_pc_plus4;
            id_instr    <= if_instr;
        end
        // Lưu ý: Nếu stall == 1 và flush == 0, các thanh ghi (id_pc, id_pc_plus4, id_instr) 
        // sẽ tự động giữ nguyên giá trị hiện tại mà không cần viết lệnh gán lại.
    end

endmodule
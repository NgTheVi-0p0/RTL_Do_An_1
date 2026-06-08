module Hazard_Unit (
    input wire [4:0] if_id_rs1,
    input wire [4:0] if_id_rs2,
    input wire       if_id_uses_rs1,
    input wire       if_id_uses_rs2,
    
    input wire [4:0] id_ex_rd,
    input wire [1:0] id_ex_write_back,    // Trạng thái WB tại tầng EX
    
    input wire [4:0] ex_mem_rd,            // THÊM: Kiểm tra rd tại tầng MEM
    input wire [1:0] ex_mem_write_back,   // THÊM: Kiểm tra nguồn WB tại tầng MEM
    
    input wire       branch_mispredicted,

    output reg       stall_pc,
    output reg       stall_if_id,
    output reg       flush_id_ex,
    output reg       flush_if_id
);

    always @(*) begin
        stall_pc    = 1'b0;
        stall_if_id = 1'b0;
        flush_id_ex = 1'b0;
        flush_if_id = 1'b0;

        // --- Xử lý Load-Use Data Hazard (Stall 2 chu kỳ do RAM Đồng bộ) ---
        
        // Chu kỳ 1: Lệnh Load đang nằm ở tầng EX
        if ((id_ex_write_back == 2'b01) && 
            (id_ex_rd != 5'b0) && 
            ((if_id_uses_rs1 && (id_ex_rd == if_id_rs1)) ||
             (if_id_uses_rs2 && (id_ex_rd == if_id_rs2)))) begin
            
            stall_pc    = 1'b1;
            stall_if_id = 1'b1;
            flush_id_ex = 1'b1; // Chèn NOP vào tầng EX
        end
        
        // Chu kỳ 2: Lệnh Load đã xuống tầng MEM nhưng RAM chưa trả dữ liệu ra ngõ ra tổ hợp
        else if ((ex_mem_write_back == 2'b01) && 
                 (ex_mem_rd != 5'b0) && 
                 ((if_id_uses_rs1 && (ex_mem_rd == if_id_rs1)) ||
                  (if_id_uses_rs2 && (ex_mem_rd == if_id_rs2)))) begin
            
            stall_pc    = 1'b1;
            stall_if_id = 1'b1;
            flush_id_ex = 1'b1; // Tiếp tục giữ bong bóng NOP tại tầng EX thêm 1 chu kỳ
        end
        
        // --- Xử lý Control Hazard ---
        if (branch_mispredicted) begin
            stall_pc    = 1'b0;
            stall_if_id = 1'b0;
            flush_if_id = 1'b1; 
            flush_id_ex = 1'b1; 
        end
    end
endmodule
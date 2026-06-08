module Forwarding_Unit (
    input wire [4:0]  id_ex_rs1,
    input wire [4:0]  id_ex_rs2,
    input wire [4:0]  ex_mem_rd,
    input wire        ex_mem_regWrite,
    input wire [4:0]  mem_wb_rd,
    input wire        mem_wb_regWrite,

    output reg [1:0]  forwardA,
    output reg [1:0]  forwardB
);

    // Forwarding logic cho rs1 (forwardA)
    always @(*) begin
        // 1. Ưu tiên cao nhất: Cập nhật từ tầng EX/MEM (gần ALU nhất)
        if (ex_mem_regWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1)) begin
            forwardA = 2'b01;
        end
        // 2. Ưu tiên thứ hai: Cập nhật từ tầng MEM/WB (Chỉ forward khi tầng EX/MEM KHÔNG chiếm dụng thanh ghi đó)
        else if (mem_wb_regWrite && (mem_wb_rd != 5'b0) && 
                 !(ex_mem_regWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1)) && // SỬA: Điều kiện chặn x0 Hazard
                 (mem_wb_rd == id_ex_rs1)) begin
            forwardA = 2'b10;
        end
        else begin
            forwardA = 2'b00;
        end
    end

    // Forwarding logic cho rs2 (forwardB)
    always @(*) begin
        // 1. Ưu tiên cao nhất: Cập nhật từ tầng EX/MEM
        if (ex_mem_regWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2)) begin
            forwardB = 2'b01;
        end
        // 2. Ưu tiên thứ hai: Cập nhật từ tầng MEM/WB 
        else if (mem_wb_regWrite && (mem_wb_rd != 5'b0) && 
                 !(ex_mem_regWrite && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2)) && // SỬA: Điều kiện chặn x0 Hazard
                 (mem_wb_rd == id_ex_rs2)) begin
            forwardB = 2'b10;
        end
        else begin
            forwardB = 2'b00;
        end
    end
endmodule
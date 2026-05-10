module Program_Counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,         // Tín hiệu cho phép vi xử lý hoạt động
    input  wire        stall,         // Tín hiệu dừng từ Hazard Unit
    input  wire [31:0] pc_next,       // Địa chỉ tiếp theo
    output reg  [31:0] pc_out         // Địa chỉ hiện tại
);

    // --- 1. Logic tổ hợp: Quyết định giá trị PC tiếp theo ---
    reg [31:0] next_pc_val;

    always @(*) begin
        if (start && !stall) begin
            // Chỉ cập nhật khi máy đã khởi động và không bị dừng (Stall)
            next_pc_val = pc_next;
        end 
        else begin
            // Giữ nguyên giá trị PC cũ (Đứng yên)
            next_pc_val = pc_out;
        end
    end

    // --- 2. Logic tuần tự: Chỉ thực hiện việc lưu trữ ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out <= 32'h0000_0000;
        end 
        else begin
            pc_out <= next_pc_val;
        end
    end

endmodule
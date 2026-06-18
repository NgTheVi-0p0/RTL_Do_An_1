module Branch_Prediction_Unit (
    input wire clk,
    input wire rst_n,
    input wire branch_E,
    input wire jump_E,
    input wire branch,
    input wire [31:0] pc_F,
    input wire [31:0] pc_D,
    input wire [31:0] pc_E,
    input wire [31:0] pc_target,
    output wire [31:0] pc_next,
    output wire [31:0] pc_restore,
    output wire flush,
    output wire taken_F
);

    // 1. Khởi tạo PHT (đã đơn giản hóa giao tiếp dây nối)
    wire [1:0] pht_prediction;

    PHT pht_inst (
        .clk(clk),
        .rst_n(rst_n),
        .branch_E(branch_E),
        .jump_E(jump_E),
        .taken(branch),          // Kết nối tín hiệu "branch" vào ngõ "take" của PHT
        .pc_F(pc_F),            // Sử dụng pc_F để dự đoán
        .pc_E(pc_E),
        .predict(pht_prediction)
    );

    // 2. Khởi tạo BTB
    wire [31:0] btb_pc_out;
    wire btb_hit;

    BTB btb_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc_F(pc_F),
        .pc_E(pc_E),
        .pc_target_E(pc_target),
        .branch_E(branch_E),
        .jump_E(jump_E),
        .pc_out(btb_pc_out),
        .hit(btb_hit)
    );

    // 3. Logic quyết định rẽ nhánh tại Fetch stage (Khớp với sơ đồ)
    // taken_F được tích cực khi PHT >= 2 (Strongly/Weakly Taken) và BTB có lưu địa chỉ đích (hit)
    assign taken_F = (pht_prediction >= 2'b10) && btb_hit;
    assign pc_next = taken_F ? btb_pc_out : (pc_F + 32'd4);
    
    // 4. Logic xử lý sửa sai (Flush & Restore) tại Execute stage
    wire ex_taken;
    wire [31:0] actual_next_pc;
    assign ex_taken = branch_E ? branch : jump_E;
    assign actual_next_pc = ex_taken ? pc_target : (pc_E + 32'd4);
    
    // Phát hiện đoán sai hướng hoặc sai địa chỉ khi so sánh với PC hiện tại của giai đoạn Decode (pc_D)
    assign flush = (branch_E || jump_E) && (pc_D != actual_next_pc);
    assign pc_restore = actual_next_pc;

endmodule
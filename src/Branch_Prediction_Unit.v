module Branch_Prediction_Unit (
    input wire clk,
    input wire rst_n,
    input wire branch_E,
    input wire jump_E,
    input wire branch,            // Kết quả nhảy thực tế ở tầng EX (1: Taken, 0: Not Taken)
    input wire [31:0] pc_F,
    input wire [31:0] pc_E,
    input wire [31:0] pc_target,  // Địa chỉ đích thực tế tính từ tầng EX
    input wire [4:0]  ghr_E,      // SỬA: GHR được lưu giữ từ tầng Fetch truyền lên tới EX
    input wire        pred_taken_E,// SỬA: Hướng dự đoán cũ của lệnh này lúc ở tầng Fetch
    
    output wire [4:0] ghr_F_out,  // Xuất GHR hiện tại ở tầng Fetch ra để đẩy vào thanh ghi Pipeline
    output wire [31:0] pc_next,
    output wire [31:0] pc_restore,
    output wire flush,
    output wire taken_F
);
    // 1. Global History Register (Phần cập nhật Speculative tại tầng Fetch)
    reg [4:0] ghr; 
    assign ghr_F_out = ghr; // Đưa ra ngoài để tầng Fetch chốt vào thanh ghi IF/ID

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ghr <= 5'b0;
        // Cập nhật GHR ngay khi lệnh rẽ nhánh được phát hiện ở Fetch (Dự đoán Taken/Not Taken)
        else if (branch_E || jump_E) begin
            // Nếu đoán sai ở tầng EX, ta phục hồi lại GHR chuẩn từ ghr_E
            if (flush) begin
                ghr <= {ghr_E[3:0], (branch_E ? branch : 1'b1)};
            end else begin
                ghr <= {ghr[3:0], taken_F};
            end
        end
    end

    // 2. PHT (Predictor History Table)
    wire [4:0] pht_predict_index = pc_F[6:2] ^ ghr;
    wire [4:0] pht_update_index  = pc_E[6:2] ^ ghr_E; // SỬA: Dùng ghr_E chuẩn của chính lệnh đó
    wire [1:0] pht_prediction;
    wire pht_update_en;

    PHT pht_inst (
        .clk(clk),
        .rst_n(rst_n),
        .predict_index(pht_predict_index),
        .update_index(pht_update_index),
        .update_taken(branch_E ? branch : 1'b1),
        .update_en(pht_update_en),
        .prediction(pht_prediction)
    );

    assign pht_update_en = branch_E || jump_E;

    // 3. BTB (Branch Target Buffer)
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

    // Logic Dự đoán ở tầng Fetch
    assign taken_F = (pht_prediction >= 2'b10) && btb_hit;
    assign pc_next = taken_F ? btb_pc_out : (pc_F + 32'd4);
    
    // --- SỬA LOGIC FLUSH CHUẨN XÁC NHAU ---
    wire actual_taken = branch_E ? branch : jump_E;
    
    // Phát hiện đoán sai hướng HOẶC đoán đúng hướng nhưng bị sai địa chỉ mục tiêu (Dành cho JALR)
    wire mispredict_direction = (actual_taken != pred_taken_E);
    wire mispredict_target    = actual_taken && (btb_pc_out != pc_target); // Nếu nhảy mà địa chỉ BTB sai

    assign flush = (branch_E || jump_E) && (mispredict_direction || mispredict_target);
    
    // Tính toán địa chỉ khôi phục chuẩn xác để nạp lại PC
    assign pc_restore = actual_taken ? pc_target : (pc_E + 32'd4);

endmodule
module PHT (
    input wire clk,
    input wire rst_n,
    input wire branch_E,
    input wire jump_E,
    input wire taken,       // Tương ứng với ngõ vào "take" trên sơ đồ (nối từ tín hiệu "branch" ở Exec)
    input wire [31:0] pc_F, // Giai đoạn Fetch (bản phác thảo ghi pc_D, khuyên dùng pc_F theo sơ đồ)
    input wire [31:0] pc_E, // Giai đoạn Execute để cập nhật
    output wire [1:0] predict
);
    // 1. Khai báo Global History Register (GHR) bên trong PHT
    reg [4:0] ghr; 
    reg [1:0] pht_table [31:0]; // Bảng PHT gồm 32 mục (2-bit bão hòa)
    integer i;

    // Cập nhật GHR đồng bộ theo xung nhịp
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ghr <= 5'b0;
        end else if (branch_E || jump_E) begin
            ghr <= {ghr[3:0], (branch_E ? taken : 1'b1)};
        end
    end

    // 2. Tính toán index bên trong module PHT
    wire [4:0] predict_index = pc_F[6:2] ^ ghr;
    wire [4:0] update_index  = pc_E[6:2] ^ ghr;

    // 3. Đọc tổ hợp (Combinational read) để lấy kết quả dự đoán ngay lập tức
    assign predict = pht_table[predict_index];

    // 4. Mạch logic cập nhật trạng thái bộ đếm bão hòa
    wire update_en = branch_E || jump_E;
    wire update_taken = branch_E ? taken : 1'b1;
    wire [1:0] update_counter = pht_table[update_index];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Khởi tạo toàn bộ bảng PHT về trạng thái Weakly Not Taken (2'b01)
            for (i = 0; i < 32; i = i + 1) begin
                pht_table[i] <= 2'b01;
            end
        end else if (update_en) begin
            if (update_taken) begin
                if (update_counter != 2'b11)
                    pht_table[update_index] <= update_counter + 2'b01; // Tăng trạng thái rẽ nhánh
            end else begin
                if (update_counter != 2'b00)
                    pht_table[update_index] <= update_counter - 2'b01; // Giảm trạng thái rẽ nhánh
            end
        end
    end
endmodule
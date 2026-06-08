module PHT (
    input clk,
    input rst_n,
    input [4:0] predict_index, 
    input [4:0] update_index,  
    input update_taken,
    input update_en,
    output wire [1:0] prediction // Đổi sang wire để gán tổ hợp
);
    reg [1:0] pht_table [31:0]; 
    integer i;

    // Tính toán trước giá trị mới của bộ đếm bão hòa (Saturating Counter)
    wire [1:0] current_counter = pht_table[update_index];
    reg [1:0] next_counter;

    always @(*) begin
        if (update_taken) begin
            next_counter = (current_counter == 2'b11) ? 2'b11 : (current_counter + 2'b01);
        end else begin
            next_counter = (current_counter == 2'b00) ? 2'b00 : (current_counter - 2'b01);
        end
    end

    // Logic GHI/CẬP NHẬT BỘ ĐẾM (Đồng bộ)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                pht_table[i] <= 2'b01; // Mặc định là Weakly Not Taken (hoặc Weakly Taken tuỳ bạn chọn)
        end else if (update_en) begin
            pht_table[update_index] <= next_counter;
        end
    end

    // Logic ĐỌC TRA CỨU BẤT ĐỒNG BỘ + BYPASS
    // Nếu tầng IF đọc đúng vị trí tầng EX đang cập nhật, lấy thẳng dữ liệu "next_counter"
    assign prediction = (update_en && (predict_index == update_index)) ? next_counter : 
                        pht_table[predict_index];

endmodule
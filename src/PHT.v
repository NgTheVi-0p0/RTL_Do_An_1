module PHT (
    input clk,
    input rst_n,
    input [4:0] predict_index, // Dùng 5 bit
    input [4:0] update_index,  // Dùng 5 bit
    input update_taken,
    input update_en,
    output [1:0] prediction    // Bỏ 'reg' để biến thành wire cho mạch tổ hợp
);
    reg [1:0] pht_table [31:0]; // Bảng PHT 32 mục
    integer i;
    
    wire [1:0] update_counter = pht_table[update_index];

    // Combinational read: Đọc dữ liệu ra ngay lập tức không cần đợi xung nhịp clk
    assign prediction = pht_table[predict_index];

    // Synchronous write: Ghi dữ liệu đồng bộ với xung nhịp clk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset toàn bộ bảng PHT về giá trị mặc định (2'b01 - weakly not taken)
            for (i = 0; i < 32; i = i + 1)
                pht_table[i] <= 2'b01;
        end else if (update_en) begin
            if (update_taken) begin
                if (update_counter != 2'b11)
                    pht_table[update_index] <= update_counter + 2'b01; // Tăng trạng thái
                else
                    pht_table[update_index] <= update_counter;         // Bão hòa tại 2'b11 (strongly taken)
            end else begin
                if (update_counter != 2'b00)
                    pht_table[update_index] <= update_counter - 2'b01; // Giảm trạng thái
                else
                    pht_table[update_index] <= update_counter;         // Bão hòa tại 2'b00 (strongly not taken)
            end
        end
    end
endmodule
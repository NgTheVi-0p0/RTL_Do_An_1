module PHT (
    input clk,
    input rst_n,
    input [4:0] predict_index, // Dùng 5 bit
    input [4:0] update_index,  // Dùng 5 bit
    input update_taken,
    input update_en,
    output reg [1:0] prediction
);
    reg [1:0] pht_table [31:0]; // Giảm từ 256 xuống 32
    integer i;
    wire [1:0] update_counter = pht_table[update_index];

    // ĐỌC ĐỒNG BỘ: Kết quả xuất ra ở chu kỳ kế tiếp
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prediction <= 2'b01; // Reset giá trị dự đoán mặc định
        end else begin
            prediction <= pht_table[predict_index];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                pht_table[i] <= 2'b01;
        end else if (update_en) begin
            if (update_taken) begin
                if (update_counter != 2'b11)
                    pht_table[update_index] <= update_counter + 2'b01;
                else
                    pht_table[update_index] <= update_counter;
            end else begin
                if (update_counter != 2'b00)
                    pht_table[update_index] <= update_counter - 2'b01;
                else
                    pht_table[update_index] <= update_counter;
            end
        end
    end
endmodule
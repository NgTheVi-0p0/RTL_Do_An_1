module Program_Counter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,        // Tín hiệu kích hoạt từ Switch/Button bên ngoài
    input  wire        stall,        // Tín hiệu dừng từ Hazard Unit
    input  wire [31:0] pc_next,       
    output reg  [31:0] pc_out,        
    output reg  [31:0] pc_out_btb     
);

    // Quản lý trạng thái hoạt động nội bộ của CPU bằng 1 thanh ghi trạng thái (Run state)
    reg run_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            run_reg <= 1'b0;
        else if (start)
            run_reg <= 1'b1; // Khi nhấn start, CPU chuyển sang trạng thái chạy liên tục
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out     <= 32'b0;
            pc_out_btb <= 32'b0;
        end 
        else begin
            // Chỉ cập nhật PC khi CPU đã được kích hoạt (run_reg == 1) VÀ không bị stall
            if (run_reg && !stall) begin
                pc_out     <= pc_next;
                pc_out_btb <= pc_next;
            end
            // Trường hợp ngược lại tự động giữ nguyên giá trị cũ, không sinh ra Latch thừa
        end
    end

endmodule
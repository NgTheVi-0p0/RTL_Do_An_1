module BTB (
    input clk,
    input rst_n,
    input [31:0] pc_F,
    input [31:0] pc_E,
    input [31:0] pc_target_E,
    input branch_E,
    input jump_E,
    output wire [31:0] pc_out, 
    output wire hit            
);
    reg [31:0] tag [31:0];
    reg [31:0] target [31:0];
    reg valid [31:0];
    integer i;

    // Dùng 5 bit index (32 = 2^5)
    wire [4:0] index_F = pc_F[6:2]; 
    wire [4:0] index_E = pc_E[6:2];

    // Logic GHI/CẬP NHẬT (Đồng bộ theo xung nhịp)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                valid[i] <= 1'b0;
        end else if (branch_E || jump_E) begin
            tag[index_E]    <= pc_E;
            target[index_E] <= pc_target_E;
            valid[index_E]  <= 1'b1;
        end
    end

    // Logic ĐỌC TRA CỨU (Bất đồng bộ - Combinational Logic)
    // Trả kết quả NGAY LẬP TỨC trong chu kỳ Fetch
    assign hit    = valid[index_F] && (tag[index_F] == pc_F);
    assign pc_out = hit ? target[index_F] : 32'b0;

endmodule
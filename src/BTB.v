module BTB (
    input clk,
    input rst_n,
    input [31:0] pc_F,
    input [31:0] pc_E,
    input [31:0] pc_target_E,
    input branch_E,
    input jump_E,
    output reg [31:0] pc_out,
    output reg hit
);
    // Giảm từ 256 xuống 32
    reg [31:0] tag [31:0];
    reg [31:0] target [31:0];
    reg valid [31:0];
    integer i;

    // Dùng 5 bit index (32 = 2^5)
    wire [4:0] index_F = pc_F[6:2]; 
    wire [4:0] index_E = pc_E[6:2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                valid[i] <= 1'b0;
        end else if (branch_E || jump_E) begin
            tag[index_E] <= pc_E;
            target[index_E] <= pc_target_E;
            valid[index_E] <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (valid[index_F] && (tag[index_F] == pc_F)) begin
                pc_out <= target[index_F];
                hit    <= 1'b1;
            end else begin
                pc_out <= 32'b0;
                hit    <= 1'b0;
        end
    end
endmodule
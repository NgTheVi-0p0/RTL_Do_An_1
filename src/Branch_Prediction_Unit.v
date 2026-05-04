module Branch_Prediction_Unit (
    input wire clk,
    input wire rst_n,
    input wire branch_E,
    input wire jump_E,
    input wire taken_E,
    input wire branch,
    input wire [31:0] pc_F,
    input wire [31:0] pc_E,
    input wire [31:0] pc_target,
    output wire [31:0] pc_next,
    output wire [31:0] pc_restore,
    output wire flush,
    output wire taken_F
);
    // 1. Global History Register
    reg [7:0] ghr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ghr <= 8'b0;
        else if (branch_E) ghr <= {ghr[6:0], branch};
    end

    // 2. PHT
    wire [7:0] pht_predict_index = pc_F[9:2] ^ ghr;
    wire [7:0] pht_update_index = pc_E[9:2] ^ ghr;
    wire [1:0] pht_prediction;
    wire pht_update_en;

    PHT pht_inst (
        .clk(clk),
        .rst_n(rst_n),
        .predict_index(pht_predict_index),
        .update_index(pht_update_index),
        .update_taken(branch),
        .update_en(pht_update_en),
        .prediction(pht_prediction)
    );

    assign pht_update_en = branch_E;

    // 3. BTB
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

    assign taken_F = (pht_prediction >= 2'b10) && btb_hit;
    assign pc_next = taken_F ? btb_pc_out : (pc_F + 32'd4);
    
    // Flush khi đoán nhánh sai ở EX
    assign flush = (branch_E && (taken_E != branch));
    assign pc_restore = branch ? pc_target : (pc_E + 32'd4);
endmodule

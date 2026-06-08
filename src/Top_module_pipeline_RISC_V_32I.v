module Top_module_pipeline_RISC_V_32I (
    input wire        clk,
    input wire        rst_n,
    input wire        start,
    input wire        DataOrReg,
    input wire [31:0] check_address,
    output wire [31:0] value,
    input wire [31:0] instruction,
    input wire [31:0] address
);

    // =========================================================================
    // 0. KHAI BÁO TOÀN BỘ WIRES (CHIA THEO TỪNG TẦNG VÀ CHỨC NĂNG)
    // =========================================================================
    
    // --- Tín hiệu tầng IF (Instruction Fetch) ---
    wire [31:0] pc_F;                 // Giá trị PC hiện tại ở tầng Fetch
    wire [31:0] pc_out_btb;           // Giá trị PC dùng cho BTB
    wire [31:0] pc4_F;                // Giá trị PC + 4
    wire [31:0] instr_F;              // Lệnh lấy ra từ IMEM
    wire [31:0] predicted_pc_next_F;  // PC tiếp theo do khối BPU dự đoán
    wire [31:0] pc_next_F;            // PC thực tế nạp vào thanh ghi PC
    wire        pred_taken_F;         // Tín hiệu hướng dự đoán rẽ nhánh tại Fetch
    wire [4:0]  ghr_F;                // Lịch sử toàn cục xuất ra từ BPU tại tầng Fetch

    // --- Tín hiệu tầng ID (Instruction Decode) ---
    wire [31:0] pc_D;                 // PC tầng Decode
    wire [31:0] pc4_D;                // PC + 4 tầng Decode
    wire [31:0] instr_D;              // Nội dung lệnh tầng Decode
    wire [31:0] rs1_data_D;           // Dữ liệu đọc từ RF rs1
    wire [31:0] rs2_data_D;           // Dữ liệu đọc từ RF rs2
    wire [31:0] imm_D;                // Giá trị tức thời đã mở rộng
    wire [31:0] fwd_rs1_data_D;       // Dữ liệu rs1 sau mạch Internal Bypass tại ID
    wire [31:0] fwd_rs2_data_D;       // Dữ liệu rs2 sau mạch Internal Bypass tại ID
    wire [4:0]  rs1_D;                // Địa chỉ rs1
    wire [4:0]  rs2_D;                // Địa chỉ rs2
    wire [4:0]  rd_D;                 // Địa chỉ rd
    wire        uses_rs1_D;           // Cờ lệnh dùng rs1
    wire        uses_rs2_D;           // Cờ lệnh dùng rs2
    wire        regWrite_D;           // Cho phép ghi RF
    wire        alu_srcA_D;           // Lựa chọn toán hạng A cho ALU
    wire        alu_srcB_D;           // Lựa chọn toán hạng B cho ALU
    wire        branch_D;             // Lệnh là lệnh rẽ nhánh
    wire        memWrite_D;           // Cho phép ghi RAM
    wire [3:0]  alu_ctrl_D;           // Điều khiển ALU
    wire [2:0]  imm_sel_D;            // Kiểu mở rộng Immediate
    wire [2:0]  bropcode_D;           // Loại điều kiện rẽ nhánh
    wire [2:0]  load_sel_D;           // Kiểu load dữ liệu
    wire [2:0]  store_sel_D;          // Kiểu store dữ liệu
    wire [1:0]  jump_D;               // Loại lệnh nhảy (JAL, JALR)
    wire [1:0]  write_back_D;         // Nguồn dữ liệu ghi về thanh ghi
    wire [31:0] regfile_debug_val;    // Giá trị thanh ghi debug
    wire [4:0]  ghr_D;                // Lịch sử GHR được giữ lại tại tầng ID
    wire        pred_taken_D;         // Hướng dự đoán được giữ lại tại tầng ID

    // --- Tín hiệu tầng EX (Execute) ---
    wire [31:0] pc_E;                 // PC tầng Execute
    wire [31:0] pc4_E;                // PC + 4 tầng Execute
    wire [31:0] rs1_data_E;           // Dữ liệu rs1 tầng Execute
    wire [31:0] rs2_data_E;           // Dữ liệu rs2 tầng Execute
    wire [31:0] imm_E;                // Giá trị tức thời tầng Execute
    wire [31:0] pc_restore_E;         // Địa chỉ PC khôi phục khi đoán sai
    wire [4:0]  rd_E;                 // Địa chỉ rd tầng Execute
    wire [4:0]  rs1_E;                // Địa chỉ rs1 tầng Execute
    wire [4:0]  rs2_E;                // Địa chỉ rs2 tầng Execute
    wire        regWrite_E;           // Điều khiển ghi thanh ghi qua tầng EX
    wire        alu_srcA_E;           // Lựa chọn ALU srcA tầng Execute
    wire        alu_srcB_E;           // Lựa chọn ALU srcB tầng Execute
    wire        branch_E;             // Lệnh nhánh tại EX
    wire        memWrite_E;           // Ghi bộ nhớ tại EX
    wire [3:0]  alu_ctrl_E;           // Mã phép toán ALU tầng EX
    wire [2:0]  imm_sel_E;            // Kiểu Imm tầng EX
    wire [2:0]  bropcode_E;           // Mã nhánh tầng EX
    wire [1:0]  jump_E;               // Mã nhảy tầng EX
    wire [2:0]  load_sel_E;           // Kiểu load tầng EX
    wire [2:0]  store_sel_E;          // Kiểu store tầng EX
    wire [1:0]  write_back_E;         // Lựa chọn nguồn WB tại EX
    wire [1:0]  forwardA;             // Chọn Forwarding toán hạng A
    wire [1:0]  forwardB;             // Chọn Forwarding toán hạng B
    wire [31:0] ex_rs1_fwd;           // Dữ liệu toán hạng 1 sau Forwarding
    wire [31:0] ex_rs2_fwd;           // Dữ liệu toán hạng 2 sau Forwarding
    wire [31:0] alu_result_E;         // Kết quả ALU
    wire [31:0] alu_a_E;              // Đầu vào A thực tế của ALU
    wire [31:0] alu_b_E;              // Đầu vào B thực tế của ALU
    wire [31:0] pc_plus_imm_E;        // PC + Imm
    wire [31:0] jalr_add_result_E;    // rs1 + Imm
    wire [31:0] jalr_target_E;        // Đích JALR (ép bit cuối về 0)
    wire [31:0] pc_target_E;          // Đích cuối cùng của lệnh nhảy thực tế
    wire        equal_E;              // Cờ bằng nhau
    wire        less_signed_E;        // So sánh nhỏ hơn (có dấu)
    wire        less_unsigned_E;      // So sánh nhỏ hơn (không dấu)
    wire        branch_taken_E;       // Kết quả thực tế rẽ nhánh (1: Taken, 0: Not-Taken)
    wire        is_jump_E;            // Là lệnh nhảy (JAL/JALR)
    wire        bpu_flush_E;          // Tín hiệu xóa do đoán sai hướng/địa chỉ mục tiêu
    wire [4:0]  ghr_E;                // Lịch sử GHR truyền đến tầng EX
    wire        pred_taken_E;         // Hướng dự đoán cũ truyền đến tầng EX

    // --- Tín hiệu tầng MEM (Memory Access) ---
    wire [31:0] pc4_M;                // PC + 4 tầng MEM
    wire [31:0] mem_alu_result_M;     // Địa chỉ bộ nhớ RAM
    wire [31:0] rs2_data_M;           // Dữ liệu ghi vào RAM
    wire [31:0] mem_read_data_M;      // Dữ liệu thô đọc từ RAM
    wire [31:0] mem_forward_data_M_for_EX; // Luồng dữ liệu forward nhanh từ MEM
    wire [31:0] dmem_debug_val;       // Dữ liệu debug RAM
    wire [4:0]  mem_rd_M;             // Thanh ghi đích tại tầng MEM
    wire        mem_regWrite_M;       // Cho phép ghi thanh ghi tầng MEM
    wire        memWrite_M;           // Cho phép ghi RAM tầng MEM
    wire [2:0]  load_sel_M;           // Kiểu load tầng MEM
    wire [2:0]  store_sel_M;          // Kiểu store tầng MEM
    wire [1:0]  write_back_M;         // Chọn lựa WB tại tầng MEM

    // --- Tín hiệu tầng WB (Write Back) ---
    wire [31:0] pc4_W;                // PC + 4 tầng WB
    wire [31:0] alu_result_W;         // Kết quả ALU tầng WB
    wire [31:0] mem_data_W;           // Dữ liệu RAM đã aligner tầng WB
    wire [31:0] wb_data;              // Dữ liệu ghi cuối cùng về RF
    wire [4:0]  wb_rd;                // Địa chỉ ghi thanh ghi cuối cùng
    wire        wb_regWrite;          // Cờ điều khiển ghi RF cuối cùng
    wire [1:0]  write_back_W;         // Lựa chọn nguồn WB tại WB

    // --- Tín hiệu Điều khiển Hazard & Stall từ Hazard Unit ---
    wire        stall_pc_total;       
    wire        stall_if_id_total;    
    wire        flush_id_ex_total;    
    wire        flush_if_id_total;    

    // =========================================================================
    // 1. INSTRUCTION FETCH (IF)
    // =========================================================================
    assign pc_next_F = bpu_flush_E ? pc_restore_E : predicted_pc_next_F;
    assign pc4_F     = pc_F + 32'd4;

    Program_Counter pc_reg (
        .clk        (clk), 
        .rst_n      (rst_n), 
        .start      (start), 
        .stall      (stall_pc_total), 
        .pc_next    (pc_next_F), 
        .pc_out     (pc_F), 
        .pc_out_btb (pc_out_btb)
    );

    instruction_memory imem (
        .clk        (clk), 
        .we         (~start), 
        .addr_ext   (address), 
        .din_ext    (instruction), 
        .pc         (pc_F), 
        .instr      (instr_F)
    );

    // SỬA: Thay đổi thiết kế module IF_ID để chốt thêm cả GHR và hướng dự đoán qua từng chu kỳ
    IF_ID if_id_reg (
        .clk          (clk), 
        .rst_n        (rst_n), 
        .stall        (stall_if_id_total), 
        .flush        (flush_if_id_total), 
        .if_pc        (pc_F), 
        .if_pc_plus4  (pc4_F), 
        .if_instr     (instr_F), 
        .id_pc        (pc_D), 
        .id_pc_plus4  (pc4_D), 
        .id_instr     (instr_D)
    );

    // Chốt thêm thông tin dự đoán nhánh từ tầng Fetch sang tầng Decode
    reg [4:0] ghr_D_reg;
    reg       pred_taken_D_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ghr_D_reg        <= 5'b0;
            pred_taken_D_reg <= 1'b0;
        end else if (flush_if_id_total) begin
            ghr_D_reg        <= 5'b0;
            pred_taken_D_reg <= 1'b0;
        end else if (!stall_if_id_total) begin
            ghr_D_reg        <= ghr_F;
            pred_taken_D_reg <= pred_taken_F;
        end
    end
    assign ghr_D        = ghr_D_reg;
    assign pred_taken_D = pred_taken_D_reg;

    // =========================================================================
    // 2. INSTRUCTION DECODE (ID)
    // =========================================================================
    assign rs1_D = instr_D[19:15];
    assign rs2_D = instr_D[24:20];
    assign rd_D  = instr_D[11:7];

    control_unit cu (
        .opcode       (instr_D[6:0]), 
        .funct3       (instr_D[14:12]), 
        .funct7       (instr_D[31:25]), 
        .regWrite_D   (regWrite_D), 
        .imm_sel      (imm_sel_D), 
        .alu_srcA_D   (alu_srcA_D), 
        .alu_srcB_D   (alu_srcB_D), 
        .alu_ctrl     (alu_ctrl_D), 
        .branch_D     (branch_D), 
        .bropcode     (bropcode_D), 
        .jump_D       (jump_D), 
        .load_sel_D   (load_sel_D), 
        .store_sel_D  (store_sel_D), 
        .memWrite_D   (memWrite_D), 
        .write_back_D (write_back_D), 
        .uses_rs1_D   (uses_rs1_D), 
        .uses_rs2_D   (uses_rs2_D)
    );

    imm_extend imm_gen (
        .instr        (instr_D), 
        .imm_sel      (imm_sel_D), 
        .imm_ext      (imm_D)
    );

    Register_File regfile (
        .clk          (clk), 
        .rst_n        (rst_n), 
        .reg_write    (wb_regWrite), 
        .rs1          (rs1_D), 
        .rs2          (rs2_D), 
        .rd           (wb_rd), 
        .wd           (wb_data), 
        .rd1          (rs1_data_D), 
        .rd2          (rs2_data_D), 
        .debug_addr   (check_address[4:0]),
        .debug_val    (regfile_debug_val)
    );

    // Mạch Internal Forwarding tại ID để tối ưu hoá đọc-ghi đồng thời
    assign fwd_rs1_data_D = (wb_regWrite && (wb_rd != 5'd0) && (wb_rd == rs1_D)) ? wb_data : rs1_data_D;
    assign fwd_rs2_data_D = (wb_regWrite && (wb_rd != 5'd0) && (wb_rd == rs2_D)) ? wb_data : rs2_data_D;

    ID_EX id_ex_reg (
        .clk          (clk), 
        .rst_n        (rst_n), 
        .stall        (1'b0), 
        .flush        (flush_id_ex_total), 
        .id_pc        (pc_D), 
        .id_pc_plus4  (pc4_D), 
        .id_rs1_data  (fwd_rs1_data_D), 
        .id_rs2_data  (fwd_rs2_data_D), 
        .id_imm       (imm_D), 
        .id_rd        (rd_D), 
        .id_rs1       (rs1_D), 
        .id_rs2       (rs2_D), 
        .id_regWrite  (regWrite_D), 
        .id_imm_sel   (imm_sel_D), 
        .id_alu_srcA  (alu_srcA_D), 
        .id_alu_srcB  (alu_srcB_D), 
        .id_alu_ctrl  (alu_ctrl_D), 
        .id_branch    (branch_D), 
        .id_bropcode  (bropcode_D), 
        .id_jump      (jump_D), 
        .id_load_sel  (load_sel_D), 
        .id_store_sel (store_sel_D), 
        .id_memWrite  (memWrite_D), 
        .id_write_back(write_back_D), 
        .ex_pc        (pc_E), 
        .ex_pc_plus4  (pc4_E), 
        .ex_rs1_data  (rs1_data_E), 
        .ex_rs2_data  (rs2_data_E), 
        .ex_imm       (imm_E), 
        .ex_rd        (rd_E), 
        .ex_rs1       (rs1_E), 
        .ex_rs2       (rs2_E), 
        .ex_regWrite  (regWrite_E), 
        .ex_imm_sel   (imm_sel_E), 
        .ex_alu_srcA  (alu_srcA_E), 
        .ex_alu_srcB  (alu_srcB_E), 
        .ex_alu_ctrl  (alu_ctrl_E), 
        .ex_branch    (branch_E), 
        .ex_bropcode  (bropcode_E), 
        .ex_jump      (jump_E), 
        .ex_load_sel  (load_sel_E), 
        .ex_store_sel (store_sel_E), 
        .ex_memWrite  (memWrite_E), 
        .ex_write_back(write_back_E)
    );

    // Chốt thông tin dự đoán nhánh từ tầng Decode sang tầng Execute
    reg [4:0] ghr_E_reg;
    reg       pred_taken_E_reg;
    always @(posedge clk or rst_n) begin
        if (!rst_n) begin
            ghr_E_reg        <= 5'b0;
            pred_taken_E_reg <= 1'b0;
        end else if (flush_id_ex_total) begin
            ghr_E_reg        <= 5'b0;
            pred_taken_E_reg <= 1'b0;
        end else begin
            ghr_E_reg        <= ghr_D;
            pred_taken_E_reg <= pred_taken_D;
        end
    end
    assign ghr_E        = ghr_E_reg;
    assign pred_taken_E = pred_taken_E_reg;

    // =========================================================================
    // 3. EXECUTE (EX)
    // =========================================================================
    Forwarding_Unit fwd_unit (
        .id_ex_rs1       (rs1_E), 
        .id_ex_rs2       (rs2_E), 
        .ex_mem_rd       (mem_rd_M), 
        .ex_mem_regWrite (mem_regWrite_M), 
        .mem_wb_rd       (wb_rd), 
        .mem_wb_regWrite (wb_regWrite), 
        .forwardA        (forwardA), 
        .forwardB        (forwardB)
    );

    // SỬA: Do RAM là đồng bộ, dữ liệu ghi về từ MEM ko bao gồm lệnh Load (Load-Use đã stall riêng)
    assign mem_forward_data_M_for_EX = (write_back_M == 2'b10) ? pc4_M : mem_alu_result_M;

    assign ex_rs1_fwd = (forwardA == 2'b01) ? mem_forward_data_M_for_EX : (forwardA == 2'b10) ? wb_data : rs1_data_E;
    assign ex_rs2_fwd = (forwardB == 2'b01) ? mem_forward_data_M_for_EX : (forwardB == 2'b10) ? wb_data : rs2_data_E;

    // Logic kiểm tra điều kiện rẽ nhánh thực tế tại EX
    assign equal_E         = (ex_rs1_fwd == ex_rs2_fwd);
    assign less_signed_E   = ($signed(ex_rs1_fwd) < $signed(ex_rs2_fwd));
    assign less_unsigned_E = (ex_rs1_fwd < ex_rs2_fwd);
    assign branch_taken_E  = branch_E && (
        (bropcode_E == 3'b000 && equal_E) || (bropcode_E == 3'b001 && !equal_E) ||
        (bropcode_E == 3'b100 && less_signed_E) || (bropcode_E == 3'b101 && !less_signed_E) ||
        (bropcode_E == 3'b110 && less_unsigned_E) || (bropcode_E == 3'b111 && !less_unsigned_E)
    );

    assign is_jump_E = (jump_E != 2'b00);
    assign pc_plus_imm_E = pc_E + imm_E;
    assign jalr_add_result_E = ex_rs1_fwd + imm_E; 
    assign jalr_target_E = { jalr_add_result_E[31:1], 1'b0 };
    assign pc_target_E = (jump_E == 2'b10) ? jalr_target_E : pc_plus_imm_E;

    // SỬA: Ánh xạ chuẩn xác chân port của module Branch_Prediction_Unit (BPU) của bạn
    Branch_Prediction_Unit bpu (
        .clk          (clk), 
        .rst_n        (rst_n), 
        .branch_E     (branch_E), 
        .jump_E       (is_jump_E), 
        .branch       (branch_taken_E),      // Kết quả thực tế Taken/Not-Taken
        .pc_F         (pc_F), 
        .pc_E         (pc_E), 
        .pc_target    (pc_target_E),         // Đích thực tế từ EX
        .ghr_E        (ghr_E),               // Đưa vào ghr chuẩn lưu giữ từ Fetch
        .pred_taken_E (pred_taken_E),        // Đưa vào hướng đoán cũ của lệnh
        .ghr_F_out    (ghr_F),               // Đẩy lịch sử thô tại Fetch ra ngoài
        .pc_next      (predicted_pc_next_F), 
        .pc_restore   (pc_restore_E), 
        .flush        (bpu_flush_E),         // Xóa do đoán sai hướng hoặc lệch Target
        .taken_F      (pred_taken_F)
    );

    // Tính toán toán hạng và gọi khối ALU
    assign alu_a_E = alu_srcA_E ? pc_E : ex_rs1_fwd;
    assign alu_b_E = alu_srcB_E ? imm_E : ex_rs2_fwd;

    ALU alu_inst (
        .a          (alu_a_E), 
        .b          (alu_b_E), 
        .alu_ctrl   (alu_ctrl_E), 
        .result     (alu_result_E), 
        .zero       () 
    );

    EX_MEM ex_mem_reg (
        .clk          (clk), 
        .rst_n        (rst_n), 
        .flush        (1'b0), 
        .ex_pc_plus4  (pc4_E), 
        .ex_alu_result(alu_result_E), 
        .ex_rs2_data  (ex_rs2_fwd), 
        .ex_rd        (rd_E), 
        .ex_regWrite  (regWrite_E), 
        .ex_load_sel  (load_sel_E), 
        .ex_store_sel (store_sel_E), 
        .ex_memWrite  (memWrite_E), 
        .ex_write_back(write_back_E), 
        .mem_pc_plus4  (pc4_M), 
        .mem_alu_result(mem_alu_result_M), 
        .mem_rs2_data  (rs2_data_M), 
        .mem_rd        (mem_rd_M), 
        .mem_regWrite  (mem_regWrite_M), 
        .mem_load_sel  (load_sel_M), 
        .mem_store_sel (store_sel_M), 
        .mem_memWrite  (memWrite_M), 
        .mem_write_back(write_back_M)
    );

    // =========================================================================
    // 4. MEMORY ACCESS (MEM)
    // =========================================================================
    data_memory dmem (
        .clk          (clk), 
        .mem_write    (memWrite_M), 
        .addr         (mem_alu_result_M), 
        .write_data   (rs2_data_M), 
        .load_sel     (load_sel_M), 
        .store_sel    (store_sel_M), 
        .read_data    (mem_read_data_M), 
        .debug_addr   (check_address[11:2]),
        .debug_val    (dmem_debug_val)
    );

    MEM_WB mem_wb_reg (
        .clk          (clk), 
        .rst_n        (rst_n), 
        .mem_pc_plus4  (pc4_M), 
        .mem_alu_result(mem_alu_result_M), 
        .mem_mem_data  (mem_read_data_M),  // Đẩy data thô sang WB để thực hiện Aligner
        .mem_rd        (mem_rd_M), 
        .mem_regWrite  (mem_regWrite_M), 
        .mem_write_back(write_back_M), 
        .wb_pc_plus4  (pc4_W), 
        .wb_alu_result(alu_result_W), 
        .wb_mem_data  (mem_data_W),        // Nhận dữ liệu sạch đã căn chỉnh lề (LB, LH, LW)
        .wb_rd        (wb_rd), 
        .wb_regWrite  (wb_regWrite), 
        .wb_write_back(write_back_W)
    );

    // =========================================================================
    // 5. WRITE BACK (WB)
    // =========================================================================
    assign wb_data = (write_back_W == 2'b00) ? alu_result_W :
                     (write_back_W == 2'b01) ? mem_data_W :
                     (write_back_W == 2'b10) ? pc4_W : 32'b0;

    // =========================================================================
    // 6. HAZARD, STALL & CONTROL LOGIC (Tối ưu hóa Timing RAM đồng bộ)
    // =========================================================================
    
    // SỬA: Đồng bộ hóa toàn bộ chân port của Hazard Unit và chuyển giao cấu trúc giám sát 2 tầng EX/MEM
    Hazard_Unit hazard_unit (
        .if_id_rs1          (rs1_D), 
        .if_id_rs2          (rs2_D), 
        .if_id_uses_rs1     (uses_rs1_D), 
        .if_id_uses_rs2     (uses_rs2_D), 
        .id_ex_rd           (rd_E), 
        .id_ex_write_back   (write_back_E),        // SỬA: Sửa đúng tên chân con `id_ex_write_back`
        .ex_mem_rd          (mem_rd_M),            // THÊM: Theo dõi rd tầng MEM để stall chu kỳ 2
        .ex_mem_write_back  (write_back_M),        // THÊM: Theo dõi nguồn WB tầng MEM để stall chu kỳ 2
        .branch_mispredicted(bpu_flush_E), 
        .stall_pc           (stall_pc_total), 
        .stall_if_id        (stall_if_id_total),
        .flush_id_ex        (flush_id_ex_total),
        .flush_if_id        (flush_if_id_total)
    );

    assign value = DataOrReg ? dmem_debug_val : regfile_debug_val;

endmodule
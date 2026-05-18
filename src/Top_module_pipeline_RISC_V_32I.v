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
    wire [31:0] pc_out_btb;           // Giá trị PC dự đoán từ khối Branch Target Buffer
    wire [31:0] pc4_F;                // Giá trị PC + 4 (địa chỉ lệnh kế tiếp)
    wire [31:0] instr_F;              // Lệnh lấy ra từ bộ nhớ Instruction Memory
    wire [31:0] predicted_pc_next_F;  // PC tiếp theo do khối BPU dự đoán
    wire [31:0] pc_next_F;            // PC thực tế sẽ nạp vào thanh ghi PC (đã chọn lọc)
    wire        pred_taken_F;         // Tín hiệu báo lệnh nhảy được dự đoán là sẽ xảy ra

    // --- Tín hiệu tầng ID (Instruction Decode) ---
    wire [31:0] pc_D;                 // PC của lệnh đang được giải mã
    wire [31:0] pc4_D;                // PC + 4 của lệnh đang được giải mã
    wire [31:0] instr_D;              // Nội dung lệnh đang được giải mã
    wire [31:0] rs1_data_D;           // Dữ liệu đọc từ thanh ghi nguồn 1
    wire [31:0] rs2_data_D;           // Dữ liệu đọc từ thanh ghi nguồn 2
    wire [31:0] imm_D;                // Giá trị tức thời (Immediate) đã mở rộng
    wire [31:0] fwd_rs1_data_D;       // Dữ liệu rs1 sau khi xử lý bypass tại ID
    wire [31:0] fwd_rs2_data_D;       // Dữ liệu rs2 sau khi xử lý bypass tại ID
    wire [4:0]  rs1_D;                // Địa chỉ thanh ghi nguồn 1
    wire [4:0]  rs2_D;                // Địa chỉ thanh ghi nguồn 2
    wire [4:0]  rd_D;                 // Địa chỉ thanh ghi đích
    wire        uses_rs1_D;           // Lệnh có sử dụng rs1 hay không
    wire        uses_rs2_D;           // Lệnh có sử dụng rs2 hay không
    wire        regWrite_D;           // Cho phép ghi vào Register File
    wire        alu_srcA_D;           // Lựa chọn đầu vào A cho ALU
    wire        alu_srcB_D;           // Lựa chọn đầu vào B cho ALU
    wire        branch_D;             // Lệnh hiện tại là lệnh nhánh
    wire        memWrite_D;           // Cho phép ghi vào RAM
    wire [3:0]  alu_ctrl_D;           // Mã lệnh điều khiển ALU
    wire [2:0]  imm_sel_D;            // Kiểu mở rộng Immediate
    wire [2:0]  bropcode_D;           // Loại lệnh nhánh
    wire [2:0]  load_sel_D;           // Kiểu load dữ liệu
    wire [2:0]  store_sel_D;          // Kiểu store dữ liệu
    wire [1:0]  jump_D;               // Loại lệnh nhảy (JAL, JALR)
    wire [1:0]  write_back_D;         // Lựa chọn dữ liệu Write Back
    wire [31:0] regfile_debug_val;    // Giá trị thanh ghi phục vụ debug

    // --- Tín hiệu tầng EX (Execute) ---
    wire [31:0] pc_E;                 // PC của lệnh đang thực thi
    wire [31:0] pc4_E;                // PC + 4 của lệnh đang thực thi
    wire [31:0] rs1_data_E;           // Dữ liệu rs1 tầng EX
    wire [31:0] rs2_data_E;           // Dữ liệu rs2 tầng EX
    wire [31:0] imm_E;                // Giá trị tức thời tầng EX
    wire [31:0] pc_restore_E;         // PC cần khôi phục nếu dự đoán sai
    wire [4:0]  rd_E;                 // Địa chỉ thanh ghi đích tầng EX
    wire [4:0]  rs1_E;                // Địa chỉ rs1 tầng EX
    wire [4:0]  rs2_E;                // Địa chỉ rs2 tầng EX
    wire        regWrite_E;           // Tín hiệu ghi thanh ghi tầng EX
    wire        alu_srcA_E;           // Lựa chọn ALU srcA tầng EX
    wire        alu_srcB_E;           // Lựa chọn ALU srcB tầng EX
    wire        branch_E;             // Lệnh nhánh tầng EX
    wire        memWrite_E;           // Ghi bộ nhớ tầng EX
    wire [3:0]  alu_ctrl_E;           // Mã điều khiển ALU tầng EX
    wire [2:0]  imm_sel_E;            // Kiểu mở rộng Immediate tầng EX
    wire [2:0]  bropcode_E;           // Mã nhánh tầng EX
    wire [1:0]  jump_E;               // Mã nhảy tầng EX
    wire [2:0]  load_sel_E;           // Kiểu load tầng EX
    wire [2:0]  store_sel_E;          // Kiểu store tầng EX
    wire [1:0]  write_back_E;         // Lựa chọn WB tầng EX
    wire [1:0]  forwardA;             // Chọn Forwarding cho ALU in A
    wire [1:0]  forwardB;             // Chọn Forwarding cho ALU in B
    wire [31:0] ex_rs1_fwd;           // Dữ liệu rs1 sau Forwarding
    wire [31:0] ex_rs2_fwd;           // Dữ liệu rs2 sau Forwarding
    wire [31:0] alu_result_E;         // Kết quả ALU
    wire [31:0] alu_a_E;              // Đầu vào A thực tế của ALU
    wire [31:0] alu_b_E;              // Đầu vào B thực tế của ALU
    wire [31:0] pc_plus_imm_E;        // PC + Imm (đích lệnh nhánh/JAL)
    wire [31:0] jalr_add_result_E;    // rs1 + Imm cho JALR
    wire [31:0] jalr_target_E;        // Đích JALR (ép bit cuối về 0)
    wire [31:0] pc_target_E;          // Đích cuối cùng của lệnh nhảy
    wire        equal_E;              // So sánh bằng (rs1 == rs2)
    wire        less_signed_E;        // So sánh nhỏ hơn (có dấu)
    wire        less_unsigned_E;      // So sánh nhỏ hơn (không dấu)
    wire        branch_taken_E;       // Quyết định thực tế có nhảy không
    wire        is_jump_E;            // Là lệnh nhảy (JAL/JALR)
    wire        bpu_flush_E;          // Xóa Pipeline do dự đoán sai

    // --- Tín hiệu tầng MEM (Memory Access) ---
    wire [31:0] pc4_M;                // PC + 4 tầng MEM
    wire [31:0] mem_alu_result_M;     // Kết quả ALU (địa chỉ RAM)
    wire [31:0] rs2_data_M;           // Dữ liệu rs2 (để ghi RAM)
    wire [31:0] mem_read_data_M;      // Dữ liệu đọc từ RAM
    wire [31:0] mem_forward_data_M_for_EX; // Dữ liệu Forwarding từ MEM -> EX
    wire [31:0] dmem_debug_val;       // Dữ liệu debug RAM
    wire [4:0]  mem_rd_M;             // Địa chỉ rd tầng MEM
    wire        mem_regWrite_M;       // Ghi thanh ghi tầng MEM
    wire        memWrite_M;           // Ghi vào RAM
    wire [2:0]  load_sel_M;           // Kiểu load tầng MEM
    wire [2:0]  store_sel_M;          // Kiểu store tầng MEM
    wire [1:0]  write_back_M;         // Lựa chọn WB tầng MEM

    // --- Tín hiệu tầng WB (Write Back) ---
    wire [31:0] pc4_W;                // PC + 4 tầng WB
    wire [31:0] alu_result_W;         // Kết quả ALU tầng WB
    wire [31:0] mem_data_W;           // Dữ liệu đọc từ RAM tầng WB
    wire [31:0] wb_data;              // Dữ liệu ghi vào Register File
    wire [4:0]  wb_rd;                // Địa chỉ rd cuối cùng
    wire        wb_regWrite;          // Cho phép ghi thanh ghi thực tế
    wire [1:0]  write_back_W;         // Lựa chọn WB tầng WB

    // --- Tín hiệu Điều khiển Hazard & Stall ---
    wire        stall_pc_hazard;      // Stall PC do xung đột
    wire        stall_if_id_hazard;   // Stall tầng IF/ID
    wire        flush_id_ex_hazard;   // Xóa tầng ID/EX do Hazard
    wire        flush_if_id_hazard;   // Xóa tầng IF/ID do Hazard
    wire        stall_pc_total;       // Tổng hợp Stall cho PC
    wire        stall_if_id_total;    // Tổng hợp Stall cho IF/ID
    wire        flush_if_id_total;    // Tổng hợp xóa lệnh IF/ID
    wire        flush_id_ex_total;    // Tổng hợp xóa lệnh ID/EX
    wire        stall_id_ex_total;    // Stall ID/EX khi chưa Start
    wire        stall_top_load_use;   // Stall do Load-Use 2 chu kỳ

    // =========================================================================
    // 1. INSTRUCTION FETCH (IF)
    // =========================================================================
    assign pc_next_F = bpu_flush_E ? pc_restore_E : predicted_pc_next_F;
    assign pc4_F     = pc_F + 32'd4;

    Program_Counter pc_reg (
        .clk        (clk),               // Xung nhịp hệ thống
        .rst_n      (rst_n),             // Reset tích cực mức thấp
        .start      (start),             // Tín hiệu bắt đầu chạy CPU
        .stall      (stall_pc_total),    // Đóng băng PC khi có Hazard
        .pc_next    (pc_next_F),         // Giá trị PC tiếp theo cần cập nhật
        .pc_out     (pc_F),              // PC hiện tại xuất ra Fetch
        .pc_out_btb (pc_out_btb)         // PC dùng cho dự đoán nhánh (BTB)
    );

    instruction_memory imem (
        .clk        (clk),               // Xung nhịp hệ thống
        .we         (~start),            // Cho phép nạp lệnh từ ngoài khi chưa chạy
        .addr_ext   (address),           // Địa chỉ nạp lệnh ngoại vi
        .din_ext    (instruction),       // Dữ liệu lệnh nạp ngoại vi
        .pc         (pc_F),              // PC cấp vào để đọc lệnh
        .instr      (instr_F)            // Lệnh đọc ra tương ứng
    );

    IF_ID if_id_reg (
        .clk          (clk),               // Xung nhịp hệ thống
        .rst_n        (rst_n),             // Reset
        .stall        (stall_if_id_total), // Đóng băng thanh ghi IF/ID
        .flush        (flush_if_id_total), // Xóa thanh ghi IF/ID (chèn NOP)
        // Đầu vào tầng IF
        .if_pc        (pc_F),              // Nhận PC từ IF
        .if_pc_plus4  (pc4_F),             // Nhận PC+4 từ IF
        .if_instr     (instr_F),           // Nhận Lệnh từ IF
        // Đầu ra tầng ID
        .id_pc        (pc_D),              // Đẩy PC sang ID
        .id_pc_plus4  (pc4_D),             // Đẩy PC+4 sang ID
        .id_instr     (instr_D)            // Đẩy Lệnh sang ID
    );

    // =========================================================================
    // 2. INSTRUCTION DECODE (ID)
    // =========================================================================
    assign rs1_D = instr_D[19:15];
    assign rs2_D = instr_D[24:20];
    assign rd_D  = instr_D[11:7];

    control_unit cu (
        .opcode       (instr_D[6:0]),      // 7 bit Opcode để giải mã
        .funct3       (instr_D[14:12]),    // 3 bit Funct3
        .funct7       (instr_D[31:25]),    // 7 bit Funct7
        .regWrite_D   (regWrite_D),        // Tín hiệu cho phép ghi thanh ghi
        .imm_sel      (imm_sel_D),         // Bộ chọn kiểu mở rộng Immediate
        .alu_srcA_D   (alu_srcA_D),        // Lựa chọn đầu vào A của ALU
        .alu_srcB_D   (alu_srcB_D),        // Lựa chọn đầu vào B của ALU
        .alu_ctrl     (alu_ctrl_D),        // Điều khiển phép toán ALU
        .branch_D     (branch_D),          // Cờ báo hiệu lệnh Nhánh
        .bropcode     (bropcode_D),        // Loại lệnh nhánh (BEQ, BNE...)
        .jump_D       (jump_D),            // Cờ báo hiệu lệnh Nhảy
        .load_sel_D   (load_sel_D),        // Loại dữ liệu Load (B, H, W)
        .store_sel_D  (store_sel_D),       // Loại dữ liệu Store (B, H, W)
        .memWrite_D   (memWrite_D),        // Cho phép ghi RAM
        .write_back_D (write_back_D),      // Nguồn dữ liệu Write Back
        .uses_rs1_D   (uses_rs1_D),        // Báo hiệu lệnh có dùng rs1
        .uses_rs2_D   (uses_rs2_D)         // Báo hiệu lệnh có dùng rs2
    );

    imm_extend imm_gen (
        .instr        (instr_D),           // Toàn bộ 32 bit lệnh
        .imm_sel      (imm_sel_D),         // Tín hiệu chọn kiểu mở rộng
        .imm_ext      (imm_D)              // Dữ liệu mở rộng 32 bit ngõ ra
    );

    Register_File regfile (
        .clk          (clk),               // Xung nhịp hệ thống
        .rst_n        (rst_n),             // Reset hệ thống
        .reg_write    (wb_regWrite),       // Tín hiệu cho phép ghi (từ WB về)
        .rs1          (rs1_D),             // Địa chỉ đọc thanh ghi 1
        .rs2          (rs2_D),             // Địa chỉ đọc thanh ghi 2
        .rd           (wb_rd),             // Địa chỉ ghi thanh ghi (từ WB về)
        .wd           (wb_data),           // Dữ liệu ghi (từ WB về)
        .rd1          (rs1_data_D),        // Dữ liệu ngõ ra 1
        .rd2          (rs2_data_D),        // Dữ liệu ngõ ra 2
        .debug_addr   (check_address[4:0]),// Địa chỉ muốn soi Debug
        .debug_val    (regfile_debug_val)  // Dữ liệu xuất ra Debug
    );

    assign fwd_rs1_data_D = (wb_regWrite && (wb_rd != 5'd0) && (wb_rd == rs1_D)) ? wb_data : rs1_data_D;
    assign fwd_rs2_data_D = (wb_regWrite && (wb_rd != 5'd0) && (wb_rd == rs2_D)) ? wb_data : rs2_data_D;

    ID_EX id_ex_reg (
        .clk          (clk),               // Xung nhịp hệ thống
        .rst_n        (rst_n),             // Reset
        .stall        (stall_id_ex_total), // Đóng băng khi chưa start
        .flush        (flush_id_ex_total), // Xóa lệnh (chèn NOP) do Hazard/Dự đoán sai
        // Nhận từ tầng ID
        .id_pc        (pc_D),              // PC hiện tại
        .id_pc_plus4  (pc4_D),             // PC + 4
        .id_rs1_data  (fwd_rs1_data_D),    // Data rs1 (đã bypass)
        .id_rs2_data  (fwd_rs2_data_D),    // Data rs2 (đã bypass)
        .id_imm       (imm_D),             // Data Imm
        .id_rd        (rd_D),              // Địa chỉ rd
        .id_rs1       (rs1_D),             // Địa chỉ rs1
        .id_rs2       (rs2_D),             // Địa chỉ rs2
        .id_regWrite  (regWrite_D),        // Tín hiệu regWrite
        .id_imm_sel   (imm_sel_D),         // Tín hiệu chọn Imm
        .id_alu_srcA  (alu_srcA_D),        // ALU srcA
        .id_alu_srcB  (alu_srcB_D),        // ALU srcB
        .id_alu_ctrl  (alu_ctrl_D),        // Mã ALU ctrl
        .id_branch    (branch_D),          // Cờ Branch
        .id_bropcode  (bropcode_D),        // Loại Branch
        .id_jump      (jump_D),            // Loại Jump
        .id_load_sel  (load_sel_D),        // Loại Load
        .id_store_sel (store_sel_D),       // Loại Store
        .id_memWrite  (memWrite_D),        // Cờ ghi RAM
        .id_write_back(write_back_D),      // Cờ Write back
        // Xuất sang tầng EX
        .ex_pc        (pc_E),              // PC cho EX
        .ex_pc_plus4  (pc4_E),             // PC+4 cho EX
        .ex_rs1_data  (rs1_data_E),        // Data rs1 cho EX
        .ex_rs2_data  (rs2_data_E),        // Data rs2 cho EX
        .ex_imm       (imm_E),             // Data Imm cho EX
        .ex_rd        (rd_E),              // Đ/c rd cho EX
        .ex_rs1       (rs1_E),             // Đ/c rs1 cho EX (để Forward)
        .ex_rs2       (rs2_E),             // Đ/c rs2 cho EX (để Forward)
        .ex_regWrite  (regWrite_E),        // regWrite qua EX
        .ex_imm_sel   (imm_sel_E),         // imm_sel qua EX
        .ex_alu_srcA  (alu_srcA_E),        // srcA qua EX
        .ex_alu_srcB  (alu_srcB_E),        // srcB qua EX
        .ex_alu_ctrl  (alu_ctrl_E),        // Alu ctrl qua EX
        .ex_branch    (branch_E),          // Cờ Branch qua EX
        .ex_bropcode  (bropcode_E),        // Loại Branch qua EX
        .ex_jump      (jump_E),            // Cờ Jump qua EX
        .ex_load_sel  (load_sel_E),        // Loại Load qua EX
        .ex_store_sel (store_sel_E),       // Loại Store qua EX
        .ex_memWrite  (memWrite_E),        // Cờ ghi RAM qua EX
        .ex_write_back(write_back_E)       // WB qua EX
    );

    // =========================================================================
    // 3. EXECUTE (EX)
    // =========================================================================
    Forwarding_Unit fwd_unit (
        .id_ex_rs1      (rs1_E),           // Đ/c rs1 đang ở EX
        .id_ex_rs2      (rs2_E),           // Đ/c rs2 đang ở EX
        .ex_mem_rd      (mem_rd_M),        // Đ/c rd đang ở MEM
        .ex_mem_regWrite(mem_regWrite_M),  // Lệnh ở MEM có ghi thanh ghi không
        .mem_wb_rd      (wb_rd),           // Đ/c rd đang ở WB
        .mem_wb_regWrite(wb_regWrite),     // Lệnh ở WB có ghi thanh ghi không
        .forwardA       (forwardA),        // Tín hiệu điều khiển Mux A
        .forwardB       (forwardB)         // Tín hiệu điều khiển Mux B
    );

    assign mem_forward_data_M_for_EX = (write_back_M == 2'b10) ? pc4_M : mem_alu_result_M;
    assign ex_rs1_fwd = (forwardA == 2'b01) ? mem_forward_data_M_for_EX : (forwardA == 2'b10) ? wb_data : rs1_data_E;
    assign ex_rs2_fwd = (forwardB == 2'b01) ? mem_forward_data_M_for_EX : (forwardB == 2'b10) ? wb_data : rs2_data_E;

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

    Branch_Prediction_Unit bpu (
        .clk        (clk),                 // Xung nhịp hệ thống
        .rst_n      (rst_n),               // Reset
        .branch_E   (branch_E),            // Lệnh hiện tại ở EX là nhánh
        .jump_E     (is_jump_E),           // Lệnh hiện tại ở EX là nhảy
        .branch     (branch_taken_E),      // Kết quả tính toán thực tế có nhảy không
        .pc_F       (pc_F),                // PC tầng Fetch (để lấy dự đoán)
        .pc_D       (pc_D),                // PC tầng ID
        .pc_E       (pc_E),                // PC tầng EX (để so sánh dự đoán và thực tế)
        .pc_target  (pc_target_E),         // Đ/c đích thực tế tính được tại EX
        .pc_next    (predicted_pc_next_F), // Đ/c dự đoán xuất ra cho PC
        .pc_restore (pc_restore_E),        // Đ/c cần khôi phục nếu đoán sai
        .flush      (bpu_flush_E),         // Báo hiệu đoán sai, yêu cầu Flush Pipeline
        .taken_F    (pred_taken_F)         // Nhánh được dự đoán là Taken
    );

    assign alu_a_E = alu_srcA_E ? pc_E : ex_rs1_fwd;
    assign alu_b_E = alu_srcB_E ? imm_E : ex_rs2_fwd;

    ALU alu_inst (
        .a          (alu_a_E),             // Đầu vào A (PC hoặc rs1)
        .b          (alu_b_E),             // Đầu vào B (rs2 hoặc Imm)
        .alu_ctrl   (alu_ctrl_E),          // Mã phép toán (ADD, SUB...)
        .result     (alu_result_E),        // Kết quả trả về
        .zero       ()                     // (Không dùng do xử lý nhánh riêng)
    );

    EX_MEM ex_mem_reg (
        .clk          (clk),               // Xung nhịp
        .rst_n        (rst_n),             // Reset
        .flush        (1'b0),              // Tầng này không bao giờ bị Flush
        // Nhận từ tầng EX
        .ex_pc_plus4  (pc4_E),             // Nhận PC+4
        .ex_alu_result(alu_result_E),      // Nhận kết quả ALU
        .ex_rs2_data  (ex_rs2_fwd),        // Nhận Data rs2 (để lưu RAM)
        .ex_rd        (rd_E),              // Nhận Đ/c rd
        .ex_regWrite  (regWrite_E),        // Nhận cờ regWrite
        .ex_load_sel  (load_sel_E),        // Nhận mã Load
        .ex_store_sel (store_sel_E),       // Nhận mã Store
        .ex_memWrite  (memWrite_E),        // Nhận cờ ghi RAM
        .ex_write_back(write_back_E),      // Nhận cờ WB
        // Xuất sang tầng MEM
        .mem_pc_plus4  (pc4_M),            // Đẩy PC+4 sang MEM
        .mem_alu_result(mem_alu_result_M), // Đẩy KQ ALU sang MEM (làm đ/c RAM)
        .mem_rs2_data  (rs2_data_M),       // Đẩy Data rs2 sang MEM
        .mem_rd        (mem_rd_M),         // Đẩy Đ/c rd sang MEM
        .mem_regWrite  (mem_regWrite_M),   // Đẩy cờ regWrite sang MEM
        .mem_load_sel  (load_sel_M),       // Đẩy mã Load sang MEM
        .mem_store_sel (store_sel_M),      // Đẩy mã Store sang MEM
        .mem_memWrite  (memWrite_M),       // Đẩy cờ ghi RAM sang MEM
        .mem_write_back(write_back_M)      // Đẩy cờ WB sang MEM
    );

    // =========================================================================
    // 4. MEMORY ACCESS (MEM)
    // =========================================================================
    data_memory dmem (
        .clk          (clk),               // Xung nhịp
        .mem_write    (memWrite_M),        // Cờ cho phép ghi
        .addr         (mem_alu_result_M),  // Đ/c bộ nhớ cần truy cập (từ ALU)
        .write_data   (rs2_data_M),        // Dữ liệu cần ghi vào
        .load_sel     (load_sel_M),        // Định dạng dữ liệu đọc (LB, LH, LW)
        .store_sel    (store_sel_M),       // Định dạng dữ liệu ghi (SB, SH, SW)
        .read_data    (mem_read_data_M),   // Dữ liệu đọc ra
        .debug_addr   (check_address[11:2]),// Địa chỉ muốn soi Debug
        .debug_val    (dmem_debug_val)     // Giá trị trả ra Debug
    );

    MEM_WB mem_wb_reg (
        .clk          (clk),               // Xung nhịp
        .rst_n        (rst_n),             // Reset
        // Nhận từ tầng MEM
        .mem_pc_plus4  (pc4_M),            // Nhận PC+4
        .mem_alu_result(mem_alu_result_M), // Nhận kết quả ALU
        .mem_mem_data  (mem_read_data_M),  // Nhận kết quả đọc RAM
        .mem_rd        (mem_rd_M),         // Nhận Đ/c rd
        .mem_regWrite  (mem_regWrite_M),   // Nhận cờ regWrite
        .mem_write_back(write_back_M),     // Nhận cờ WB
        // Xuất sang tầng WB
        .wb_pc_plus4  (pc4_W),             // Đẩy PC+4 sang WB
        .wb_alu_result(alu_result_W),      // Đẩy KQ ALU sang WB
        .wb_mem_data  (mem_data_W),        // Đẩy KQ đọc RAM sang WB
        .wb_rd        (wb_rd),             // Đẩy Đ/c rd sang WB
        .wb_regWrite  (wb_regWrite),       // Đẩy cờ regWrite sang WB
        .wb_write_back(write_back_W)       // Đẩy cờ WB sang WB
    );

    // =========================================================================
    // 5. WRITE BACK (WB)
    // =========================================================================
    assign wb_data = (write_back_W == 2'b00) ? alu_result_W :
                     (write_back_W == 2'b01) ? mem_data_W :
                     (write_back_W == 2'b10) ? pc4_W : 32'b0;

    // =========================================================================
    // 6. HAZARD, STALL & DEBUG LOGIC
    // =========================================================================
    Hazard_Unit hazard_unit (
        .if_id_rs1          (rs1_D),             // Địa chỉ rs1 ở tầng ID
        .if_id_rs2          (rs2_D),             // Địa chỉ rs2 ở tầng ID
        .if_id_uses_rs1     (uses_rs1_D),        // Lệnh ở ID có dùng rs1 không
        .if_id_uses_rs2     (uses_rs2_D),        // Lệnh ở ID có dùng rs2 không
        .id_ex_rd           (rd_E),              // Đ/c rd của lệnh ở tầng EX
        .id_ex_wb_sel       (write_back_E),      // Lệnh ở EX có phải lệnh Load không (sel == 01)
        .branch_mispredicted(bpu_flush_E),       // Nhận tín hiệu dự đoán nhánh sai
        .stall_pc           (stall_pc_hazard),   // Phát lệnh Stall PC
        .stall_if_id        (stall_if_id_hazard),// Phát lệnh Stall IF/ID
        .flush_id_ex        (flush_id_ex_hazard),// Phát lệnh Flush ID/EX
        .flush_if_id        (flush_if_id_hazard) // Phát lệnh Flush IF/ID
    );

    assign stall_top_load_use = (write_back_M == 2'b01) && (mem_rd_M != 5'd0) && 
                                ((uses_rs1_D && (mem_rd_M == rs1_D)) || (uses_rs2_D && (mem_rd_M == rs2_D)));

    assign stall_pc_total    = stall_pc_hazard | stall_top_load_use | (~start);
    assign stall_if_id_total = stall_if_id_hazard | stall_top_load_use | (~start);
    assign flush_if_id_total = flush_if_id_hazard | bpu_flush_E;
    assign flush_id_ex_total = flush_id_ex_hazard | bpu_flush_E | stall_top_load_use;
    assign stall_id_ex_total = ~start;

    assign value = DataOrReg ? dmem_debug_val : regfile_debug_val;

endmodule
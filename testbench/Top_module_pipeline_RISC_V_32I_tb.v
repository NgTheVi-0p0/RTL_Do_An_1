`timescale 1ns/1ps

module Top_module_pipeline_RISC_V_32I_tb;
    reg clk;
    reg rst_n;
    reg start;
    reg DataOrReg;
    reg [31:0] check_address;
    wire [31:0] value;
    reg [31:0] instruction;
    reg [31:0] address;

    integer error_count;
    integer flush_count;
    
    // Khai báo các thanh ghi giám sát hiệu năng CPU thực tế [1]
    integer total_cycles;
    integer total_branches;

    Top_module_pipeline_RISC_V_32I uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .DataOrReg(DataOrReg),
        .check_address(check_address),
        .value(value),
        .instruction(instruction),
        .address(address)
    );

    // ------------------------------------------------------------------------
    // Tạo xung nhịp hệ thống (Clock - Chu kỳ 10ns)
    // ------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // Khối hàm mã hóa lệnh RV32I (Instruction Encoders)
    // ------------------------------------------------------------------------
    function automatic [31:0] ENC_R;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            ENC_R = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic [31:0] ENC_I;
        input[11:0] imm12;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            ENC_I = {imm12, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic [31:0] ENC_S;
        input[11:0] imm12;
        input [4:0] rs2;
        input[4:0] rs1;
        input [2:0] funct3;
        input[6:0] opcode;
        begin
            ENC_S = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
        end
    endfunction

    function automatic [31:0] ENC_B;
        input integer imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input[2:0] funct3;
        input [6:0] opcode;
        reg[12:0] bimm;
        begin
            bimm = imm[12:0];
            ENC_B = {bimm[12], bimm[10:5], rs2, rs1, funct3, bimm[4:1], bimm[11], opcode};
        end
    endfunction

    function automatic [31:0] ENC_J;
        input integer imm;
        input[4:0] rd;
        input [6:0] opcode;
        reg [20:0] jimm;
        begin
            jimm = imm[20:0];
            ENC_J = {jimm[20], jimm[10:1], jimm[11], jimm[19:12], rd, opcode};
        end
    endfunction

    function automatic[31:0] ENC_U;
        input [19:0] imm20;
        input[4:0] rd;
        input [6:0] opcode;
        begin
            ENC_U = {imm20, rd, opcode};
        end
    endfunction

    // ------------------------------------------------------------------------
    // Các tác vụ hỗ trợ (Helper Tasks)
    // ------------------------------------------------------------------------
    task automatic load_instr;
        input [31:0] addr_i;
        input [31:0] instr_i;
        begin
            @(negedge clk);
            address     = addr_i;
            instruction = instr_i;
        end
    endtask

    task automatic check_equal;
        input [255:0] name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                error_count = error_count + 1;
                $display("  FAIL: %0s | Nhận=0x%08h Mong_Muốn=0x%08h", name, got, exp);
            end else begin
                $display("  PASS: %0s | Giá trị=0x%08h", name, got);
            end
        end
    endtask

    task automatic check_reg_via_debug;
        input [4:0] reg_idx;
        input [31:0] exp;
        input [255:0] name;
        begin
            DataOrReg = 1'b0;
            check_address = {27'b0, reg_idx};
            #1;
            check_equal(name, value, exp);
        end
    endtask

    task automatic check_mem_word_via_debug;
        input [31:0] byte_addr;
        input [31:0] exp;
        input [255:0] name;
        begin
            DataOrReg = 1'b1;
            check_address = byte_addr;
            #1;
            check_equal(name, value, exp);
        end
    endtask

    // Khôi phục hệ thống, xóa sạch bộ nhớ lệnh và tự động reset các biến đếm động [1]
    task automatic reset_and_clear_imem;
        integer k;
        begin
            start          = 1'b0;
            rst_n          = 1'b0;
            flush_count    = 0;
            total_cycles   = 0;
            total_branches = 0;
            @(negedge clk);
            for (k = 0; k < 128; k = k + 1) begin
                address     = k << 2;
                instruction = 32'h0000_0013; // Lệnh NOP
                @(negedge clk);
            end
        end
    endtask

    // Khối giám sát động để đếm số chu kỳ chạy và số lệnh nhảy thực thi trong EX stage [1]
    always @(posedge clk) begin
        if (uut.bpu_flush_E) begin
            flush_count <= flush_count + 1;
        end
        if (start) begin
            total_cycles <= total_cycles + 1;
            if (uut.branch_E) begin
                total_branches <= total_branches + 1;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Chương trình chạy mô phỏng chính
    // ------------------------------------------------------------------------
    integer idx; 

    initial begin
        $dumpfile("mophong_vcd/Top_module_pipeline_RISC_V_32I_tb.vcd");
        $dumpvars(0, Top_module_pipeline_RISC_V_32I_tb);
        for (idx = 0; idx < 32; idx = idx + 1) begin
            $dumpvars(0, Top_module_pipeline_RISC_V_32I_tb.uut.regfile.rf[idx]);
        end

        // Khởi tạo các tín hiệu ban đầu
        rst_n        = 1'b0;
        start        = 1'b0;
        DataOrReg    = 1'b0;
        check_address= 32'b0;
        instruction  = 32'h0000_0013;
        address      = 32'b0;
        error_count  = 0;
        flush_count  = 0;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // ====================================================================
        // PHẦN 1: KIỂM THỬ 37 LỆNH (STANDARD INSTRUCTION SUITE)
        // Kiểm thử độc lập chức năng giải mã và toán học của 37 lệnh RV32I [1]
        // ====================================================================
        $display("\n=================================================");
        $display(" CHẠY PHẦN 1: KIỂM THỬ 37 LỆNH CƠ BẢN (KHÔNG TRÙNG LẶP)");
        $display("=================================================");
        reset_and_clear_imem();

        // Nạp chương trình Phần 1
        load_instr(32'h0000_0000, ENC_I(12'd15, 5'd0, 3'b000, 5'd1, 7'b0010011));   // 0x00: addi x1, x0, 15
        load_instr(32'h0000_0004, ENC_I(12'd3, 5'd0, 3'b000, 5'd2, 7'b0010011));    // 0x04: addi x2, x0, 3
        load_instr(32'h0000_0008, ENC_B(12, 5'd2, 5'd1, 3'b001, 7'b1100011));       // 0x08: bne x1, x2, +12 -> Nhảy vượt qua 2 lệnh tiếp theo tới 0x14
        load_instr(32'h0000_000c, ENC_I(12'd99, 5'd0, 3'b000, 5'd1, 7'b0010011));   // 0x0c: addi x1, x0, 99 (Bị nhảy qua)
        load_instr(32'h0000_0010, ENC_I(12'd99, 5'd0, 3'b000, 5'd2, 7'b0010011));   // 0x10: addi x2, x0, 99 (Bị nhảy qua)
        load_instr(32'h0000_0014, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011));  // 0x14: add x3, x1, x2 (18)
        load_instr(32'h0000_0018, ENC_R(7'b0100000, 5'd2, 5'd1, 3'b000, 5'd4, 7'b0110011));  // 0x18: sub x4, x1, x2 (12)
        load_instr(32'h0000_001c, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b111, 5'd5, 7'b0110011));  // 0x1c: and x5, x1, x2 (3)
        load_instr(32'h0000_0020, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b110, 5'd6, 7'b0110011));  // 0x20: or x6, x1, x2 (15)
        load_instr(32'h0000_0024, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b100, 5'd7, 7'b0110011));  // 0x24: xor x7, x1, x2 (12)
        load_instr(32'h0000_0028, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b001, 5'd8, 7'b0110011));  // 0x28: sll x8, x1, x2 (120)
        load_instr(32'h0000_002c, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b101, 5'd9, 7'b0110011));  // 0x2c: srl x9, x1, x2 (1)
        load_instr(32'h0000_0030, ENC_R(7'b0100000, 5'd2, 5'd1, 3'b101, 5'd10, 7'b0110011)); // 0x30: sra x10, x1, x2 (1)
        load_instr(32'h0000_0034, ENC_R(7'b0000000, 5'd1, 5'd2, 3'b010, 5'd11, 7'b0110011)); // 0x34: slt x11, x2, x1 (1)
        load_instr(32'h0000_0038, ENC_R(7'b0000000, 5'd1, 5'd2, 3'b011, 5'd12, 7'b0110011)); // 0x38: sltu x12, x2, x1 (1)
        load_instr(32'h0000_003c, ENC_U(20'h123, 5'd13, 7'b0110111));                       // 0x3c: lui x13, 0x123 (0x00123000)
        load_instr(32'h0000_0040, ENC_U(20'h1, 5'd14, 7'b0010111));                         // 0x40: auipc x14, 0x1 (0x40 + 0x1000 = 0x00001040)
        load_instr(32'h0000_0044, ENC_I(12'd5, 5'd1, 3'b100, 5'd15, 7'b0010011));           // 0x44: xori x15, x1, 5 (10)
        load_instr(32'h0000_0048, ENC_I(12'd8, 5'd1, 3'b110, 5'd16, 7'b0010011));           // 0x48: ori x16, x1, 8 (15)
        load_instr(32'h0000_004c, ENC_I(12'd4, 5'd1, 3'b111, 5'd17, 7'b0010011));           // 0x4c: andi x17, x1, 4 (4)
        load_instr(32'h0000_0050, ENC_I(12'd2, 5'd1, 3'b001, 5'd18, 7'b0010011));           // 0x50: slli x18, x1, 2 (60)
        load_instr(32'h0000_0054, ENC_I(12'd1, 5'd1, 3'b101, 5'd19, 7'b0010011));           // 0x54: srli x19, x1, 1 (7)
        load_instr(32'h0000_0058, ENC_I(12'hFF0, 5'd0, 3'b000, 5'd20, 7'b0010011));         // 0x58: addi x20, x0, -16
        load_instr(32'h0000_005c, ENC_I({7'b0100000, 5'd2}, 5'd20, 3'b101, 5'd21, 7'b0010011)); // 0x5c: srai x21, x20, 2 (-4)
        load_instr(32'h0000_0060, ENC_I(12'd20, 5'd1, 3'b010, 5'd22, 7'b0010011));          // 0x60: slti x22, x1, 20 (1)
        load_instr(32'h0000_0064, ENC_I(12'd20, 5'd20, 3'b011, 5'd23, 7'b0010011));         // 0x64: sltiu x23, x20, 20 (0)
        load_instr(32'h0000_0068, ENC_I(12'h55, 5'd0, 3'b000, 5'd24, 7'b0010011));          // 0x68: addi x24, x0, 0x55
        load_instr(32'h0000_006c, ENC_S(12'd16, 5'd24, 5'd0, 3'b010, 7'b0100011));          // 0x6c: sw x24, 16(x0)
        load_instr(32'h0000_0070, ENC_I(12'd16, 5'd0, 3'b010, 5'd25, 7'b0000011));          // 0x70: lw x25, 16(x0)
        load_instr(32'h0000_0074, ENC_I(12'h123, 5'd0, 3'b000, 5'd26, 7'b0010011));         // 0x74: addi x26, x0, 0x123
        load_instr(32'h0000_0078, ENC_S(12'd20, 5'd26, 5'd0, 3'b001, 7'b0100011));          // 0x78: sh x26, 20(x0)
        load_instr(32'h0000_007c, ENC_I(12'd20, 5'd0, 3'b001, 5'd27, 7'b0000011));          // 0x7c: lh x27, 20(x0)
        load_instr(32'h0000_0080, ENC_I(12'd20, 5'd0, 3'b101, 5'd28, 7'b0000011));          // 0x80: lhu x28, 20(x0)
        load_instr(32'h0000_0084, ENC_I(12'h7F, 5'd0, 3'b000, 5'd29, 7'b0010011));          // 0x84: addi x29, x0, 0x7F
        load_instr(32'h0000_0088, ENC_S(12'd24, 5'd29, 5'd0, 3'b000, 7'b0100011));          // 0x88: sb x29, 24(x0)
        load_instr(32'h0000_008c, ENC_I(12'd24, 5'd0, 3'b000, 5'd30, 7'b0000011));          // 0x8c: lb x30, 24(x0)
        load_instr(32'h0000_0090, ENC_I(12'd24, 5'd0, 3'b100, 5'd31, 7'b0000011));          // 0x90: lbu x31, 24(x0)
        load_instr(32'h0000_0094, ENC_J(0, 5'd0, 7'b1101111));                              // 0x94: jal x0, 0 (Lặp vô hạn để giữ PC)

        // Bắt đầu chạy CPU
        rst_n = 1'b1;
        repeat (2) @(negedge clk);
        start = 1'b1;
        repeat (60) @(negedge clk);

        // Kiểm tra kết quả Phần 1
        $display("--- THỰC THI KIỂM TRA PHẦN 1 ---");
        check_reg_via_debug(5'd1,  32'd15,          "x1  (addi) = 15");
        check_reg_via_debug(5'd2,  32'd3,           "x2  (addi) = 3");
        check_reg_via_debug(5'd3,  32'd18,          "x3  (add)  = 18");
        check_reg_via_debug(5'd4,  32'd12,          "x4  (sub)  = 12");
        check_reg_via_debug(5'd5,  32'd3,           "x5  (and)  = 3");
        check_reg_via_debug(5'd6,  32'd15,          "x6  (or)   = 15");
        check_reg_via_debug(5'd7,  32'd12,          "x7  (xor)  = 12");
        check_reg_via_debug(5'd8,  32'd120,         "x8  (sll)  = 120");
        check_reg_via_debug(5'd9,  32'd1,           "x9  (srl)  = 1");
        check_reg_via_debug(5'd10, 32'd1,           "x10 (sra)  = 1");
        check_reg_via_debug(5'd11, 32'd1,           "x11 (slt)  = 1");
        check_reg_via_debug(5'd12, 32'd1,           "x12 (sltu) = 1");
        check_reg_via_debug(5'd13, 32'h00123000,    "x13 (lui)  = 0x00123000");
        check_reg_via_debug(5'd14, 32'h00001040,    "x14 (auipc)= 0x00001040");
        check_reg_via_debug(5'd15, 32'd10,          "x15 (xori) = 10");
        check_reg_via_debug(5'd16, 32'd15,          "x16 (ori)  = 15");
        check_reg_via_debug(5'd17, 32'd4,           "x17 (andi) = 4");
        check_reg_via_debug(5'd18, 32'd60,          "x18 (slli) = 60");
        check_reg_via_debug(5'd19, 32'd7,           "x19 (srli) = 7");
        check_reg_via_debug(5'd20, 32'hFFFFFFF0,    "x20 (addi) = -16");
        check_reg_via_debug(5'd21, 32'hFFFFFFFC,    "x21 (srai) = -4");
        check_reg_via_debug(5'd22, 32'd1,           "x22 (slti) = 1");
        check_reg_via_debug(5'd23, 32'd0,           "x23 (sltiu) = 0");
        check_reg_via_debug(5'd25, 32'h55,          "x25 (lw)   = 0x55");
        check_reg_via_debug(5'd27, 32'h123,         "x27 (lh)   = 0x123");
        check_reg_via_debug(5'd28, 32'h123,         "x28 (lhu)  = 0x123");
        check_reg_via_debug(5'd30, 32'h7F,          "x30 (lb)   = 0x7F");
        check_reg_via_debug(5'd31, 32'h7F,          "x31 (lbu)  = 0x7F");


        // ====================================================================
        // PHẦN 2: XỬ LÝ XUNG ĐỘT DỮ LIỆU (DATA HAZARD & FORWARDING)
        // Kiểm tra mạch Forwarding từ EX/MEM và MEM/WB, độ ưu tiên, và Store data [1]
        // ====================================================================
        $display("\n=================================================");
        $display(" CHẠY PHẦN 2: DATA HAZARD & FORWARDING");
        $display("=================================================");
        reset_and_clear_imem();

        // Nạp chương trình Phần 2
        load_instr(32'h0000_0000, ENC_I(12'd5, 5'd0, 3'b000, 5'd1, 7'b0010011));    // 0x00: addi x1, x0, 5
        load_instr(32'h0000_0004, ENC_I(12'd7, 5'd0, 3'b000, 5'd2, 7'b0010011));    // 0x04: addi x2, x0, 7
        load_instr(32'h0000_0008, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011));  // 0x08: add x3, x1, x2 (Simultaneous forwarding: x1 từ MEM/WB, x2 từ EX/MEM) [1]
        load_instr(32'h0000_000c, ENC_R(7'b0000000, 5'd1, 5'd3, 3'b000, 5'd4, 7'b0110011));  // 0x0c: add x4, x3, x1 (EX-to-EX bypass nhanh) [1]
        load_instr(32'h0000_0010, ENC_I(12'd50, 5'd0, 3'b000, 5'd14, 7'b0010011));  // 0x10: addi x14, x0, 50
        load_instr(32'h0000_0014, ENC_I(12'd100, 5'd0, 3'b000, 5'd14, 7'b0010011)); // 0x14: addi x14, x0, 100
        load_instr(32'h0000_0018, ENC_R(7'b0000000, 5'd0, 5'd14, 3'b000, 5'd15, 7'b0110011)); // 0x18: add x15, x14, x0 (Double-forwarding: EX/MEM có 100, MEM/WB có 50. Phải lấy EX/MEM -> x15=100)
        load_instr(32'h0000_001c, ENC_S(12'd32, 5'd15, 5'd0, 3'b010, 7'b0100011));  // 0x1c: sw x15, 32(x0) (Forward trực tiếp kết quả sang Store Data)
        load_instr(32'h0000_0020, ENC_I(12'd32, 5'd0, 3'b010, 5'd16, 7'b0000011));  // 0x20: lw x16, 32(x0)
        load_instr(32'h0000_0024, ENC_J(0, 5'd0, 7'b1101111));                      // 0x24: jal x0, 0

        // Chạy CPU
        rst_n = 1'b1;
        repeat (2) @(negedge clk);
        start = 1'b1;
        repeat (30) @(negedge clk);

        // Kiểm tra kết quả Phần 2
        $display("--- THỰC THI KIỂM TRA PHẦN 2 ---");
        check_reg_via_debug(5'd3,  32'd12,          "x3  (add - forwarding) = 12");
        check_reg_via_debug(5'd4,  32'd17,          "x4  (add - ex_to_ex bypass) = 17");
        check_reg_via_debug(5'd15, 32'd100,         "x15 (add - priority forwarding) = 100");
        check_reg_via_debug(5'd16, 32'd100,         "x16 (lw - store data forwarding) = 100");


        // ====================================================================
        // PHẦN 3: XUNG ĐỘT TRUY XUẤT BỘ NHỚ (LOAD-USE HAZARD & STALL)
        // Kiểm tra mạch Stall chèn bóng khí (Bubble) khi lệnh dùng thanh ghi đích của lệnh LW kề trước [1]
        // ====================================================================
        $display("\n=================================================");
        $display(" CHẠY PHẦN 3: LOAD-USE HAZARD & STALL");
        $display("=================================================");
        reset_and_clear_imem();

        // Nạp chương trình Phần 3
        load_instr(32'h0000_0000, ENC_I(12'd100, 5'd0, 3'b000, 5'd1, 7'b0010011));  // 0x00: addi x1, x0, 100
        load_instr(32'h0000_0004, ENC_S(12'd0, 5'd1, 5'd0, 3'b010, 7'b0100011));    // 0x04: sw x1, 0(x0)
        load_instr(32'h0000_0008, ENC_I(12'd0, 5'd0, 3'b010, 5'd2, 7'b0000011));    // 0x08: lw x2, 0(x0)
        load_instr(32'h0000_000c, ENC_R(7'b0000000, 5'd0, 5'd2, 3'b000, 5'd3, 7'b0110011));  // 0x0c: add x3, x2, x0 (Stall trên rs1) [1]
        load_instr(32'h0000_0010, ENC_I(12'd0, 5'd0, 3'b010, 5'd4, 7'b0000011));    // 0x10: lw x4, 0(x0)
        load_instr(32'h0000_0014, ENC_R(7'b0000000, 5'd4, 5'd0, 3'b000, 5'd5, 7'b0110011));  // 0x14: add x5, x0, x4 (Stall trên rs2) [1]
        load_instr(32'h0000_0018, ENC_J(0, 5'd0, 7'b1101111));                      // 0x18: jal x0, 0

        // Chạy CPU
        rst_n = 1'b1;
        repeat (2) @(negedge clk);
        start = 1'b1;
        repeat (30) @(negedge clk);

        // Kiểm tra kết quả Phần 3
        $display("--- THỰC THI KIỂM TRA PHẦN 3 ---");
        check_reg_via_debug(5'd3,  32'd100,         "x3  (add - load-use rs1 stall) = 100");
        check_reg_via_debug(5'd5,  32'd100,         "x5  (add - load-use rs2 stall) = 100");


        // ====================================================================
        // PHẦN 4: XUNG ĐỘT LUỒNG ĐIỀU KHIỂN (CONTROL HAZARD & FLUSH)
        // Kiểm tra cơ chế Flush (Xóa bỏ lệnh rác nạp sai) của các lệnh nhảy JAL, JALR và Rẽ nhánh [1]
        // ====================================================================
        $display("\n=================================================");
        $display(" CHẠY PHẦN 4: CONTROL HAZARD & FLUSH");
        $display("=================================================");
        reset_and_clear_imem();

        // Nạp chương trình Phần 4
        load_instr(32'h0000_0000, ENC_I(12'd5, 5'd0, 3'b000, 5'd1, 7'b0010011));    // 0x00: addi x1, x0, 5
        load_instr(32'h0000_0004, ENC_I(12'd5, 5'd0, 3'b000, 5'd2, 7'b0010011));    // 0x04: addi x2, x0, 5
        load_instr(32'h0000_0008, ENC_B(12, 5'd2, 5'd1, 3'b000, 7'b1100011));       // 0x08: beq x1, x2, +12 -> Nhảy đến 0x14. Flushes tiếp theo [1]
        load_instr(32'h0000_000c, ENC_I(12'd99, 5'd0, 3'b000, 5'd3, 7'b0010011));   // 0x0c: addi x3, x0, 99 (Bị xóa - Flush) [1]
        load_instr(32'h0000_0010, ENC_I(12'd99, 5'd0, 3'b000, 5'd3, 7'b0010011));   // 0x10: addi x3, x0, 99 (Bị xóa - Flush) [1]
        load_instr(32'h0000_0014, ENC_I(12'd48, 5'd0, 3'b000, 5'd8, 7'b0010011));   // 0x14: addi x8, x0, 48 (0x30)
        load_instr(32'h0000_0018, ENC_J(12, 5'd9, 7'b1101111));                     // 0x18: jal x9, +12 -> Nhảy tới 0x24. Lưu PC+4 (0x1c) vào x9 [1]
        load_instr(32'h0000_001c, ENC_I(12'd99, 5'd0, 3'b000, 5'd10, 7'b0010011));  // 0x1c: addi x10, x0, 99 (Bị xóa - Flush) [1]
        load_instr(32'h0000_0020, ENC_I(12'd99, 5'd0, 3'b000, 5'd10, 7'b0010011));  // 0x20: addi x10, x0, 99 (Bị xóa - Flush) [1]
        load_instr(32'h0000_0024, ENC_I(12'd0, 5'd8, 3'b000, 5'd12, 7'b1100111));   // 0x24: jalr x12, x8, 0 -> Nhảy tới x8 (0x30). Lưu PC+4 (0x28) vào x12 [1]
        load_instr(32'h0000_0028, ENC_I(12'd99, 5'd0, 3'b000, 5'd13, 7'b0010011));  // 0x28: addi x13, x0, 99 (Bị xóa - Flush) [1]
        load_instr(32'h0000_002c, ENC_I(12'd99, 5'd0, 3'b000, 5'd13, 7'b0010011));  // 0x2c: addi x13, x0, 99 (Bị xóa - Flush) [1]
        load_instr(32'h0000_0030, ENC_I(12'd77, 5'd0, 3'b000, 5'd14, 7'b0010011));  // 0x30: addi x14, x0, 77
        load_instr(32'h0000_0034, ENC_J(0, 5'd0, 7'b1101111));                      // 0x34: jal x0, 0

        // Chạy CPU
        rst_n = 1'b1;
        repeat (2) @(negedge clk);
        start = 1'b1;
        repeat (30) @(negedge clk);

        // Kiểm tra kết quả Phần 4
        $display("--- THỰC THI KIỂM TRA PHẦN 4 ---");
        check_reg_via_debug(5'd3,  32'd0,           "x3  (flushed beq instruction must be 0) = 0");
        check_reg_via_debug(5'd8,  32'd48,          "x8  (addi) = 48");
        check_reg_via_debug(5'd9,  32'h0000001c,    "x9  (jal link address PC+4) = 0x0000001c");
        check_reg_via_debug(5'd10, 32'd0,           "x10 (flushed jal instruction must be 0) = 0");
        check_reg_via_debug(5'd12, 32'h00000028,    "x12 (jalr link address PC+4) = 0x00000028");
        check_reg_via_debug(5'd13, 32'd0,           "x13 (flushed jalr instruction must be 0) = 0");
        check_reg_via_debug(5'd14, 32'd77,          "x14 (jalr target instruction) = 77");


        // ====================================================================
        // PHẦN 5: HUẤN LUYỆN BỘ DỰ ĐOÁN NHÁNH (BPU / PHT / GHR LOOP)
        // Vòng lặp lồng nhau 4 tầng (limit = 4) - Đánh giá chi tiết hiệu suất BPU [1]
        // ====================================================================
        $display("\n=================================================");
        $display(" CHẠY PHẦN 5: BPU / PHT / GHR LOOP (VÒNG LẶP LỒNG 4 TẦNG)");
        $display("=================================================");
        reset_and_clear_imem();

        // Nạp chương trình Phần 5 (4 Vòng lặp lồng nhau)
        load_instr(32'h0000_0000, ENC_I(12'd0,  5'd0, 3'b000, 5'd1, 7'b0010011));  // 0x00: addi x1, x0, 0     (count = 0)
        load_instr(32'h0000_0004, ENC_I(12'd10,  5'd0, 3'b000, 5'd6, 7'b0010011));  // 0x04: addi x6, x0, 10     (limit = 10)
        load_instr(32'h0000_0008, ENC_I(12'd0,  5'd0, 3'b000, 5'd2, 7'b0010011));  // 0x08: addi x2, x0, 0     (i = 0)
        load_instr(32'h0000_000c, ENC_I(12'd0,  5'd0, 3'b000, 5'd3, 7'b0010011));  // 0x0C: addi x3, x0, 0     (j = 0) - [L_j_start]
        load_instr(32'h0000_0010, ENC_I(12'd0,  5'd0, 3'b000, 5'd4, 7'b0010011));  // 0x10: addi x4, x0, 0     (k = 0) - [L_k_start]
        load_instr(32'h0000_0014, ENC_I(12'd0,  5'd0, 3'b000, 5'd5, 7'b0010011));  // 0x14: addi x5, x0, 0     (l = 0) - [L_l_start]
        load_instr(32'h0000_0018, ENC_B(16,     5'd3, 5'd2, 3'b001, 7'b1100011));  // 0x18: bne x2, x3, 16     (Nếu i != j, nhảy tới skip_inc)
        load_instr(32'h0000_001c, ENC_B(12,     5'd4, 5'd3, 3'b001, 7'b1100011));  // 0x1C: bne x3, x4, 12     (Nếu j != k, nhảy tới skip_inc)
        load_instr(32'h0000_0020, ENC_B(8,      5'd5, 5'd4, 3'b001, 7'b1100011));  // 0x20: bne x4, x5, 8      (Nếu k != l, nhảy tới skip_inc)
        load_instr(32'h0000_0024, ENC_I(12'd1,  5'd1, 3'b000, 5'd1, 7'b0010011));  // 0x24: addi x1, x1, 1     (count++)
        load_instr(32'h0000_0028, ENC_I(12'd1,  5'd5, 3'b000, 5'd5, 7'b0010011));  // 0x28: addi x5, x5, 1     - [skip_inc] (l++)
        load_instr(32'h0000_002c, ENC_B(-20,    5'd6, 5'd5, 3'b100, 7'b1100011));  // 0x2C: blt x5, x6, -20    (Nếu l < limit, quay lại 0x18) [Đã sửa]
        load_instr(32'h0000_0030, ENC_I(12'd1,  5'd4, 3'b000, 5'd4, 7'b0010011));  // 0x30: addi x4, x4, 1     (k++)
        load_instr(32'h0000_0034, ENC_B(-32,    5'd6, 5'd4, 3'b100, 7'b1100011));  // 0x34: blt x4, x6, -32    (Nếu k < limit, quay lại L_l_start ở 0x14) [Đã sửa]
        load_instr(32'h0000_0038, ENC_I(12'd1,  5'd3, 3'b000, 5'd3, 7'b0010011));  // 0x38: addi x3, x3, 1     (j++)
        load_instr(32'h0000_003c, ENC_B(-44,    5'd6, 5'd3, 3'b100, 7'b1100011));  // 0x3C: blt x3, x6, -44    (Nếu j < limit, quay lại L_k_start ở 0x10) [Đã sửa]
        load_instr(32'h0000_0040, ENC_I(12'd1,  5'd2, 3'b000, 5'd2, 7'b0010011));  // 0x40: addi x2, x2, 1     (i++)
        load_instr(32'h0000_0044, ENC_B(-56,    5'd6, 5'd2, 3'b100, 7'b1100011));  // 0x44: blt x2, x6, -56    (Nếu i < limit, quay lại L_j_start ở 0x0C)
        load_instr(32'h0000_0048, ENC_J(0,      5'd0, 7'b1101111));                // 0x48: jal x0, 0          (Lặp vô hạn để kết thúc chương trình)

        // Bắt đầu chạy CPU (Tăng chu kỳ chạy mô phỏng để hoàn thành 256 lần lặp con)
        rst_n = 1'b1;
        repeat (2) @(negedge clk);
        start = 1'b1;
        repeat (50000) @(negedge clk);

        // Kiểm tra kết quả Phần 5 (x1 mong đợi = 10 khi limit = 10) [1]
        $display("--- THỰC THI KIỂM TRA PHẦN 5 ---");
        check_reg_via_debug(5'd1, 32'd10,            "x1 (count of nested loops) = 10");

        if (flush_count == 0) begin
            error_count = error_count + 1;
            $display("  FAIL: Không ghi nhận bất kỳ sự kiện flush nhánh nào từ BPU!");
        end else begin
            $display("  PASS: Đã ghi nhận tổng số lần flush pipeline của BPU = %0d", flush_count);
        end

        // --- ĐÁNH GIÁ VÀ IN CHI TIẾT TỶ LỆ MÔ PHỎNG HIỆU SUẤT BPU --- [1]
        begin : print_bpu_metrics
            real misprediction_rate;
            real bpu_accuracy;
            real flush_rate_cycles;
            
            // Chuyển đổi kiểu dữ liệu Integer sang Real để tính toán phần trăm chính xác [1]
            misprediction_rate = (total_branches > 0) ? ($itor(flush_count) / $itor(total_branches)) * 100.0 : 0.0;
            bpu_accuracy       = 100.0 - misprediction_rate;

            $display("\n=================== BPU PERFORMANCE METRICS (PHẦN 5) ===================");
            $display("  - Tổng số chu kỳ CPU hoạt động (Total Active Cycles)   : %0d", total_cycles);
            $display("  - Tổng số lệnh rẽ nhánh được nạp (Branches Evaluated)  : %0d", total_branches);
            $display("  - Số Flush do đoán sai (Pipeline Flushes)              : %0d", flush_count);
            $display("  - Tỷ lệ đoán sai (Branch Misprediction Rate)           : %0.2f%%", misprediction_rate);
            $display("  - Tỷ lệ đoán đúng (BPU Prediction Accuracy)            : %0.2f%%", bpu_accuracy);
            $display("========================================================================\n");
        end


        // ====================================================================
        // BÁO CÁO TỔNG HỢP KIỂM THỬ CUỐI CÙNG
        // ====================================================================
        $display("\n=================================================");
        if (error_count == 0) begin
            $display(" KẾT QUẢ: TOÀN BỘ 5 PHẦN KIỂM THỬ ĐÃ ĐẠT TIÊU CHUẨN!");
            $display("  Hệ thống xử lý pipeline không phát sinh lỗi.");
        end else begin
            $display(" KẾT QUẢ: PHÁT SINH LỖI TRONG QUÁ TRÌNH KIỂM THỬ!");
            $display("  Tổng số lỗi ghi nhận: error_count = %0d", error_count);
        end
        $display("=================================================");

        $finish;
    end
endmodule
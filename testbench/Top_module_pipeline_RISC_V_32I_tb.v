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

    // -----------------------------
    // Clock
    // -----------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -----------------------------
    // Instruction encoders (RV32I)
    // -----------------------------
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

    // MỚI: Bổ sung bộ mã hóa lệnh U-Type (cho LUI, AUIPC)
    function automatic[31:0] ENC_U;
        input [19:0] imm20;
        input[4:0] rd;
        input [6:0] opcode;
        begin
            ENC_U = {imm20, rd, opcode};
        end
    endfunction

    // -----------------------------
    // Helpers
    // -----------------------------
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
                $display("FAIL: %0s | got=0x%08h exp=0x%08h", name, got, exp);
            end else begin
                $display("PASS: %0s | value=0x%08h", name, got);
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

    always @(posedge clk) begin
        if (uut.bpu_flush_E) begin
            flush_count <= flush_count + 1;
        end
    end

    // -----------------------------
    // Main test
    // -----------------------------
    initial begin
        $dumpfile("mophong_vcd/Top_module_pipeline_RISC_V_32I_tb.vcd");
        $dumpvars(0, Top_module_pipeline_RISC_V_32I_tb);
        $monitor("t=%0t clk=%b rst_n=%b start=%b pc_F=%h instr_F=%h value=%h flush=%b",
                 $time, clk, rst_n, start, uut.pc_F, uut.instr_F, value, uut.bpu_flush_E);

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

        // ============================================================================
        // --- PHẦN 1: DATA HAZARD (FORWARDING) ---
        // Kiểm tra xem forwarding có hoạt động đúng khi có dependencies giữa các lệnh
        // ============================================================================
        load_instr(32'h0000_0000, ENC_I(12'd5,   5'd0, 3'b000, 5'd1, 7'b0010011)); // 0x00: addi x1,x0,5 (x1 = 5)
        load_instr(32'h0000_0004, ENC_I(12'd7,   5'd0, 3'b000, 5'd2, 7'b0010011)); // 0x04: addi x2,x0,7 (x2 = 7)
        load_instr(32'h0000_0008, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011)); // 0x08: add x3,x1,x2 (x3 = 12) [Forwarded: x1, x2]
        load_instr(32'h0000_000c, ENC_R(7'b0000000, 5'd1, 5'd3, 3'b000, 5'd4, 7'b0110011)); // 0x0C: add x4,x3,x1 (x4 = 17) [Forwarded: x3]
        
        // ============================================================================
        // --- PHẦN 2: LOAD-USE HAZARD (STALL) ---
        // Kiểm tra xem CPU có stall đúng khi có Load-Use conflict
        // ============================================================================
        load_instr(32'h0000_0010, ENC_I(12'd100, 5'd0, 3'b000, 5'd10,7'b0010011)); // 0x10: addi x10,x0,100 (x10 = 100)
        load_instr(32'h0000_0014, ENC_S(12'd0,   5'd10,5'd0, 3'b010, 7'b0100011)); // 0x14: sw x10,0(x0) (Mem[0] = 100)
        load_instr(32'h0000_0018, ENC_I(12'd0,   5'd0, 3'b010, 5'd5, 7'b0000011)); // 0x18: lw x5,0(x0) (x5 = 100 từ Mem[0])
        load_instr(32'h0000_001c, ENC_R(7'b0000000, 5'd1, 5'd5, 3'b000, 5'd6, 7'b0110011)); // 0x1C: add x6,x5,x1 (x6 = 105) [STALL here, must wait for x5]
        
        // ============================================================================
        // --- PHẦN 3: CONTROL HAZARD (PC CORRECTION & FLUSH) ---
        // Kiểm tra xem CPU có flush đúng khi branch prediction sai
        // ============================================================================
        // BEQ test: Nếu x6==x6 -> Taken (Nhảy tới +8)
        load_instr(32'h0000_0020, ENC_B(8,       5'd6, 5'd6, 3'b000, 7'b1100011)); // 0x20: beq x6,x6,+8
        load_instr(32'h0000_0024, ENC_I(12'd99,  5'd0, 3'b000, 5'd0, 7'b0010011)); // 0x24: addi x0,x0,99 (Bị FLUSH)
        
        // Đích nhảy của BEQ (0x20 + 8 = 0x28)
        load_instr(32'h0000_0028, ENC_I(12'd64,  5'd0, 3'b000, 5'd8, 7'b0010011)); // 0x28: addi x8,x0,64 (x8 = 64)
        
        // JAL test: Unconditional jump (luôn nhảy)
        load_instr(32'h0000_002C, ENC_J(8,       5'd9, 7'b1101111));               // 0x2C: jal x9,+8 (x9 = 0x30, Nhảy tới 0x34)
        load_instr(32'h0000_0030, ENC_I(12'd77,  5'd0, 3'b000, 5'd11,7'b0010011)); // 0x30: addi x11,x0,77 (Bị FLUSH)
        
        // Đích nhảy của JAL (0x2C + 8 = 0x34)
        load_instr(32'h0000_0034, ENC_I(12'd0,   5'd8, 3'b000, 5'd12,7'b1100111)); // 0x34: jalr x12,x8,0 (x12 = 0x38, Nhảy tới x8=64)
        load_instr(32'h0000_0038, ENC_I(12'd88,  5'd0, 3'b000, 5'd13,7'b0010011)); // 0x38: addi x13,x0,88 (Bị FLUSH)
        
        // Đích của JALR (0x40 = 64 - PC offset adjustment)
        load_instr(32'h0000_003C, ENC_I(12'd88,  5'd0, 3'b000, 5'd13,7'b0010011)); // 0x3C: nop (Bị FLUSH)
        load_instr(32'h0000_0040, ENC_B(8,       5'd2, 5'd1, 3'b001, 7'b1100011)); // 0x40: bne x1,x2,+8 (x1=5, x2=7, 5!=7 -> Nhảy tới 0x48)
        load_instr(32'h0000_0044, ENC_I(12'd11,  5'd0, 3'b000, 5'd14,7'b0010011)); // 0x44: addi x14,x0,11 (Bị FLUSH)
        
        // ============================================================================
        // --- PHẦN 4: BRANCH PREDICTION UNIT (PHT & GHR) ---
        // Kiểm tra Branch Prediction Unit hoạt động đúng:
        //   - PHT (Pattern History Table) lưu trữ 2-bit predictor cho mỗi branch
        //   - GHR (Global History Register) theo dõi lịch sử của các branch
        // ============================================================================
        
        // Nhảy tới 0x48 (từ BNE)
        load_instr(32'h0000_0048, ENC_U(20'h12345, 5'd15, 7'b0110111));            // 0x48: lui x15, 0x12345 (x15 = 0x12345000)
        
        // Vòng lặp branch để kiểm tra Branch Prediction Unit:
        //   - lệnh BEQ được thực hiện nhiều lần
        //   - branch sẽ Not-Taken khi counter = 0, kiểm tra PHT/GHR thay đổi trạng thái
        load_instr(32'h0000_004C, ENC_I(12'd3, 5'd0, 3'b000, 5'd13, 7'b0010011)); // 0x4C: addi x13,x0,3 (loop counter)
        load_instr(32'h0000_0050, ENC_B(12, 5'd13, 5'd0, 3'b000, 7'b1100011));     // 0x50: beq x13,x0,+12 (exit khi x13 == 0)
        load_instr(32'h0000_0054, ENC_I(12'hFFF, 5'd13, 3'b000, 5'd13, 7'b0010011)); // 0x54: addi x13,x13,-1
        load_instr(32'h0000_0058, ENC_J(-8, 5'd0, 7'b1101111));                  // 0x58: jal x0,-8 (về 0x50)
        load_instr(32'h0000_005C, ENC_I(12'd11, 5'd0, 3'b000, 5'd14, 7'b0010011)); // 0x5C: addi x14,x0,11 (exit path)

        // Additional branch pattern: alternating Taken / Not-Taken to exercise PHT 2-bit states
        load_instr(32'h0000_0060, ENC_B(8,  5'd1, 5'd0, 3'b001, 7'b1100011)); // 0x60: bne x1,x0,+8  (Taken)
        load_instr(32'h0000_0064, ENC_B(-8, 5'd1, 5'd2, 3'b001, 7'b1100011)); // 0x64: bne x1,x2,-8  (Not-Taken)
        load_instr(32'h0000_0068, ENC_B(8,  5'd1, 5'd0, 3'b001, 7'b1100011)); // 0x68: bne x1,x0,+8  (Taken)
        
        // Thêm các operation khác để kiểm tra R-type và I-type
        load_instr(32'h0000_006C, ENC_I(12'd2, 5'd1, 3'b001, 5'd20, 7'b0010011)); // 0x6C: slli x20, x1, 2 (5 << 2 = 20)
        load_instr(32'h0000_0070, ENC_I(12'd1, 5'd20,3'b101, 5'd21, 7'b0010011)); // 0x70: srli x21, x20, 1 (20 >> 1 = 10)
        load_instr(32'h0000_0074, ENC_I(12'hFF8, 5'd0, 3'b000, 5'd22, 7'b0010011)); // 0x74: addi x22, x0, -8
        load_instr(32'h0000_0078, ENC_I({7'b0100000, 5'd00001}, 5'd22, 3'b101, 5'd23, 7'b0010011)); // 0x78: srai x23, x22, 1 (-4)
        load_instr(32'h0000_007C, ENC_I(12'd10,  5'd1, 3'b010, 5'd24, 7'b0010011)); // 0x7C: slti x24, x1, 10 (1)
        load_instr(32'h0000_0080, ENC_I(12'd10,  5'd22,3'b011, 5'd25, 7'b0010011)); // 0x80: sltiu x25, x22, 10 (0)
        
        load_instr(32'h0000_0084, ENC_R(7'b0100000, 5'd1, 5'd3, 3'b000, 5'd26, 7'b0110011)); // 0x84: sub x26, x3, x1 (7)
        load_instr(32'h0000_0088, ENC_I(12'd3,   5'd0, 3'b000, 5'd27, 7'b0010011));          // 0x88: addi x27, x0, 3
        load_instr(32'h0000_008C, ENC_R(7'b0000000, 5'd27, 5'd1, 3'b001, 5'd27, 7'b0110011)); // 0x8C: sll x27, x1, x27 (40)
        load_instr(32'h0000_0090, ENC_R(7'b0000000, 5'd1, 5'd22, 3'b010, 5'd28, 7'b0110011)); // 0x90: slt x28, x22, x1 (1)
        load_instr(32'h0000_0094, ENC_R(7'b0000000, 5'd1, 5'd22, 3'b011, 5'd29, 7'b0110011)); // 0x94: sltu x29, x22, x1 (0)
        
        load_instr(32'h0000_0098, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b100, 5'd30, 7'b0110011)); // 0x98: xor x30, x1, x2 (2)
        load_instr(32'h0000_009C, ENC_I(12'd1,   5'd0, 3'b000, 5'd31, 7'b0010011));          // 0x9C: addi x31, x0, 1
        load_instr(32'h0000_00A0, ENC_R(7'b0000000, 5'd31, 5'd20, 3'b101, 5'd31, 7'b0110011)); // 0xA0: srl x31, x20, x31 (10)
        
        // LOAD/STORE operations
        load_instr(32'h0000_00A4, ENC_U(20'hABCD8, 5'd8, 7'b0110111));            // 0xA4: lui x8, 0xABCD8
        load_instr(32'h0000_00A8, ENC_I(12'h765, 5'd8, 3'b000, 5'd8, 7'b0010011));// 0xA8: addi x8, x8, 0x765
        load_instr(32'h0000_00AC, ENC_S(12'd32,  5'd8, 5'd0, 3'b010, 7'b0100011));// 0xAC: sw x8, 32(x0)
        
        load_instr(32'h0000_00B0, ENC_I(12'd32,  5'd0, 3'b000, 5'd9, 7'b0000011));// 0xB0: lb x9, 32(x0)
        load_instr(32'h0000_00B4, ENC_I(12'd32,  5'd0, 3'b001, 5'd10,7'b0000011));// 0xB4: lh x10, 32(x0)
        load_instr(32'h0000_00B8, ENC_I(12'd33,  5'd0, 3'b100, 5'd11,7'b0000011));// 0xB8: lbu x11, 33(x0)
        load_instr(32'h0000_00BC, ENC_I(12'd34,  5'd0, 3'b101, 5'd12,7'b0000011));// 0xBC: lhu x12, 34(x0)
        
        load_instr(32'h0000_00C0, ENC_I(12'hFFB, 5'd0, 3'b000, 5'd13,7'b0010011));// 0xC0: addi x13, x0, -5
        load_instr(32'h0000_00C4, ENC_I(12'd5,   5'd0, 3'b000, 5'd14,7'b0010011));// 0xC4: addi x14, x0, 5
        
        load_instr(32'h0000_00C8, ENC_B(8, 5'd14,5'd13,3'b100, 7'b1100011));      // 0xC8: blt x13, x14, +8
        load_instr(32'h0000_00CC, ENC_I(12'd0, 5'd0, 3'b000, 5'd0, 7'b0010011));  // 0xCC: nop (Bị bỏ qua)
        
        load_instr(32'h0000_00D0, ENC_B(8, 5'd13,5'd14,3'b101, 7'b1100011));      // 0xD0: bge x14, x13, +8
        load_instr(32'h0000_00D4, ENC_I(12'd0, 5'd0, 3'b000, 5'd0, 7'b0010011));  // 0xD4: nop (Bị bỏ qua)
        
        load_instr(32'h0000_00D8, ENC_B(8, 5'd13,5'd14,3'b110, 7'b1100011));      // 0xD8: bltu x14, x13, +8
        load_instr(32'h0000_00DC, ENC_I(12'd0, 5'd0, 3'b000, 5'd0, 7'b0010011));  // 0xDC: nop (Bị bỏ qua)
        
        load_instr(32'h0000_00E0, ENC_B(8, 5'd14,5'd13,3'b111, 7'b1100011));      // 0xE0: bgeu x13, x14, +8
        load_instr(32'h0000_00E4, ENC_I(12'd0, 5'd0, 3'b000, 5'd0, 7'b0010011));  // 0xE4: nop (Bị bỏ qua)
        
        load_instr(32'h0000_00E8, ENC_J(0, 5'd0, 7'b1101111));                    // 0xE8: jal x0,0 (Vòng lặp vô hạn)

        // Bắt đầu chạy CPU
        @(negedge clk);
        start = 1'b1;

        // Cho phép CPU đủ thời gian chạy qua hơn 60 lệnh + chu kỳ Flush
        repeat (180) @(negedge clk);

        // KIỂM TRA TRẠNG THÁI CỦA 31 THANH GHI
        $display("--- CHECKING REGISTERS ---");
        check_reg_via_debug(5'd0,  32'd0,          "x0  must remain zero");
        check_reg_via_debug(5'd1,  32'd5,          "x1  (addi) = 5");
        check_reg_via_debug(5'd2,  32'd7,          "x2  (addi) = 7");
        check_reg_via_debug(5'd3,  32'd12,         "x3  (add)  = 12");
        check_reg_via_debug(5'd4,  32'd17,         "x4  (add)  = 17");
        check_reg_via_debug(5'd5,  32'hFFFFFFFE,   "x5  (sra)  = -2");
        check_reg_via_debug(5'd6,  32'd7,          "x6  (or)   = 7");
        check_reg_via_debug(5'd7,  32'd5,          "x7  (and)  = 5");
        check_reg_via_debug(5'd8,  32'hABCD8765,   "x8  (lui+addi) = 0xABCD8765");
        check_reg_via_debug(5'd9,  32'h00000065,   "x9  (lb)   = 0x00000065 (Sign extended byte)");
        check_reg_via_debug(5'd10, 32'hFFFF8765,   "x10 (lh)   = 0xFFFF8765 (Sign extended halfword)");
        check_reg_via_debug(5'd11, 32'h00000087,   "x11 (lbu)  = 0x00000087 (Zero extended byte)");
        check_reg_via_debug(5'd12, 32'h0000ABCD,   "x12 (lhu)  = 0x0000ABCD (Zero extended halfword)");
        check_reg_via_debug(5'd13, 32'hFFFFFFFB,   "x13 (addi) = -5");
        check_reg_via_debug(5'd14, 32'd5,          "x14 (addi) = 5");
        check_reg_via_debug(5'd15, 32'h12345000,   "x15 (lui)  = 0x12345000");
        check_reg_via_debug(5'd16, 32'h0100004C,   "x16 (auipc)= PC + 0x01000000");
        check_reg_via_debug(5'd17, 32'd10,         "x17 (xori) = 10");
        check_reg_via_debug(5'd18, 32'd13,         "x18 (ori)  = 13");
        check_reg_via_debug(5'd19, 32'd4,          "x19 (andi) = 4");
        check_reg_via_debug(5'd20, 32'd20,         "x20 (slli) = 20");
        check_reg_via_debug(5'd21, 32'd10,         "x21 (srli) = 10");
        check_reg_via_debug(5'd22, 32'hFFFFFFF8,   "x22 (addi) = -8");
        check_reg_via_debug(5'd23, 32'hFFFFFFFC,   "x23 (srai) = -4");
        check_reg_via_debug(5'd24, 32'd1,          "x24 (slti) = 1 (True)");
        check_reg_via_debug(5'd25, 32'd0,          "x25 (sltiu)= 0 (False)");
        check_reg_via_debug(5'd26, 32'd7,          "x26 (sub)  = 7");
        check_reg_via_debug(5'd27, 32'd40,         "x27 (sll)  = 40");
        check_reg_via_debug(5'd28, 32'd1,          "x28 (slt)  = 1 (True)");
        check_reg_via_debug(5'd29, 32'd0,          "x29 (sltu) = 0 (False)");
        check_reg_via_debug(5'd30, 32'd2,          "x30 (xor)  = 2");
        check_reg_via_debug(5'd31, 32'd10,         "x31 (srl)  = 10");

        if (flush_count == 0) begin
            error_count = error_count + 1;
            $display("FAIL: No branch flush observed!");
        end else begin
            $display("PASS: Observed branch flush count = %0d", flush_count);
        end

        if (error_count == 0) begin
            $display("============================================");
            $display("PERFECT: ALL 37 INSTRUCTIONS PASSED!");
            $display("============================================");
        end else begin
            $display("============================================");
            $display("FAILED: error_count = %0d", error_count);
            $display("============================================");
        end

        $finish;
    end
endmodule
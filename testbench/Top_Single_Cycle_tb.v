`timescale 1ns/1ps

module Top_Single_Cycle_tb;
    reg clk;
    reg rst_n;
    reg start;
    reg inst_we;
    reg [31:0] inst_addr;
    reg [31:0] inst_data;
    wire [31:0] pc;
    wire [31:0] instr;

    Top_Single_Cycle uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .inst_we(inst_we),
        .inst_addr(inst_addr),
        .inst_data(inst_data),
        .pc(pc),
        .instr(instr)
    );
    task dump_registers;
        integer j;
        begin
            $display("\n=== REGISTER FILE DUMP ===");
            for (j = 0; j < 32; j = j + 1) begin
                $display("x%0d = %h", j, uut.regfile.rf[j]);
            end
            $display("==========================\n");
        end
    endtask
    initial begin
        $dumpfile("mophong_vcd/Top_Single_Cycle_tb.vcd");
        $dumpvars(0, Top_Single_Cycle_tb);

        clk = 0;
        rst_n = 0;
        start = 0;
        inst_we = 0;
        inst_addr = 32'h0000_0000;
        inst_data = 32'h0000_0000;

        #10 rst_n = 1;

        // Load program into instruction memory while CPU is not started
    // NẠP CHƯƠNG TRÌNH TEST ĐỦ 37 LỆNH RISC-V
    // NẠP CHƯƠNG TRÌNH TEST 37 LỆNH RISC-V (CHUẨN ABI REGISTER)
    inst_we = 1;

    // --- NHÓM 1: KHỞI TẠO HẰNG SỐ (I-Type ALU) - 9 lệnh ---
    #10 inst_addr = 32'h00; inst_data = 32'h00a00293; // 19. addi t0, zero, 10   (x5 = 10)
    #10 inst_addr = 32'h04; inst_data = 32'h00502313; // 20. slti t1, zero, 5    (x6 = 0)
    #10 inst_addr = 32'h08; inst_data = 32'h00f03393; // 21. sltiu t2, zero, 15  (x7 = 1)
    #10 inst_addr = 32'h0C; inst_data = 32'h0032c413; // 22. xori s0, t0, 3      (x8 = 9)
    #10 inst_addr = 32'h10; inst_data = 32'h00746493; // 23. ori s1, s0, 7       (x9 = 15)
    #10 inst_addr = 32'h14; inst_data = 32'h00f4f513; // 24. andi a0, s1, 15     (x10 = 15)
    #10 inst_addr = 32'h18; inst_data = 32'h00129593; // 25. slli a1, t0, 1      (x11 = 20)
    #10 inst_addr = 32'h1C; inst_data = 32'h0015d613; // 26. srli a2, a1, 1      (x12 = 10)
    #10 inst_addr = 32'h20; inst_data = 32'h4015d693; // 27. srai a3, a1, 1      (x13 = 10)

    // --- NHÓM 2: TÍNH TOÁN THANH GHI (R-Type ALU) - 10 lệnh ---
    #10 inst_addr = 32'h24; inst_data = 32'h00628733; // 28. add a4, t0, t1      (x14 = 10)
    #10 inst_addr = 32'h28; inst_data = 32'h406287b3; // 29. sub a5, t0, t1      (x15 = 10)
    #10 inst_addr = 32'h2C; inst_data = 32'h00629833; // 30. sll a6, t0, t1      (x16 = 10)
    #10 inst_addr = 32'h30; inst_data = 32'h0062a8b3; // 31. slt a7, t0, t1      (x17 = 0)
    #10 inst_addr = 32'h34; inst_data = 32'h0062b933; // 32. sltu s2, t0, t1     (x18 = 0)
    #10 inst_addr = 32'h38; inst_data = 32'h0062c9b3; // 33. xor s3, t0, t1      (x19 = 10)
    #10 inst_addr = 32'h3C; inst_data = 32'h0062da33; // 34. srl s4, t0, t1      (x20 = 10)
    #10 inst_addr = 32'h40; inst_data = 32'h4062dab3; // 35. sra s5, t0, t1      (x21 = 10)
    #10 inst_addr = 32'h44; inst_data = 32'h0062eb33; // 36. or  s6, t0, t1      (x22 = 10)
    #10 inst_addr = 32'h48; inst_data = 32'h0062fb33; // 37. and s7, t0, t1      (x23 = 0)

    // --- NHÓM 3: BỘ NHỚ (Store/Load dùng sp - x2) - 8 lệnh ---
    #10 inst_addr = 32'h4C; inst_data = 32'h00000113; // addi sp, zero, 0        (x2 = 0)
    #10 inst_addr = 32'h50; inst_data = 32'h00510023; // 16. sb t0, 0(sp)        (Mem[0] = 8-bit)
    #10 inst_addr = 32'h54; inst_data = 32'h00511223; // 17. sh t0, 4(sp)        (Mem[4] = 16-bit)
    #10 inst_addr = 32'h58; inst_data = 32'h00512423; // 18. sw t0, 8(sp)        (Mem[8] = 32-bit)
    #10 inst_addr = 32'h5C; inst_data = 32'h00010c03; // 11. lb s8, 0(sp)        (x24 = Load byte)
    #10 inst_addr = 32'h60; inst_data = 32'h00411c83; // 12. lh s9, 4(sp)        (x25 = Load half)
    #10 inst_addr = 32'h64; inst_data = 32'h00812d03; // 13. lw s10, 8(sp)       (x26 = Load word)
    #10 inst_addr = 32'h68; inst_data = 32'h00014d83; // 14. lbu s11, 0(sp)      (x27 = Load byte unsign)
    #10 inst_addr = 32'h6C; inst_data = 32'h00415e03; // 15. lhu t3, 4(sp)       (x28 = Load half unsign)

    // --- NHÓM 4: LUI & AUIPC - 2 lệnh ---
    #10 inst_addr = 32'h70; inst_data = 32'h12345e37; // 1. lui t3, 0x12345      (x28)
    #10 inst_addr = 32'h74; inst_data = 32'h00001eb7; // 2. auipc t4, 0x1        (x29)

    // --- NHÓM 5: NHẢY & NHÁNH (Jump & Branch) - 8 lệnh ---
    #10 inst_addr = 32'h78; inst_data = 32'h00800f6f; // 3. jal t5, 8            (Nhảy tới 80h, x30 = PC+4)
    #10 inst_addr = 32'h7C; inst_data = 32'h00000013; // (Bị nhảy qua)
    #10 inst_addr = 32'h80; inst_data = 32'h00000f97; // auipc t6, 0 (Lấy PC hiện tại vào x31)
    #10 inst_addr = 32'h84; inst_data = 32'h000f8067; // 4. jalr zero, 0(t6)     (Quay lại 80h - Test JALR)
    
    // Lưu ý: Ghi đè lệnh tiếp theo để thoát vòng lặp test Branch
    #10 inst_addr = 32'h84; inst_data = 32'h00628263; // 5. beq t0, t1, 4        (10 == 0 -> False)
    #10 inst_addr = 32'h88; inst_data = 32'h00629263; // 6. bne t0, t1, 4        (10 != 0 -> True, nhảy tới 90h)
    #10 inst_addr = 32'h8C; inst_data = 32'h00000013; // (Bị nhảy qua)
    #10 inst_addr = 32'h90; inst_data = 32'h0062c263; // 7. blt t0, t1, 4        (10 < 0 -> False)
    #10 inst_addr = 32'h94; inst_data = 32'h00535263; // 8. bge t1, t0, 4        (0 >= 10 -> False)
    #10 inst_addr = 32'h98; inst_data = 32'h0062e263; // 9. bltu t0, t1, 4       (False)
    #10 inst_addr = 32'h9C; inst_data = 32'h00537263; // 10. bgeu t1, t0, 4      (False)

    #10 inst_we = 0;

        
        // --- 3. Kiểm tra Fetch tại PC = 0 trước khi chạy ---
        #1;
        if (pc !== 32'h0000_0000) $display("FAIL: PC ban đầu không phải 0! Hiện tại: %h", pc);
        if (instr !== 32'h00a00293) $display("FAIL: Lệnh đầu tiên lỗi! Hiện tại: %h", instr);

        // --- 4. Bắt đầu chạy và Tự động kiểm tra từng nhóm lệnh ---
        start = 1;

        // --- NHÓM 1: I-Type ALU (Mỗi lệnh mất 10ns - 1 chu kỳ) ---
        #10; // Chạy xong addi t0, zero, 10
        if (uut.regfile.rf[5] !== 32'd10) $display("FAIL Lệnh 19 (addi): t0 phải bằng 10, got %d", uut.regfile.rf[5]);
        
        #10; // Chạy xong slti t1, zero, 5
        if (uut.regfile.rf[6] !== 32'd1)  $display("FAIL Lệnh 20 (slti): t1 phải bằng 1 (0 < 5), got %d", uut.regfile.rf[6]);

        #10; // Chạy xong sltiu t2, zero, 15
        if (uut.regfile.rf[7] !== 32'd1)  $display("FAIL Lệnh 21 (sltiu): t2 phải bằng 1, got %d", uut.regfile.rf[7]);

        #10; // Chạy xong xori s0, t0, 3 (10 ^ 3 = 9)
        if (uut.regfile.rf[8] !== 32'd9)  $display("FAIL Lệnh 22 (xori): s0 phải bằng 9, got %d", uut.regfile.rf[8]);

        #10; // Chạy xong ori s1, s0, 7 (9 | 7 = 15)
        if (uut.regfile.rf[9] !== 32'd15) $display("FAIL Lệnh 23 (ori): s1 phải bằng 15, got %d", uut.regfile.rf[9]);

        #10; // Chạy xong andi a0, s1, 15
        if (uut.regfile.rf[10] !== 32'd15) $display("FAIL Lệnh 24 (andi): a0 phải bằng 15, got %d", uut.regfile.rf[10]);

        #10; // Chạy xong slli a1, t0, 1 (10 << 1 = 20)
        if (uut.regfile.rf[11] !== 32'd20) $display("FAIL Lệnh 25 (slli): a1 phải bằng 20, got %d", uut.regfile.rf[11]);

        #20; // Nhảy qua srli và srai (đợi 2 chu kỳ)
        if (uut.regfile.rf[13] !== 32'd10) $display("FAIL Lệnh 27 (srai): a3 phải bằng 10, got %d", uut.regfile.rf[13]);

        // --- NHÓM 2: R-Type ALU (Ví dụ Add/Sub) ---
        #10; // Chạy xong add a4, t0, t1 (10 + 1 = 11)
        if (uut.regfile.rf[14] !== 32'd11) $display("FAIL Lệnh 28 (add): a4 phải bằng 11, got %d", uut.regfile.rf[14]);

        #10; // Chạy xong sub a5, t0, t1 (10 - 1 = 9)
        if (uut.regfile.rf[15] !== 32'd9) $display("FAIL Lệnh 29 (sub): a5 phải bằng 9, got %d", uut.regfile.rf[15]);

        // --- NHÓM 3: Load/Store ---
        // Đợi đến khi các lệnh Load từ bộ nhớ hoàn tất (khoảng chu kỳ h6C)
        #150; 
        if (uut.regfile.rf[26] !== 32'd10) $display("FAIL Lệnh 13 (lw): s10 phải bằng 10, got %d", uut.regfile.rf[26]);

        // --- NHÓM JUMP & BRANCH (Quan trọng nhất là kiểm tra PC) ---
        // Đợi đến lệnh JAL (tại địa chỉ 78h)
        #30;
        if (pc !== 32'h0000_0080) $display("FAIL Lệnh 3 (jal): PC phải nhảy tới 80h, thực tế: %h", pc);
        if (uut.regfile.rf[30] !== 32'h0000_007C) $display("FAIL Lệnh 3 (jal): t5 phải lưu PC+4 (7Ch), got %h", uut.regfile.rf[30]);

        // Đợi đến lệnh BNE (tại địa chỉ 88h)
        #10; 
        if (pc !== 32'h0000_0090) $display("FAIL Lệnh 6 (bne): Điều kiện đúng (10!=1) phải nhảy tới 90h, thực tế: %h", pc);

        // --- KẾT THÚC ---
        #100;
        $display("--------------------------------------------------");
        $display("Hoàn tất kiểm tra Self-checking!");
        $display("Nếu không có dòng FAIL nào ở trên -> CPU chay CHUẨN 37 lệnh.");
        $display("--------------------------------------------------");
        
        dump_registers(); // Gọi hàm in toàn bộ thanh ghi để xem lần cuối
        $finish;
    end
    always #5 clk = ~clk;
endmodule

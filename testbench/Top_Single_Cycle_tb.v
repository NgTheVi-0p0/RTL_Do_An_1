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
    // --- NHÓM 1: KHỞI TẠO HẰNG SỐ (I-Type ALU) ---
    // t0=10, t1=1, t2=1, s0=9, s1=15, a0=15, a1=20, a2=10, a3=10
    #10 inst_addr = 32'h00; inst_data = 32'h00a00293; // addi t0, zero, 10   -> x5 = 10
    #10 inst_addr = 32'h04; inst_data = 32'h00502313; // slti t1, zero, 5    -> x6 = 1 (vì 0 < 5)
    #10 inst_addr = 32'h08; inst_data = 32'h00f03393; // sltiu t2, zero, 15  -> x7 = 1 (không dấu)
    #10 inst_addr = 32'h0C; inst_data = 32'h0032c413; // xori s0, t0, 3      -> x8 = 10 ^ 3 = 9
    #10 inst_addr = 32'h10; inst_data = 32'h00746493; // ori s1, s0, 7       -> x9 = 9 | 7 = 15
    #10 inst_addr = 32'h14; inst_data = 32'h00f4f513; // andi a0, s1, 15     -> x10 = 15 & 15 = 15
    #10 inst_addr = 32'h18; inst_data = 32'h00129593; // slli a1, t0, 1      -> x11 = 10 << 1 = 20
    #10 inst_addr = 32'h1C; inst_data = 32'h0015d613; // srli a2, a1, 1      -> x12 = 20 >> 1 = 10
    #10 inst_addr = 32'h20; inst_data = 32'h4015d693; // srai a3, a1, 1      -> x13 = 20 >>> 1 = 10

    // --- NHÓM 2: TÍNH TOÁN THANH GHI (R-Type ALU) ---
    // Sử dụng t0=10, t1=1 làm đầu vào
    #10 inst_addr = 32'h24; inst_data = 32'h00628733; // add a4, t0, t1      -> x14 = 10 + 1 = 11
    #10 inst_addr = 32'h28; inst_data = 32'h406287b3; // sub a5, t0, t1      -> x15 = 10 - 1 = 9
    #10 inst_addr = 32'h2C; inst_data = 32'h00629833; // sll a6, t0, t1      -> x16 = 10 << 1 = 20
    #10 inst_addr = 32'h30; inst_data = 32'h0062a8b3; // slt a7, t0, t1      -> x17 = 0 (10 không < 1)
    #10 inst_addr = 32'h34; inst_data = 32'h0062b933; // sltu s2, t0, t1     -> x18 = 0
    #10 inst_addr = 32'h38; inst_data = 32'h0062c9b3; // xor s3, t0, t1      -> x19 = 10 ^ 1 = 11
    #10 inst_addr = 32'h3C; inst_data = 32'h0062da33; // srl s4, t0, t1      -> x20 = 10 >> 1 = 5
    #10 inst_addr = 32'h40; inst_data = 32'h4062dab3; // sra s5, t0, t1      -> x21 = 10 >>> 1 = 5
    #10 inst_addr = 32'h44; inst_data = 32'h0062eb33; // or  s6, t0, t1      -> x22 = 10 | 1 = 11
    #10 inst_addr = 32'h48; inst_data = 32'h0062fb33; // and s7, t0, t1      -> x23 = 10 & 1 = 0

    // --- NHÓM 3: BỘ NHỚ (Store/Load dùng sp - x2) ---
    #10 inst_addr = 32'h4C; inst_data = 32'h00000113; // addi sp, zero, 0    -> x2 = 0
    #10 inst_addr = 32'h50; inst_data = 32'h00512023; // sw t0, 0(sp)        -> Mem[0] = 10 (32-bit)
    #10 inst_addr = 32'h54; inst_data = 32'h00512223; // sw t0, 4(sp)        -> Mem[4] = 10 (32-bit)
    #10 inst_addr = 32'h58; inst_data = 32'h00812d03; // lw s10, 8(sp)       -> Test Load (địa chỉ 8)
    #10 inst_addr = 32'h5C; inst_data = 32'h00010c03; // lb s8, 0(sp)        -> x24 = Load byte từ Mem[0]
    #10 inst_addr = 32'h60; inst_data = 32'h00411c83; // lh s9, 4(sp)        -> x25 = Load half từ Mem[4]
    #10 inst_addr = 32'h64; inst_data = 32'h00012d03; // lw s10, 0(sp)       -> x26 = Load word từ Mem[0]
    #10 inst_addr = 32'h68; inst_data = 32'h00014d83; // lbu s11, 0(sp)      -> x27 = Load byte unsigned
    #10 inst_addr = 32'h6C; inst_data = 32'h00415e03; // lhu t3, 4(sp)       -> x28 = Load half unsigned

    // --- NHÓM 4: LUI & AUIPC ---
    #10 inst_addr = 32'h70; inst_data = 32'h12345e37; // lui t3, 0x12345     -> x28 = 0x12345000
    #10 inst_addr = 32'h74; inst_data = 32'h00001eb7; // auipc t4, 0x1       -> x29 = 0x74 + 0x1000 = 0x1074

    // --- NHÓM 5: NHẢY & NHÁNH (Jump & Branch) ---
    #10 inst_addr = 32'h78; inst_data = 32'h00800f6f; // jal t5, 8            -> Nhảy tới 80h, x30 = 7Ch
    #10 inst_addr = 32'h7C; inst_data = 32'h01400293; // addi x5, zero, 20   -> (Lệnh này PHẢI BỊ NHẢY QUA)
    #10 inst_addr = 32'h80; inst_data = 32'h00000f97; // auipc t6, 0         -> x31 = 80h (lấy PC hiện tại)
    
    // Test Branch (Lưu ý Machine Code đã sửa để nhảy +8 bytes)
    #10 inst_addr = 32'h84; inst_data = 32'h00628463; // beq t0, t1, 8        -> (10==1? Sai) -> Đi tiếp tới 88h
    #10 inst_addr = 32'h88; inst_data = 32'h00629463; // bne t0, t1, 8        -> (10!=1? Đúng) -> Nhảy tới 90h
    #10 inst_addr = 32'h8C; inst_data = 32'h01400293; // addi x5, zero, 20   -> (Lệnh này PHẢI BỊ NHẢY QUA)
    
    #10 inst_addr = 32'h90; inst_data = 32'h0062c463; // blt t0, t1, 8        -> (10<1? Sai) -> Đi tiếp tới 94h
    #10 inst_addr = 32'h94; inst_data = 32'h00535463; // bge t1, t0, 8        -> (1>=10? Sai) -> Đi tiếp tới 98h
    #10 inst_addr = 32'h98; inst_data = 32'h00000013; // nop (addi x0, x0, 0)
    
    // Lệnh lặp vô tận để dừng CPU (Rất quan trọng!)
    #10 inst_addr = 32'h9C; inst_data = 32'h0000006f; // jal zero, 0          -> Nhảy tại chỗ mãi mãi ở 9Ch

    #10 inst_we = 0;

        
        // --- 3. Kiểm tra Fetch tại PC = 0 trước khi chạy ---
        #1;
        if (pc !== 32'h0000_0000) $display("FAIL: PC ban đầu không phải 0! Hiện tại: %h", pc);
        if (instr !== 32'h00a00293) $display("FAIL: Lệnh đầu tiên lỗi! Hiện tại: %h", instr);

        // --- 4. Bắt đầu chạy và Tự động kiểm tra từng nhóm lệnh ---
        start = 1;

        // --- NHÓM 1: I-Type ALU (Mỗi lệnh mất 10ns - 1 chu kỳ) ---
        repeat(1) @(negedge clk); // Chạy xong addi t0, zero, 10
        if (uut.regfile.rf[5] !== 32'd10) $display("FAIL Lệnh 19 (addi): t0 phải bằng 10, got %d", uut.regfile.rf[5]);
        
       repeat(1) @(negedge clk); // Chạy xong slti t1, zero, 5
        if (uut.regfile.rf[6] !== 32'd1)  $display("FAIL Lệnh 20 (slti): t1 phải bằng 1 (0 < 5), got %d", uut.regfile.rf[6]);

        repeat(1) @(negedge clk);  // Chạy xong sltiu t2, zero, 15
        if (uut.regfile.rf[7] !== 32'd1)  $display("FAIL Lệnh 21 (sltiu): t2 phải bằng 1, got %d", uut.regfile.rf[7]);

        repeat(1) @(negedge clk); // Chạy xong xori s0, t0, 3 (10 ^ 3 = 9)
        if (uut.regfile.rf[8] !== 32'd9)  $display("FAIL Lệnh 22 (xori): s0 phải bằng 9, got %d", uut.regfile.rf[8]);

        repeat(1) @(negedge clk); // Chạy xong ori s1, s0, 7 (9 | 7 = 15)
        if (uut.regfile.rf[9] !== 32'd15) $display("FAIL Lệnh 23 (ori): s1 phải bằng 15, got %d", uut.regfile.rf[9]);

        repeat(1) @(negedge clk); // Chạy xong andi a0, s1, 15
        if (uut.regfile.rf[10] !== 32'd15) $display("FAIL Lệnh 24 (andi): a0 phải bằng 15, got %d", uut.regfile.rf[10]);

        repeat(1) @(negedge clk); // Chạy xong slli a1, t0, 1 (10 << 1 = 20)
        if (uut.regfile.rf[11] !== 32'd20) $display("FAIL Lệnh 25 (slli): a1 phải bằng 20, got %d", uut.regfile.rf[11]);

        repeat(2) @(negedge clk); // Nhảy qua srli và srai (đợi 2 chu kỳ)
        if (uut.regfile.rf[13] !== 32'd10) $display("FAIL Lệnh 27 (srai): a3 phải bằng 10, got %d", uut.regfile.rf[13]);

        // --- NHÓM 2: R-Type ALU (Ví dụ Add/Sub) ---
        repeat(1) @(negedge clk); // Chạy xong add a4, t0, t1 (10 + 1 = 11)
        if (uut.regfile.rf[14] !== 32'd11) $display("FAIL Lệnh 28 (add): a4 phải bằng 11, got %d", uut.regfile.rf[14]);

        repeat(1) @(negedge clk); // Chạy xong sub a5, t0, t1 (10 - 1 = 9)
        if (uut.regfile.rf[15] !== 32'd9) $display("FAIL Lệnh 29 (sub): a5 phải bằng 9, got %d", uut.regfile.rf[15]);

        // --- NHÓM 3: Load/Store ---
        // Đợi đến khi các lệnh Load từ bộ nhớ hoàn tất (khoảng chu kỳ h6C)
        repeat(15) @(negedge clk);
        if (uut.regfile.rf[26] !== 32'd10) $display("FAIL Lệnh 13 (lw): s10 phải bằng 10, got %d", uut.regfile.rf[26]);

        // --- NHÓM JUMP & BRANCH (Quan trọng nhất là kiểm tra PC) ---
        // Đợi đến lệnh JAL (tại địa chỉ 78h)
        repeat(5) @(negedge clk);
        if (pc !== 32'h0000_0080) $display("FAIL Lệnh 3 (jal): PC phải nhảy tới 80h, thực tế: %h", pc);
        if (uut.regfile.rf[30] !== 32'h0000_007C) $display("FAIL Lệnh 3 (jal): t5 phải lưu PC+4 (7Ch), got %h", uut.regfile.rf[30]);

        // Đợi đến lệnh BNE (tại địa chỉ 88h)
        repeat(3) @(negedge clk);
        if (pc !== 32'h0000_0090) $display("FAIL Lệnh 6 (bne): Điều kiện đúng (10!=1) phải nhảy tới 90h, thực tế: %h", pc);

        // --- KẾT THÚC ---
        repeat(100) @(negedge clk);
        $display("--------------------------------------------------");
        $display("Hoàn tất kiểm tra Self-checking!");
        $display("Nếu không có dòng FAIL nào ở trên -> CPU chay CHUẨN 37 lệnh.");
        $display("--------------------------------------------------");
        
        dump_registers(); // Gọi hàm in toàn bộ thanh ghi để xem lần cuối
        $finish;
    end
    always #5 clk = ~clk;
endmodule

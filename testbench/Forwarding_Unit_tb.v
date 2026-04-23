// Testbench cho Forwarding Unit

`timescale 1ns / 1ps

module Forwarding_Unit_tb;

    reg [4:0]  id_ex_rs1;
    reg [4:0]  id_ex_rs2;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_regWrite;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_regWrite;

    wire [1:0] forwardA;
    wire [1:0] forwardB;

    // Instantiate the module
    Forwarding_Unit uut (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_regWrite(ex_mem_regWrite),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_regWrite(mem_wb_regWrite),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    // Test cases
    initial begin
        $dumpfile("mophong_vcd/Forwarding_Unit_tb.vcd");
        $dumpvars(0, Forwarding_Unit_tb);

        // Khởi tạo
        id_ex_rs1 = 5'b0_0000;
        id_ex_rs2 = 5'b0_0000;
        ex_mem_rd = 5'b0_0000;
        ex_mem_regWrite = 1'b0;
        mem_wb_rd = 5'b0_0000;
        mem_wb_regWrite = 1'b0;

        #10;

        // Test 1: Không có forwarding (dùng register file)
        $display("=== TEST 1: Không forwarding ===");
        id_ex_rs1 = 5'b0_0001;  // x1
        id_ex_rs2 = 5'b0_0010;  // x2
        ex_mem_rd = 5'b0_0011;  // x3 (không trùng)
        ex_mem_regWrite = 1'b1;
        mem_wb_rd = 5'b0_0100;  // x4 (không trùng)
        mem_wb_regWrite = 1'b1;
        #10;

        if (forwardA !== 2'b00 || forwardB !== 2'b00) begin
            $display("FAIL: Không forward khi không cần thiết");
            $display("forwardA=%b, forwardB=%b", forwardA, forwardB);
        end else begin
            $display("PASS: forwardA=%b, forwardB=%b (dùng register file)", forwardA, forwardB);
        end

        // Test 2: Forward rs1 từ EX/MEM, rs2 từ MEM/WB
        $display("\n=== TEST 2: Forward rs1 từ EX/MEM, rs2 từ MEM/WB ===");
        id_ex_rs1 = 5'b0_0011;  // x3
        id_ex_rs2 = 5'b0_0100;  // x4
        ex_mem_rd = 5'b0_0011;  // x3 (trùng rs1)
        ex_mem_regWrite = 1'b1;
        mem_wb_rd = 5'b0_0100;  // x4 (trùng rs2)
        mem_wb_regWrite = 1'b1;
        #10;

        if (forwardA !== 2'b01 || forwardB !== 2'b10) begin
            $display("FAIL: Không forward đúng rs1 từ EX/MEM và rs2 từ MEM/WB");
            $display("forwardA=%b (expected 01), forwardB=%b (expected 10)", forwardA, forwardB);
        end else begin
            $display("PASS: forwardA=%b (EX/MEM), forwardB=%b (MEM/WB)", forwardA, forwardB);
        end

        // Test 3: Forward rs2 từ MEM/WB
        $display("\n=== TEST 3: Forward rs2 từ MEM/WB ===");
        id_ex_rs1 = 5'b0_0101;  // x5
        id_ex_rs2 = 5'b0_0110;  // x6
        ex_mem_rd = 5'b0_0101;  // x5 (trùng rs1)
        ex_mem_regWrite = 1'b1;
        mem_wb_rd = 5'b0_0110;  // x6 (trùng rs2)
        mem_wb_regWrite = 1'b1;
        #10;

        if (forwardA !== 2'b01 || forwardB !== 2'b10) begin
            $display("FAIL: Không forward đúng cả rs1 và rs2");
            $display("forwardA=%b (expected 01), forwardB=%b (expected 10)", forwardA, forwardB);
        end else begin
            $display("PASS: forwardA=%b (EX/MEM), forwardB=%b (MEM/WB)", forwardA, forwardB);
        end

        // Test 4: Forward cả rs1 và rs2 từ EX/MEM
        $display("\n=== TEST 4: Forward cả rs1 và rs2 từ EX/MEM ===");
        id_ex_rs1 = 5'b0_0111;  // x7
        id_ex_rs2 = 5'b0_0111;  // x7 (cùng register)
        ex_mem_rd = 5'b0_0111;  // x7
        ex_mem_regWrite = 1'b1;
        mem_wb_rd = 5'b0_1000;  // x8 (không ảnh hưởng)
        mem_wb_regWrite = 1'b1;
        #10;

        if (forwardA !== 2'b01 || forwardB !== 2'b01) begin
            $display("FAIL: Không forward cả rs1 và rs2 từ EX/MEM");
            $display("forwardA=%b, forwardB=%b (expected 01, 01)", forwardA, forwardB);
        end else begin
            $display("PASS: forwardA=%b, forwardB=%b (cả hai từ EX/MEM)", forwardA, forwardB);
        end

        // Test 5: Không forward khi rd = x0
        $display("\n=== TEST 5: Không forward khi rd = x0 ===");
        id_ex_rs1 = 5'b0_0000;  // x0
        id_ex_rs2 = 5'b0_0000;  // x0
        ex_mem_rd = 5'b0_0000;  // x0 (không được forward)
        ex_mem_regWrite = 1'b1;
        mem_wb_rd = 5'b0_0000;  // x0
        mem_wb_regWrite = 1'b1;
        #10;

        if (forwardA !== 2'b00 || forwardB !== 2'b00) begin
            $display("FAIL: Forward x0 (không được phép)");
            $display("forwardA=%b, forwardB=%b (expected 00, 00)", forwardA, forwardB);
        end else begin
            $display("PASS: forwardA=%b, forwardB=%b (không forward x0)", forwardA, forwardB);
        end

        // Test 6: Không forward khi regWrite = 0
        $display("\n=== TEST 6: Không forward khi regWrite = 0 ===");
        id_ex_rs1 = 5'b0_1001;  // x9
        id_ex_rs2 = 5'b0_1010;  // x10
        ex_mem_rd = 5'b0_1001;  // x9
        ex_mem_regWrite = 1'b0; // Không ghi register
        mem_wb_rd = 5'b0_1010;  // x10
        mem_wb_regWrite = 1'b0; // Không ghi register
        #10;

        if (forwardA !== 2'b00 || forwardB !== 2'b00) begin
            $display("FAIL: Forward khi regWrite = 0");
            $display("forwardA=%b, forwardB=%b (expected 00, 00)", forwardA, forwardB);
        end else begin
            $display("PASS: forwardA=%b, forwardB=%b (regWrite = 0)", forwardA, forwardB);
        end

        #20;
        $finish;
    end

endmodule

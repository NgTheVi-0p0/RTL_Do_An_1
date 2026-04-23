// Testbench cho IF_ID Pipeline Register

`timescale 1ns / 1ps

module IF_ID_tb;

    reg        clk;
    reg        rst_n;
    reg        stall;
    reg        flush;
    reg [31:0] if_pc;
    reg [31:0] if_pc_plus4;
    reg [31:0] if_instr;
    
    wire [31:0] id_pc;
    wire [31:0] id_pc_plus4;
    wire [31:0] id_instr;

    // Instantiate the module
    IF_ID uut (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall),
        .flush(flush),
        .if_pc(if_pc),
        .if_pc_plus4(if_pc_plus4),
        .if_instr(if_instr),
        .id_pc(id_pc),
        .id_pc_plus4(id_pc_plus4),
        .id_instr(id_instr)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Test cases
    initial begin
        $dumpfile("mophong_vcd/IF_ID_tb.vcd");
        $dumpvars(0, IF_ID_tb);
        
        // Khởi tạo
        rst_n = 0;
        stall = 0;
        flush = 0;
        if_pc = 0;
        if_pc_plus4 = 4;
        if_instr = 32'h0000_0013;  // NOP
        
        #10 rst_n = 1;  // Release reset
        
        // Test 1: Ghi dữ liệu bình thường
        $display("=== TEST 1: Normal data write ===");
        if_pc = 32'h0000_0000;
        if_pc_plus4 = 32'h0000_0004;
        if_instr = 32'h0010_0093;  // addi x1, x0, 1
        #10;
        
        if (id_pc !== 32'h0000_0000 || id_instr !== 32'h0010_0093) begin
            $display("FAIL: Data not updated correctly");
        end else begin
            $display("PASS: id_pc = %h, id_instr = %h", id_pc, id_instr);
        end
        
        // Test 2: Cập nhật địa chỉ tiếp theo
        $display("\n=== TEST 2: Update to next instruction ===");
        if_pc = 32'h0000_0004;
        if_pc_plus4 = 32'h0000_0008;
        if_instr = 32'h0010_0113;  // addi x2, x0, 1
        #10;
        
        if (id_pc !== 32'h0000_0004 || id_instr !== 32'h0010_0113) begin
            $display("FAIL: Data not updated correctly");
        end else begin
            $display("PASS: id_pc = %h, id_instr = %h", id_pc, id_instr);
        end
        
        // Test 3: Stall - dữ liệu không thay đổi
        $display("\n=== TEST 3: Stall condition ===");
        stall = 1;
        if_pc = 32'h0000_0008;
        if_pc_plus4 = 32'h0000_000C;
        if_instr = 32'h0010_0193;  // addi x3, x0, 1
        #10;
        
        if (id_pc !== 32'h0000_0004 || id_instr !== 32'h0010_0113) begin
            $display("FAIL: Data changed during stall");
        end else begin
            $display("PASS: Data held during stall (id_pc = %h)", id_pc);
        end
        
        // Test 4: Flush - dữ liệu bị xóa (NOP)
        $display("\n=== TEST 4: Flush condition ===");
        stall = 0;
        flush = 1;
        #10;
        
        if (id_instr !== 32'h0000_0013) begin
            $display("FAIL: Flush didn't insert NOP");
        end else begin
            $display("PASS: Flushed with NOP (id_instr = %h)", id_instr);
        end
        
        // Test 5: Tiếp tục sau flush
        $display("\n=== TEST 5: Resume after flush ===");
        flush = 0;
        if_pc = 32'h0000_0010;
        if_pc_plus4 = 32'h0000_0014;
        if_instr = 32'h0020_0193;  // addi x3, x0, 2
        #10;
        
        if (id_pc !== 32'h0000_0010 || id_instr !== 32'h0020_0193) begin
            $display("FAIL: Data not updated after flush");
        end else begin
            $display("PASS: id_pc = %h, id_instr = %h", id_pc, id_instr);
        end
        
        #20;
        $finish;
    end

endmodule

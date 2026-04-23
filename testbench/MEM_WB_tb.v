// Testbench cho MEM_WB Pipeline Register

`timescale 1ns / 1ps

module MEM_WB_tb;

    reg        clk;
    reg        rst_n;
    
    reg [31:0] mem_pc_plus4;
    reg [31:0] mem_alu_result;
    reg [31:0] mem_mem_data;
    reg [4:0]  mem_rd;
    
    reg        mem_regWrite;
    reg [1:0]  mem_write_back;
    
    wire [31:0] wb_pc_plus4;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_mem_data;
    wire [4:0]  wb_rd;
    
    wire        wb_regWrite;
    wire [1:0]  wb_write_back;

    // Instantiate the module
    MEM_WB uut (
        .clk(clk),
        .rst_n(rst_n),
        .mem_pc_plus4(mem_pc_plus4),
        .mem_alu_result(mem_alu_result),
        .mem_mem_data(mem_mem_data),
        .mem_rd(mem_rd),
        .mem_regWrite(mem_regWrite),
        .mem_write_back(mem_write_back),
        .wb_pc_plus4(wb_pc_plus4),
        .wb_alu_result(wb_alu_result),
        .wb_mem_data(wb_mem_data),
        .wb_rd(wb_rd),
        .wb_regWrite(wb_regWrite),
        .wb_write_back(wb_write_back)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Test cases
    initial begin
        $dumpfile("mophong_vcd/MEM_WB_tb.vcd");
        $dumpvars(0, MEM_WB_tb);
        
        // Khởi tạo
        rst_n = 0;
        mem_pc_plus4 = 32'h0000_0004;
        mem_alu_result = 32'h0000_0000;
        mem_mem_data = 32'h0000_0000;
        mem_rd = 5'b0_0000;
        mem_regWrite = 1'b0;
        mem_write_back = 2'b00;
        
        #10 rst_n = 1;  // Release reset
        
        // Test 1: Ghi dữ liệu lệnh ADD (write back ALU result)
        $display("=== TEST 1: Ghi dữ liệu lệnh ADD ===");
        mem_pc_plus4 = 32'h0000_0004;
        mem_alu_result = 32'h0000_000F;  // 10 + 5 = 15
        mem_mem_data = 32'h0000_0000;    // Không dùng
        mem_rd = 5'b0_0011;              // rd = x3
        mem_regWrite = 1'b1;
        mem_write_back = 2'b00;          // ALU result
        #10;
        
        if (wb_alu_result !== 32'h0000_000F || wb_rd !== 5'b0_0011 || wb_regWrite !== 1'b1) begin
            $display("FAIL: Dữ liệu ADD không đúng");
        end else begin
            $display("PASS: wb_alu_result=%h, wb_rd=%d, wb_regWrite=%b", wb_alu_result, wb_rd, wb_regWrite);
        end
        
        // Test 2: Ghi dữ liệu lệnh LW (write back memory data)
        $display("\n=== TEST 2: Ghi dữ liệu lệnh LW ===");
        mem_pc_plus4 = 32'h0000_0008;
        mem_alu_result = 32'h0000_0200;  // địa chỉ load (không dùng cho write back)
        mem_mem_data = 32'hABCD_1234;    // dữ liệu từ memory
        mem_rd = 5'b0_0100;              // rd = x4
        mem_regWrite = 1'b1;
        mem_write_back = 2'b01;          // Memory data
        #10;
        
        if (wb_mem_data !== 32'hABCD_1234 || wb_rd !== 5'b0_0100 || wb_write_back !== 2'b01) begin
            $display("FAIL: Dữ liệu LW không đúng");
        end else begin
            $display("PASS: wb_mem_data=%h, wb_rd=%d, wb_write_back=%b", wb_mem_data, wb_rd, wb_write_back);
        end
        
        // Test 3: Ghi dữ liệu lệnh JAL (write back PC+4)
        $display("\n=== TEST 3: Ghi dữ liệu lệnh JAL ===");
        mem_pc_plus4 = 32'h0000_0100;    // return address
        mem_alu_result = 32'h0000_0000;  // không dùng
        mem_mem_data = 32'h0000_0000;    // không dùng
        mem_rd = 5'b0_0001;              // rd = x1 (RA register)
        mem_regWrite = 1'b1;
        mem_write_back = 2'b10;          // PC + 4
        #10;
        
        if (wb_pc_plus4 !== 32'h0000_0100 || wb_rd !== 5'b0_0001 || wb_write_back !== 2'b10) begin
            $display("FAIL: Dữ liệu JAL không đúng");
        end else begin
            $display("PASS: wb_pc_plus4=%h, wb_rd=%d, wb_write_back=%b", wb_pc_plus4, wb_rd, wb_write_back);
        end
        
        // Test 4: Lệnh không ghi register (SW, BEQ, etc.)
        $display("\n=== TEST 4: Lệnh không ghi register ===");
        mem_pc_plus4 = 32'h0000_000C;
        mem_alu_result = 32'h0000_0300;
        mem_mem_data = 32'h0000_0000;
        mem_rd = 5'b0_0000;              // rd = x0
        mem_regWrite = 1'b0;             // Không ghi register
        mem_write_back = 2'b00;
        #10;
        
        if (wb_regWrite !== 1'b0) begin
            $display("FAIL: regWrite không đúng cho lệnh không ghi");
        end else begin
            $display("PASS: wb_regWrite=%b (không ghi register)", wb_regWrite);
        end
        
        // Test 5: Cập nhật liên tiếp
        $display("\n=== TEST 5: Cập nhật liên tiếp ===");
        mem_pc_plus4 = 32'h0000_0010;
        mem_alu_result = 32'h0000_FFFF;
        mem_mem_data = 32'h1234_5678;
        mem_rd = 5'b0_0101;              // rd = x5
        mem_regWrite = 1'b1;
        mem_write_back = 2'b01;          // Memory data
        #10;
        
        if (wb_mem_data !== 32'h1234_5678 || wb_rd !== 5'b0_0101) begin
            $display("FAIL: Cập nhật liên tiếp không đúng");
        end else begin
            $display("PASS: wb_mem_data=%h, wb_rd=%d", wb_mem_data, wb_rd);
        end
        
        #20;
        $finish;
    end

endmodule

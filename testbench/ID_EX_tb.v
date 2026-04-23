// Testbench cho ID_EX Pipeline Register

`timescale 1ns / 1ps

module ID_EX_tb;

    reg        clk;
    reg        rst_n;
    reg        stall;
    reg        flush;
    
    reg [31:0] id_pc;
    reg [31:0] id_pc_plus4;
    reg [31:0] id_rs1_data;
    reg [31:0] id_rs2_data;
    reg [31:0] id_imm;
    reg [4:0]  id_rd;
    reg [4:0]  id_rs1;
    reg [4:0]  id_rs2;
    
    reg        id_regWrite;
    reg [2:0]  id_imm_sel;
    reg        id_alu_srcA;
    reg        id_alu_srcB;
    reg [9:0]  id_alu_ctrl;
    reg        id_branch;
    reg [2:0]  id_bropcode;
    reg [1:0]  id_jump;
    reg [2:0]  id_load_sel;
    reg [2:0]  id_store_sel;
    reg        id_memWrite;
    reg [1:0]  id_write_back;
    
    wire [31:0] ex_pc;
    wire [31:0] ex_pc_plus4;
    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [31:0] ex_imm;
    wire [4:0]  ex_rd;
    wire [4:0]  ex_rs1;
    wire [4:0]  ex_rs2;
    
    wire        ex_regWrite;
    wire [2:0]  ex_imm_sel;
    wire        ex_alu_srcA;
    wire        ex_alu_srcB;
    wire [9:0]  ex_alu_ctrl;
    wire        ex_branch;
    wire [2:0]  ex_bropcode;
    wire [1:0]  ex_jump;
    wire [2:0]  ex_load_sel;
    wire [2:0]  ex_store_sel;
    wire        ex_memWrite;
    wire [1:0]  ex_write_back;

    // Instantiate the module
    ID_EX uut (
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall),
        .flush(flush),
        .id_pc(id_pc),
        .id_pc_plus4(id_pc_plus4),
        .id_rs1_data(id_rs1_data),
        .id_rs2_data(id_rs2_data),
        .id_imm(id_imm),
        .id_rd(id_rd),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_regWrite(id_regWrite),
        .id_imm_sel(id_imm_sel),
        .id_alu_srcA(id_alu_srcA),
        .id_alu_srcB(id_alu_srcB),
        .id_alu_ctrl(id_alu_ctrl),
        .id_branch(id_branch),
        .id_bropcode(id_bropcode),
        .id_jump(id_jump),
        .id_load_sel(id_load_sel),
        .id_store_sel(id_store_sel),
        .id_memWrite(id_memWrite),
        .id_write_back(id_write_back),
        .ex_pc(ex_pc),
        .ex_pc_plus4(ex_pc_plus4),
        .ex_rs1_data(ex_rs1_data),
        .ex_rs2_data(ex_rs2_data),
        .ex_imm(ex_imm),
        .ex_rd(ex_rd),
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .ex_regWrite(ex_regWrite),
        .ex_imm_sel(ex_imm_sel),
        .ex_alu_srcA(ex_alu_srcA),
        .ex_alu_srcB(ex_alu_srcB),
        .ex_alu_ctrl(ex_alu_ctrl),
        .ex_branch(ex_branch),
        .ex_bropcode(ex_bropcode),
        .ex_jump(ex_jump),
        .ex_load_sel(ex_load_sel),
        .ex_store_sel(ex_store_sel),
        .ex_memWrite(ex_memWrite),
        .ex_write_back(ex_write_back)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Test cases
    initial begin
        $dumpfile("mophong_vcd/ID_EX_tb.vcd");
        $dumpvars(0, ID_EX_tb);
        
        // Khởi tạo
        rst_n = 0;
        stall = 0;
        flush = 0;
        id_pc = 32'h0000_0000;
        id_pc_plus4 = 32'h0000_0004;
        id_rs1_data = 32'h0000_0000;
        id_rs2_data = 32'h0000_0000;
        id_imm = 32'h0000_0000;
        id_rd = 5'b0_0001;
        id_rs1 = 5'b0_0000;
        id_rs2 = 5'b0_0000;
        id_regWrite = 1'b0;
        id_imm_sel = 3'b000;
        id_alu_srcA = 1'b0;
        id_alu_srcB = 1'b0;
        id_alu_ctrl = 10'b0000_000000;
        id_branch = 1'b0;
        id_bropcode = 3'b000;
        id_jump = 2'b00;
        id_load_sel = 3'b000;
        id_store_sel = 3'b000;
        id_memWrite = 1'b0;
        id_write_back = 2'b00;
        
        #10 rst_n = 1;  // Release reset
        
        // Test 1: Ghi dữ liệu bình thường (lệnh ADDI x1, x0, 1)
        $display("=== TEST 1: Ghi dữ liệu lệnh ADDI ===");
        id_pc = 32'h0000_0000;
        id_pc_plus4 = 32'h0000_0004;
        id_rs1_data = 32'h0000_0000;
        id_rs2_data = 32'h0000_0000;
        id_imm = 32'h0000_0001;  // immediate = 1
        id_rd = 5'b0_0001;       // rd = x1
        id_rs1 = 5'b0_0000;      // rs1 = x0
        id_regWrite = 1'b1;
        id_alu_srcA = 1'b0;
        id_alu_srcB = 1'b1;
        id_alu_ctrl = 10'b0000_000000;  // ADD operation
        id_write_back = 2'b00;
        #10;
        
        if (ex_pc !== 32'h0000_0000 || ex_rd !== 5'b0_0001 || ex_regWrite !== 1'b1) begin
            $display("FAIL: Dữ liệu không được cập nhật đúng");
        end else begin
            $display("PASS: ex_pc=%h, ex_rd=%d, ex_regWrite=%b", ex_pc, ex_rd, ex_regWrite);
        end
        
        // Test 2: Cập nhật lệnh tiếp theo (LW x2, 0(x1))
        $display("\n=== TEST 2: Ghi dữ liệu lệnh LW ===");
        id_pc = 32'h0000_0004;
        id_pc_plus4 = 32'h0000_0008;
        id_rs1_data = 32'h0000_0001;  // x1 = 1
        id_rs2_data = 32'h0000_0000;
        id_imm = 32'h0000_0000;       // offset = 0
        id_rd = 5'b0_0010;            // rd = x2
        id_rs1 = 5'b0_0001;           // rs1 = x1
        id_regWrite = 1'b1;
        id_alu_srcA = 1'b0;
        id_alu_srcB = 1'b1;
        id_alu_ctrl = 10'b0000_000000;
        id_load_sel = 3'b010;         // 32-bit load
        id_write_back = 2'b01;        // Memory data
        #10;
        
        if (ex_pc !== 32'h0000_0004 || ex_rd !== 5'b0_0010 || ex_load_sel !== 3'b010) begin
            $display("FAIL: Dữ liệu LW không đúng");
        end else begin
            $display("PASS: ex_pc=%h, ex_rd=%d, ex_load_sel=%b", ex_pc, ex_rd, ex_load_sel);
        end
        
        // Test 3: Stall - dữ liệu không thay đổi
        $display("\n=== TEST 3: Điều kiện Stall ===");
        stall = 1;
        id_pc = 32'h0000_0008;
        id_pc_plus4 = 32'h0000_000C;
        id_rd = 5'b0_0011;
        #10;
        
        if (ex_pc !== 32'h0000_0004 || ex_rd !== 5'b0_0010) begin
            $display("FAIL: Dữ liệu thay đổi trong lúc stall");
        end else begin
            $display("PASS: Dữ liệu được giữ nguyên (ex_pc=%h)", ex_pc);
        end
        
        // Test 4: Flush - xóa dữ liệu (NOP)
        $display("\n=== TEST 4: Điều kiện Flush ===");
        stall = 0;
        flush = 1;
        #10;
        
        if (ex_regWrite !== 1'b0 || ex_pc !== 32'h0000_0000) begin
            $display("FAIL: Flush không xóa dữ liệu đúng");
        end else begin
            $display("PASS: Đã flush (ex_regWrite=%b, ex_pc=%h)", ex_regWrite, ex_pc);
        end
        
        // Test 5: Tiếp tục sau flush (lệnh BEQ)
        $display("\n=== TEST 5: Tiếp tục sau flush với lệnh BEQ ===");
        flush = 0;
        id_pc = 32'h0000_0010;
        id_pc_plus4 = 32'h0000_0014;
        id_rs1_data = 32'h0000_0005;
        id_rs2_data = 32'h0000_0005;
        id_imm = 32'h0000_0010;       // branch offset
        id_rd = 5'b0_0000;            // rd = x0 (không cần ghi)
        id_regWrite = 1'b0;
        id_branch = 1'b1;
        id_bropcode = 3'b000;         // BEQ
        #10;
        
        if (ex_pc !== 32'h0000_0010 || ex_branch !== 1'b1) begin
            $display("FAIL: Lệnh BEQ không được cập nhật đúng");
        end else begin
            $display("PASS: ex_pc=%h, ex_branch=%b, rs1_data=%h, rs2_data=%h", 
                     ex_pc, ex_branch, ex_rs1_data, ex_rs2_data);
        end
        
        #20;
        $finish;
    end

endmodule

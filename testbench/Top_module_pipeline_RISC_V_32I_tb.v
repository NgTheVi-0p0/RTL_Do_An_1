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
        input [11:0] imm12;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            ENC_I = {imm12, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic [31:0] ENC_S;
        input [11:0] imm12;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        begin
            ENC_S = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
        end
    endfunction

    // Branch immediate is byte offset, must be multiple of 2
    function automatic [31:0] ENC_B;
        input integer imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [6:0] opcode;
        reg [12:0] bimm;
        begin
            bimm = imm[12:0];
            ENC_B = {bimm[12], bimm[10:5], rs2, rs1, funct3, bimm[4:1], bimm[11], opcode};
        end
    endfunction

    // J immediate is byte offset, must be multiple of 2
    function automatic [31:0] ENC_J;
        input integer imm;
        input [4:0] rd;
        input [6:0] opcode;
        reg [20:0] jimm;
        begin
            jimm = imm[20:0];
            ENC_J = {jimm[20], jimm[10:1], jimm[11], jimm[19:12], rd, opcode};
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

        rst_n        = 1'b0;
        start        = 1'b0;
        DataOrReg    = 1'b0;
        check_address= 32'b0;
        instruction  = 32'h0000_0013;
        address      = 32'b0;
        error_count  = 0;
        flush_count  = 0;

        // Hold reset
        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // Group A: reset/start/load behavior
        check_equal("PC after reset release", uut.pc_F, 32'h0000_0000);
        check_equal("IMEM reset to NOP at word0", uut.imem.mem[0], 32'h0000_0013);

        // While start=0: load instructions from external pins
        // Program map:
        // 0x00 addi x1,x0,5
        // 0x04 addi x2,x0,7
        // 0x08 add  x3,x1,x2
        // 0x0c add  x4,x3,x1
        // 0x10 addi x10,x0,100
        // 0x14 sw   x10,0(x0)
        // 0x18 lw   x5,0(x0)
        // 0x1c add  x6,x5,x1       (load-use hazard)
        // 0x20 beq  x6,x6,+8       (taken)
        // 0x24 addi x7,x0,99       (must be flushed/skipped)
        // 0x28 addi x7,x0,42
        // 0x2c addi x8,x0,64
        // 0x30 jal  x9,+8          (to 0x38)
        // 0x34 addi x11,x0,77      (must be skipped)
        // 0x38 jalr x12,x8,0       (to 0x40)
        // 0x3c addi x13,x0,88      (must be skipped)
        // 0x40 bne  x1,x2,+8       (taken)
        // 0x44 addi x14,x0,11      (must be skipped)
        // 0x48 addi x14,x0,22
        // 0x4c jal  x0,0           (loop forever)
        load_instr(32'h0000_0000, ENC_I(12'd5,   5'd0, 3'b000, 5'd1, 7'b0010011)); // addi x1,x0,5
        load_instr(32'h0000_0004, ENC_I(12'd7,   5'd0, 3'b000, 5'd2, 7'b0010011)); // addi x2,x0,7
        load_instr(32'h0000_0008, ENC_R(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, 7'b0110011)); // add x3,x1,x2
        load_instr(32'h0000_000c, ENC_R(7'b0000000, 5'd1, 5'd3, 3'b000, 5'd4, 7'b0110011)); // add x4,x3,x1
        load_instr(32'h0000_0010, ENC_I(12'd100, 5'd0, 3'b000, 5'd10,7'b0010011)); // addi x10,x0,100
        load_instr(32'h0000_0014, ENC_S(12'd0,   5'd10,5'd0, 3'b010, 7'b0100011)); // sw x10,0(x0)
        load_instr(32'h0000_0018, ENC_I(12'd0,   5'd0, 3'b010, 5'd5, 7'b0000011)); // lw x5,0(x0)
        load_instr(32'h0000_001c, ENC_R(7'b0000000, 5'd1, 5'd5, 3'b000, 5'd6, 7'b0110011)); // add x6,x5,x1
        load_instr(32'h0000_0020, ENC_B(8,       5'd6, 5'd6, 3'b000, 7'b1100011)); // beq x6,x6,+8
        load_instr(32'h0000_0024, ENC_I(12'd99,  5'd0, 3'b000, 5'd7, 7'b0010011)); // addi x7,x0,99
        load_instr(32'h0000_0028, ENC_I(12'd42,  5'd0, 3'b000, 5'd7, 7'b0010011)); // addi x7,x0,42
        load_instr(32'h0000_002c, ENC_I(12'd64,  5'd0, 3'b000, 5'd8, 7'b0010011)); // addi x8,x0,64
        load_instr(32'h0000_0030, ENC_J(8,       5'd9, 7'b1101111));                // jal x9,+8
        load_instr(32'h0000_0034, ENC_I(12'd77,  5'd0, 3'b000, 5'd11,7'b0010011)); // addi x11,x0,77
        load_instr(32'h0000_0038, ENC_I(12'd0,   5'd8, 3'b000, 5'd12,7'b1100111)); // jalr x12,x8,0
        load_instr(32'h0000_003c, ENC_I(12'd88,  5'd0, 3'b000, 5'd13,7'b0010011)); // addi x13,x0,88
        load_instr(32'h0000_0040, ENC_B(8,       5'd2, 5'd1, 3'b001, 7'b1100011)); // bne x1,x2,+8
        load_instr(32'h0000_0044, ENC_I(12'd11,  5'd0, 3'b000, 5'd14,7'b0010011)); // addi x14,x0,11
        load_instr(32'h0000_0048, ENC_I(12'd22,  5'd0, 3'b000, 5'd14,7'b0010011)); // addi x14,x0,22
        load_instr(32'h0000_004c, ENC_J(0,       5'd0, 7'b1101111));                // jal x0,0

        // Verify loading while start=0
        check_equal("PC must stay at 0 while start=0", uut.pc_F, 32'h0000_0000);
        check_equal("Loaded instr @0x00", uut.imem.mem[0], ENC_I(12'd5, 5'd0, 3'b000, 5'd1, 7'b0010011));
        check_equal("Loaded instr @0x30", uut.imem.mem[12], ENC_J(8, 5'd9, 7'b1101111));

        // Group B/C/D/E: start CPU and run
        @(negedge clk);
        start = 1'b1;

        // Allow enough cycles to execute and settle into final loop
        repeat (120) @(negedge clk);

        // Check architectural state (forwarding, load-use stall, branch/jump paths)
        check_reg_via_debug(5'd0,  32'd0,  "x0 must remain zero");
        check_reg_via_debug(5'd1,  32'd5,  "x1 addi result");
        check_reg_via_debug(5'd2,  32'd7,  "x2 addi result");
        check_reg_via_debug(5'd3,  32'd12, "x3 = x1 + x2 (forward path)");
        check_reg_via_debug(5'd4,  32'd17, "x4 = x3 + x1 (forward chain)");
        check_reg_via_debug(5'd5,  32'd100,"x5 = lw mem[0]");
        check_reg_via_debug(5'd6,  32'd105,"x6 = x5 + x1 (load-use hazard handled)");
        check_reg_via_debug(5'd7,  32'd42, "x7 branch skip works");
        check_reg_via_debug(5'd9,  32'h34, "x9 jal link address");
        check_reg_via_debug(5'd11, 32'd0,  "x11 skipped by jal");
        check_reg_via_debug(5'd12, 32'h3c, "x12 jalr link address");
        check_reg_via_debug(5'd13, 32'd0,  "x13 skipped by jalr");
        check_reg_via_debug(5'd14, 32'd22, "x14 bne skip works");

        check_mem_word_via_debug(32'h0000_0000, 32'd100, "mem[0] after sw");

        // Control hazard activity must appear at least once
        if (flush_count == 0) begin
            error_count = error_count + 1;
            $display("FAIL: no branch flush observed (expected at least one mispredict/recovery)");
        end else begin
            $display("PASS: observed branch flush count = %0d", flush_count);
        end

        // End report
        if (error_count == 0) begin
            $display("============================================");
            $display("TOP PIPELINE TEST PASSED (all checks green)");
            $display("============================================");
        end else begin
            $display("============================================");
            $display("TOP PIPELINE TEST FAILED, error_count = %0d", error_count);
            $display("============================================");
        end

        $finish;
    end
endmodule

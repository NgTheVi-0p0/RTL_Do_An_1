`timescale 1ns/1ps

module ALU_tb;
    reg [31:0] a;
    reg [31:0] b;
    reg [9:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    ALU uut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );

    task check;
        input [31:0] expected;
        input [9:0]  op;
        input [31:0]  exp_zero;
        begin
            #10;
            if (result !== expected) $display("ERROR %b: expected %h, got %h", op, expected, result);
            if (zero !== exp_zero) $display("ERROR %b zero: expected %b, got %b", op, exp_zero, zero);
        end
    endtask

    initial begin
        $dumpfile("mophong_vcd/ALU_tb.vcd");
        $dumpvars(0, ALU_tb);

        // ADD
        a = 32'h0000_0005; b = 32'h0000_0003;
        alu_ctrl = 10'b0000000001; check(32'h0000_0008, alu_ctrl, 1'b0);

        // ADD zero
        a = 32'h0000_0007; b = 32'hFFFF_FFF9;
        alu_ctrl = 10'b0000000001; check(32'h0000_0000, alu_ctrl, 1'b1);

        // SUB
        a = 32'h0000_0005; b = 32'h0000_0003;
        alu_ctrl = 10'b0000000010; check(32'h0000_0002, alu_ctrl, 1'b0);

        // SUB zero
        a = 32'h0000_00AA; b = 32'h0000_00AA;
        alu_ctrl = 10'b0000000010; check(32'h0000_0000, alu_ctrl, 1'b1);

        // SLL
        a = 32'h0000_0001; b = 32'h0000_0005;
        alu_ctrl = 10'b0000000100; check(32'h0000_0020, alu_ctrl, 1'b0);

        // SLT signed less
        a = 32'hFFFF_FFFF; b = 32'h0000_0001;
        alu_ctrl = 10'b0000001000; check(32'h0000_0001, alu_ctrl, 1'b0);

        // SLT signed greater
        a = 32'h0000_0002; b = 32'hFFFF_FFFF;
        alu_ctrl = 10'b0000001000; check(32'h0000_0000, alu_ctrl, 1'b1);

        // SLTU unsigned less
        a = 32'h0000_0001; b = 32'h0000_0002;
        alu_ctrl = 10'b0000010000; check(32'h0000_0001, alu_ctrl, 1'b0);

        // SLTU unsigned greater
        a = 32'hFFFF_FFFF; b = 32'h0000_0000;
        alu_ctrl = 10'b0000010000; check(32'h0000_0000, alu_ctrl, 1'b1);

        // XOR
        a = 32'h1234_5678; b = 32'hFFFF_0000;
        alu_ctrl = 10'b0000100000; check(32'hEDCB_5678, alu_ctrl, 1'b0);

        // SRL logical right shift
        a = 32'h8000_0000; b = 32'h0000_0001;
        alu_ctrl = 10'b0001000000; check(32'h4000_0000, alu_ctrl, 1'b0);

        // SRL zero result
        a = 32'h0000_0001; b = 32'h0000_0001;
        alu_ctrl = 10'b0001000000; check(32'h0000_0000, alu_ctrl, 1'b1);

        // SRA arithmetic right shift negative
        a = 32'hFFFF_FFF8; b = 32'h0000_0002;
        alu_ctrl = 10'b0010000000; check(32'hFFFF_FFFE, alu_ctrl, 1'b0);

        // SRA arithmetic right shift positive
        a = 32'h0000_0008; b = 32'h0000_0002;
        alu_ctrl = 10'b0010000000; check(32'h0000_0002, alu_ctrl, 1'b0);

        // OR
        a = 32'h0000_F0F0; b = 32'h0000_0F0F;
        alu_ctrl = 10'b0100000000; check(32'h0000_FFFF, alu_ctrl, 1'b0);

        // AND
        a = 32'h0000_F0F0; b = 32'h0000_0F0F;
        alu_ctrl = 10'b1000000000; check(32'h0000_0000, alu_ctrl, 1'b1);

        $display("ALU_tb finished");
        $finish;
    end
endmodule

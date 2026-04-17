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

    initial begin
        $dumpfile("ALU_tb.vcd");
        $dumpvars(0, ALU_tb);

        a = 32'h0000_0005; b = 32'h0000_0003;

        // ADD
        alu_ctrl = 10'b0000000001; #10;
        if (result !== 32'h8) $display("ERROR ADD: expected 8, got %h", result);

        // SUB
        alu_ctrl = 10'b0000000010; #10;
        if (result !== 32'h2) $display("ERROR SUB: expected 2, got %h", result);

        // SLL
        alu_ctrl = 10'b0000000100; #10;
        if (result !== 32'h0000_0080) $display("ERROR SLL: expected 0x80, got %h", result);

        // SLT
        alu_ctrl = 10'b0000001000; #10;
        if (result !== 32'h0000_0000) $display("ERROR SLT: expected 0, got %h", result);

        // SLTU
        alu_ctrl = 10'b0000010000; #10;
        if (result !== 32'h0000_0000) $display("ERROR SLTU: expected 0, got %h", result);

        // XOR
        alu_ctrl = 10'b0000100000; #10;
        if (result !== 32'h0000_0006) $display("ERROR XOR: expected 6, got %h", result);

        // SRL
        alu_ctrl = 10'b0001000000; #10;
        if (result !== 32'h0000_0000) $display("ERROR SRL: expected 0, got %h", result);

        // SRA
        a = 32'hFFFF_FFF8; b = 32'h0000_0002;
        alu_ctrl = 10'b0010000000; #10;
        if (result !== 32'hFFFF_FFFE) $display("ERROR SRA: expected FFFE, got %h", result);

        // OR
        a = 32'h0000_F0F0; b = 32'h0000_0F0F;
        alu_ctrl = 10'b0100000000; #10;
        if (result !== 32'h0000_FFFF) $display("ERROR OR: expected FFFF, got %h", result);

        // AND
        alu_ctrl = 10'b1000000000; #10;
        if (result !== 32'h0000_0000) $display("ERROR AND: expected 0, got %h", result);

        $display("ALU_tb finished");
        $finish;
    end
endmodule

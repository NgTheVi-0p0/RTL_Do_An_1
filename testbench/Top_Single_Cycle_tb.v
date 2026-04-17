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

    initial begin
        $dumpfile("mophong_vcd/Top_Single_Cycle_tb.vcd");
        $dumpvars(0, Top_Single_Cycle_tb);

        clk = 0;
        rst_n = 0;
        start = 0;
        inst_we = 0;
        inst_addr = 32'h0000_0000;
        inst_data = 32'h0000_0000;

        #5 rst_n = 1;

        // Load program into instruction memory while CPU is not started
        #5 inst_we = 1; inst_addr = 32'h0000_0000; inst_data = 32'h0010_0093; // addi x1, x0, 1
        #10 inst_addr = 32'h0000_0004; inst_data = 32'h0020_0113; // addi x2, x0, 2
        #10 inst_we = 0;

        // Check fetch at PC = 0
        #1;
        if (pc !== 32'h0000_0000) $display("ERROR Top PC initial: got %h", pc);
        if (instr !== 32'h0010_0093) $display("ERROR Top instr[0]: got %h", instr);

        // Start CPU and let it step through instructions
        start = 1;
        #10;
        if (pc !== 32'h0000_0004) $display("ERROR Top PC after 1st step: got %h", pc);
        if (instr !== 32'h0020_0113) $display("ERROR Top instr[4]: got %h", instr);

        #10;
        if (pc !== 32'h0000_0008) $display("ERROR Top PC after 2nd step: got %h", pc);

        $display("Top_Single_Cycle_tb finished");
        $finish;
    end

    always #5 clk = ~clk;
endmodule

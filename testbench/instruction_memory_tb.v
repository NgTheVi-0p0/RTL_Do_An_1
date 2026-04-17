`timescale 1ns/1ps

module instruction_memory_tb;
    reg clk;
    reg we;
    reg [31:0] addr_ext;
    reg [31:0] din_ext;
    reg [31:0] pc;
    wire [31:0] instr;

    instruction_memory uut (
        .clk(clk),
        .we(we),
        .addr_ext(addr_ext),
        .din_ext(din_ext),
        .pc(pc),
        .instr(instr)
    );

    initial begin
        $dumpfile("instruction_memory_tb.vcd");
        $dumpvars(0, instruction_memory_tb);

        clk = 0; we = 0; addr_ext = 32'h0000_0000; din_ext = 32'h0000_0000; pc = 32'h0000_0000;

        // Load two instructions into memory
        #5 we = 1; addr_ext = 32'h0000_0000; din_ext = 32'h0010_0093; // addi x1, x0, 1
        #10 addr_ext = 32'h0000_0004; din_ext = 32'h0020_0113; // addi x2, x0, 2
        #10 we = 0;

        // Fetch instruction at PC 0
        #5 pc = 32'h0000_0000;
        #1 if (instr !== 32'h0010_0093) $display("ERROR instr[0]: got %h", instr);

        // Fetch instruction at PC 4
        #10 pc = 32'h0000_0004;
        #1 if (instr !== 32'h0020_0113) $display("ERROR instr[4]: got %h", instr);

        $display("instruction_memory_tb finished");
        $finish;
    end

    always #5 clk = ~clk;
endmodule

module ALU (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0]  alu_ctrl, // 10 bit theo đồ án
    output reg [31:0] result,
    output wire       zero
);
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;                   // Bit 0: ADD
            4'b0001: result = a - b;                   // Bit 1: SUB
            4'b0010: result = a << b[4:0];             // Bit 2: SLL
            4'b0011: result = ($signed(a) < $signed(b)); // Bit 3: SLT
            4'b0100: result = (a < b);                 // Bit 4: SLTU
            4'b0101: result = a ^ b;                   // Bit 5: XOR
            4'b0110: result = a >> b[4:0];             // Bit 6: SRL
            4'b0111: result = $signed(a) >>> b[4:0];    // Bit 7: SRA
            4'b1000: result = a | b;                   // Bit 8: OR
            4'b1001: result = a & b;                   // Bit 9: AND
            4'b1010: result = b;                      // ALU_LUI: Lấy thẳng giá trị b (Imm)
            default: result = 32'b0;
        endcase
    end
    assign zero = (result == 32'b0);
endmodule
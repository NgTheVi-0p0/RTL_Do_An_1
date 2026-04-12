// Cách viết ALU cho alu_ctrl[9:0] (One-hot)
module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [9:0]  alu_ctrl, // 10 bit theo đồ án
    output reg [31:0] result,
    output wire       zero
);
    always @(*) begin
        case (alu_ctrl)
            10'b0000000001: result = a + b;                   // Bit 0: ADD
            10'b0000000010: result = a - b;                   // Bit 1: SUB
            10'b0000000100: result = a << b[4:0];             // Bit 2: SLL
            10'b0000001000: result = ($signed(a) < $signed(b)); // Bit 3: SLT
            10'b0000010000: result = (a < b);                 // Bit 4: SLTU
            10'b0000100000: result = a ^ b;                   // Bit 5: XOR
            10'b0001000000: result = a >> b[4:0];             // Bit 6: SRL
            10'b0010000000: result = a >>> b[4:0];            // Bit 7: SRA
            10'b0100000000: result = a | b;                   // Bit 8: OR
            10'b1000000000: result = a & b;                   // Bit 9: AND
            default: result = 32'b0;
        endcase
    end
    assign zero = (result == 32'b0);
endmodule
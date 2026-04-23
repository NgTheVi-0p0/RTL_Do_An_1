module EX_MEM (
    input wire clk,
    input wire rst_n,
    
    // Inputs từ EX
    input wire [31:0] ex_pc_plus4,
    input wire [31:0] ex_alu_result,
    input wire [31:0] ex_rs2_data_forwarded, // Dữ liệu rs2 sau khi đã qua bộ MUX forwarding (dùng cho lệnh Store)
    input wire [4:0]  ex_rd,
    
    // Control signals từ EX
    input wire        ex_regWrite,
    input wire [1:0]  ex_write_back,
    input wire        ex_memWrite,
    input wire [2:0]  ex_load_sel,
    input wire [2:0]  ex_store_sel,
    
    // Outputs sang MEM
    output reg [31:0] mem_pc_plus4,
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_rs2_data,
    output reg [4:0]  mem_rd,
    
    output reg        mem_regWrite,
    output reg [1:0]  mem_write_back,
    output reg        mem_memWrite,
    output reg [2:0]  mem_load_sel,
    output reg [2:0]  mem_store_sel
);
    // Viết logic always @(posedge clk or negedge rst_n) tương tự như các pipeline register khác
endmodule
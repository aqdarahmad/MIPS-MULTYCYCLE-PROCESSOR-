// ============================================================
// Multi-Cycle MIPS Processor - Top Level
// ============================================================
module top (
    input  logic clk,
    input  logic reset
);
    // Internal wires between Datapath and Control Unit
    logic        PCWrite, PCWriteControl, IorD;
    logic        MemRead, MemWrite, IRWrite;
    logic        MemtoReg, RegWrite, RegDst;
    logic        ALUSelA, TargetWrite;
    logic [1:0]  ALUSelB, PCSrc, ALUOp;
    logic [5:0]  opc, fn;
    logic        Zero;

    // Datapath
    datapath DP (
        .clk            (clk),
        .reset          (reset),
        .PCWrite        (PCWrite),
        .PCWriteControl (PCWriteControl),
        .IorD           (IorD),
        .MemRead        (MemRead),
        .MemWrite       (MemWrite),
        .IRWrite        (IRWrite),
        .MemtoReg       (MemtoReg),
        .RegWrite       (RegWrite),
        .RegDst         (RegDst),
        .ALUSelA        (ALUSelA),
        .ALUSelB        (ALUSelB),
        .PCSrc          (PCSrc),
        .ALUOp          (ALUOp),
        .TargetWrite    (TargetWrite),
        .opc            (opc),
        .fn             (fn),
        .Zero           (Zero)
    );

    // Control Unit
    control_unit CU (
        .clk            (clk),
        .reset          (reset),
        .opc            (opc),
        .Zero           (Zero),
        .PCWrite        (PCWrite),
        .PCWriteControl (PCWriteControl),
        .IorD           (IorD),
        .MemRead        (MemRead),
        .MemWrite       (MemWrite),
        .IRWrite        (IRWrite),
        .MemtoReg       (MemtoReg),
        .RegWrite       (RegWrite),
        .RegDst         (RegDst),
        .ALUSelA        (ALUSelA),
        .ALUSelB        (ALUSelB),
        .PCSrc          (PCSrc),
        .ALUOp          (ALUOp),
        .TargetWrite    (TargetWrite)
    );

endmodule
// ============================================================
// Control Unit - FSM (Finite State Machine)
// Multi-Cycle MIPS Processor
// ============================================================

// ──────────────────────────────────────
// Opcodes
// ──────────────────────────────────────
`define OPC_RTYPE  6'b000000
`define OPC_LW     6'b100011
`define OPC_SW     6'b101011
`define OPC_BEQ    6'b000100
`define OPC_ADDI   6'b001000
`define OPC_J      6'b000010
`define OPC_JAL    6'b000011

// ──────────────────────────────────────
// FSM States
// ──────────────────────────────────────
`define S_FETCH         4'd0
`define S_DECODE        4'd1
`define S_MEM_ADDR      4'd2   // Compute Load/Store address
`define S_MEM_READ      4'd3   // Read from memory (lw)
`define S_MEM_WRITEBACK 4'd4   // Write lw result to register
`define S_MEM_WRITE     4'd5   // Write to memory (sw)
`define S_EXECUTE       4'd6   // R-Type execute
`define S_ALU_WRITEBACK 4'd7   // Write R-Type result to register
`define S_BRANCH        4'd8   // BEQ comparison
`define S_JUMP          4'd9   // J instruction
`define S_ADDI_EX       4'd10  // ADDI execute
`define S_ADDI_WB       4'd11  // ADDI writeback

module control_unit (
    input  logic        clk, reset,
    input  logic [5:0]  opc,
    input  logic        Zero,
    // Control output signals
    output logic        PCWrite, PCWriteControl,
    output logic        IorD, MemRead, MemWrite,
    output logic        IRWrite, MemtoReg,
    output logic        RegWrite, RegDst,
    output logic        ALUSelA, TargetWrite,
    output logic [1:0]  ALUSelB, PCSrc, ALUOp
);

    logic [3:0] state, next_state;

    // ──────────────────────────────────────
    // State Register
    // ──────────────────────────────────────
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= `S_FETCH;
        else       state <= next_state;
    end

    // ──────────────────────────────────────
    // Next State Logic
    // ──────────────────────────────────────
    always_comb begin
        case (state)
            `S_FETCH: next_state = `S_DECODE;

            `S_DECODE: begin
                case (opc)
                    `OPC_LW:    next_state = `S_MEM_ADDR;
                    `OPC_SW:    next_state = `S_MEM_ADDR;
                    `OPC_RTYPE: next_state = `S_EXECUTE;
                    `OPC_BEQ:   next_state = `S_BRANCH;
                    `OPC_ADDI:  next_state = `S_ADDI_EX;
                    `OPC_J:     next_state = `S_JUMP;
                    default:    next_state = `S_FETCH;
                endcase
            end

            `S_MEM_ADDR: begin
                if (opc == `OPC_LW) next_state = `S_MEM_READ;
                else                 next_state = `S_MEM_WRITE;
            end

            `S_MEM_READ:      next_state = `S_MEM_WRITEBACK;
            `S_MEM_WRITEBACK: next_state = `S_FETCH;
            `S_MEM_WRITE:     next_state = `S_FETCH;
            `S_EXECUTE:       next_state = `S_ALU_WRITEBACK;
            `S_ALU_WRITEBACK: next_state = `S_FETCH;
            `S_BRANCH:        next_state = `S_FETCH;
            `S_JUMP:          next_state = `S_FETCH;
            `S_ADDI_EX:       next_state = `S_ADDI_WB;
            `S_ADDI_WB:       next_state = `S_FETCH;
            default:          next_state = `S_FETCH;
        endcase
    end

    // ──────────────────────────────────────
    // Output Logic (Moore FSM)
    // ──────────────────────────────────────
    always_comb begin
        // Default values (all deasserted)
        PCWrite         = 0;
        PCWriteControl  = 0;
        IorD            = 0;
        MemRead         = 0;
        MemWrite        = 0;
        IRWrite         = 0;
        MemtoReg        = 0;
        RegWrite        = 0;
        RegDst          = 0;
        ALUSelA         = 0;
        ALUSelB         = 2'b00;
        PCSrc           = 2'b00;
        ALUOp           = 2'b00;
        TargetWrite     = 0;

        case (state)
            // ─────────────────────
            // S0: FETCH
            // IR <- Memory[PC]
            // PC <- PC + 4
            // ─────────────────────
            `S_FETCH: begin
                MemRead  = 1;
                IRWrite  = 1;
                ALUSelA  = 0;        // A = PC
                ALUSelB  = 2'b01;    // B = 4
                ALUOp    = 2'b00;    // ADD
                PCWrite  = 1;
                PCSrc    = 2'b00;    // PC <- ALUResult (PC+4)
            end

            // ─────────────────────
            // S1: DECODE
            // Read registers
            // Pre-compute branch target
            // ─────────────────────
            `S_DECODE: begin
                ALUSelA     = 0;     // A = PC
                ALUSelB     = 2'b11; // B = ShiftedImm
                ALUOp       = 2'b00; // ADD
                TargetWrite = 1;     // Save Jump target address
            end

            // ─────────────────────
            // S2: MEM_ADDR (lw/sw)
            // ALUResult <- $rs + SignExt(imm)
            // ─────────────────────
            `S_MEM_ADDR: begin
                ALUSelA = 1;         // A = $rs
                ALUSelB = 2'b10;     // B = SignExtImm
                ALUOp   = 2'b00;     // ADD
            end

            // ─────────────────────
            // S3: MEM_READ (lw)
            // MDR <- Memory[ALUResult]
            // ─────────────────────
            `S_MEM_READ: begin
                MemRead = 1;
                IorD    = 1;         // Address from ALUResult
            end

            // ─────────────────────
            // S4: MEM_WRITEBACK (lw)
            // $rt <- MDR
            // ─────────────────────
            `S_MEM_WRITEBACK: begin
                RegWrite = 1;
                RegDst   = 0;        // wreg = rt
                MemtoReg = 1;        // wdata = MDR
            end

            // ─────────────────────
            // S5: MEM_WRITE (sw)
            // Memory[ALUResult] <- $rt
            // ─────────────────────
            `S_MEM_WRITE: begin
                MemWrite = 1;
                IorD     = 1;        // Address from ALUResult
            end

            // ─────────────────────
            // S6: EXECUTE (R-Type)
            // ALUResult <- $rs op $rt
            // ─────────────────────
            `S_EXECUTE: begin
                ALUSelA = 1;         // A = $rs
                ALUSelB = 2'b00;     // B = $rt
                ALUOp   = 2'b10;     // R-Type (fn field selects operation)
            end

            // ─────────────────────
            // S7: ALU_WRITEBACK (R-Type)
            // $rd <- ALUResult
            // ─────────────────────
            `S_ALU_WRITEBACK: begin
                RegWrite = 1;
                RegDst   = 1;        // wreg = rd
                MemtoReg = 0;        // wdata = ALUResult
            end

            // ─────────────────────
            // S8: BRANCH (beq)
            // if ($rs == $rt) PC <- branch address
            // ─────────────────────
            `S_BRANCH: begin
                ALUSelA        = 1;     // A = $rs
                ALUSelB        = 2'b00; // B = $rt
                ALUOp          = 2'b01; // SUB for comparison
                PCWriteControl = 1;     // update PC if Zero = 1
                PCSrc          = 2'b01; // PC <- branch target
            end

            // ─────────────────────
            // S9: JUMP (j)
            // PC <- Target
            // ─────────────────────
            `S_JUMP: begin
                PCWrite = 1;
                PCSrc   = 2'b10;     // PC <- Target register
            end

            // ─────────────────────
            // S10: ADDI Execute
            // ALUResult <- $rs + imm
            // ─────────────────────
            `S_ADDI_EX: begin
                ALUSelA = 1;         // A = $rs
                ALUSelB = 2'b10;     // B = SignExtImm
                ALUOp   = 2'b00;     // ADD
            end

            // ─────────────────────
            // S11: ADDI Writeback
            // $rt <- ALUResult
            // ─────────────────────
            `S_ADDI_WB: begin
                RegWrite = 1;
                RegDst   = 0;        // wreg = rt
                MemtoReg = 0;        // wdata = ALUResult
            end

        endcase
    end

endmodule
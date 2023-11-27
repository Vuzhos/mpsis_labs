module riscv_core (

  input  logic        clk_i,
  input  logic        rst_i,

  input  logic        stall_i,
  input  logic [31:0] instr_i,
  input  logic [31:0] mem_rd_i,
  input  logic        irq_req_i,

  output logic [31:0] instr_addr_o,
  output logic [31:0] mem_addr_o,
  output logic [ 2:0] mem_size_o,
  output logic        mem_req_o,
  output logic        mem_we_o,
  output logic [31:0] mem_wd_o,
  output logic        irq_ret_o
);

    logic [31:0] pc;

    logic [31:0] adder_2_op_2;
    logic [31:0] adder_1_o;
    logic [31:0] adder_2_o;
    
    
    logic [4:0] RA1;
    logic [4:0] RA2;
    logic [4:0] WA;
    
    logic [31:0] imm_I;
    logic [31:0] imm_U;
    logic [31:0] imm_S;
    logic [31:0] imm_B;
    logic [31:0] imm_J;
    logic [31:0] imm_Z;
    
    logic flag;
    logic [1:0] a_sel;
    logic [2:0] b_sel;
    logic [4:0] ALUop;
    logic gpr_we;
    logic [1:0] wb_sel;
    logic branch;
    logic jal;
    logic jalr;
    
    logic [31:0] wb_data;
    logic [31:0] data_for_alu_1;
    logic [31:0] data_for_alu_2;
    logic [31:0] data_from_alu;
    logic [31:0] RD1;
    logic [31:0] RD2;
    
    logic [31:0] new_pc;
    
    assign RA2 = instr_i[24:20];
    assign RA1 = instr_i[19:15];
    assign WA = instr_i[11:7];
    
    assign imm_I = { {20{instr_i[31]}}, instr_i[31:20]};
    assign imm_U = { instr_i[31:12], {12{1'b0}}};
    assign imm_S = { {20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
    assign imm_B = { {19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
    assign imm_J = { {11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
    assign imm_Z = { {27{instr_i[19]}}, instr_i[19:15]};
    
    logic mret;
    logic ill_instr;
    logic csr_we;
    logic [2:0] csr_op;
    logic [31:0] csr_wd;
    logic [31:0] mie;
    logic [31:0] mepc;
    logic [31:0] mtvec;
    
    logic irq_o;
    logic irq_cause;
    logic trap;
    assign trap = irq_o || ill_instr; 
    
    
    fulladder32 adder_1(
      .a_i      (RD1), 
      .b_i      (imm_I), 
      .carry_i  (1'b0),
      .carry_o  (), 
      .sum_o    (adder_1_o)
    );
    
    fulladder32 adder_2(
      .a_i      (pc), 
      .b_i      (adder_2_op_2), 
      .carry_i  (1'b0),
      .carry_o  (), 
      .sum_o    (adder_2_o)
    );
    
    rf_riscv reg_file(
      .clk_i            (clk_i),
      .write_enable_i   (gpr_we && !(stall_i || trap)),
      
      .write_addr_i     (WA), 
      .read_addr1_i     (RA1), 
      .read_addr2_i     (RA2),
      
      .write_data_i     (wb_data),
      .read_data1_o     (RD1), 
      .read_data2_o     (RD2) 
    );
    
    alu_riscv alu(
      .a_i      (data_for_alu_1), 
      .b_i      (data_for_alu_2), 
      .alu_op_i (ALUop), 
      .flag_o   (flag),
      .result_o (data_from_alu)
    );

    decoder_riscv decoder(
      .fetched_instr_i  (instr_i),
      .a_sel_o          (a_sel),
      .b_sel_o          (b_sel),
      .alu_op_o         (ALUop),
      .csr_op_o         (csr_op),
      .csr_we_o         (csr_we),
      .mem_req_o        (mem_req_o && !trap),
      .mem_we_o         (mem_we_o && !trap),
      .mem_size_o       (mem_size_o),
      .gpr_we_o         (gpr_we),
      .wb_sel_o         (wb_sel),
      .illegal_instr_o  (ill_instr),
      .branch_o         (branch),
      .jal_o            (jal),
      .jalr_o           (jalr),
      .mret_o           (mret)
    );
    
    csr_controller csr(
      .clk_i (clk_i),
      .rst_i (rst_i),
      .trap_i (trap),

      .opcode_i (csr_op),

      .addr_i (instr_i[31:20]),
      .pc_i (new_pc),
      .mcause_i (irq_cause ? 32'h0000_0002 : irq_cause),
      .rs1_data_i (RD1),
      .imm_data_i (imm_Z),
      .write_enable_i (csr_we),

      .read_data_o (csr_wd),
      .mie_o,
      .mepc_o (mepc),
      .mtvec_o (mtvec)
    );

    interrupt_controller irq(
      .clk_i (clk_i),
      .rst_i (rst_i),
      .exception_i (ill_instr),
      .irq_req_i (irq_req_i),
      .mie_i (mie[0]),
      .mret_i (mret),
    
      .irq_ret_o (irq_ret_o),
      .irq_cause_o (irq_cause),
      .irq_o (irq_o)
    );
    
    assign adder_2_op_2 = jal || (flag && branch) ? (branch ? imm_B : imm_J) : 4;
    assign new_pc = mret ? mepc : (trap ? mtvec : (jalr ? adder_1_o : adder_2_o));
    
    always_ff @ (posedge clk_i) begin
      if (rst_i) pc <= 32'd0;
      else if (!stall_i)
        pc <= new_pc;
    end  
    
    assign instr_addr_o = pc;
    
    always_comb begin
        case(a_sel)
            0: data_for_alu_1 = RD1;
            1: data_for_alu_1 = pc;
            2: data_for_alu_1 = 0;
        endcase
      
        case(b_sel)
            0: data_for_alu_2 = RD2;
            1: data_for_alu_2 = imm_I;
            2: data_for_alu_2 = imm_U;
            3: data_for_alu_2 = imm_S;
            4: data_for_alu_2 = 4;
        endcase
        
        case(wb_sel)
            0: wb_data = data_from_alu;
            1: wb_data = mem_rd_i;
            2: wb_data = csr_wd;
        endcase

    end
    
    assign mem_wd_o = RD2;
    
    assign mem_addr_o = data_from_alu;

endmodule

module CYBERcobra (
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [15:0]  sw_i,
  output logic [31:0]  out_o
);

    logic [31:0] pc;
    logic [31:0] data;
    logic J;
    logic B;
    logic [1:0] WS;
    logic [4:0] ALUop;
    logic [4:0] RA1;
    logic [4:0] RA2;
    logic [4:0] WA;
    logic [31:0] offset_const;
    logic [31:0] RF_const;
    
    logic flag;
    logic [31:0] data_from_alu;
    logic [31:0] data_for_rf;
    logic [31:0] reg_to_alu [1:0];
    logic [31:0] b;
    logic [31:0] new_pc;
    
    
    
    assign J = data[31];
    assign B = data[30];
    assign WS = data[29:28];
    assign ALUop = data[27:23];
    assign RA1 = data[22:18];
    assign RA2 = data[17:13];
    assign offset_const = {{22{data[12]}}, data[12:5], 2'b00};
    assign WA = data[4:0];
    assign RF_const = { {9{data[27]}}, data[27:5]};
    
    assign b = J || (B && flag) ? offset_const : 32'd4;
    
    fulladder32 adder(
      .a_i      (pc), 
      .b_i      (b), 
      .carry_i  (1'b0),
      .carry_o  (), 
      .sum_o    (new_pc)
    );
    
    instr_mem memory(
      .addr_i       (pc), 
      .read_data_o  (data)
    );
    
    rf_riscv reg_file(
      .clk_i            (clk_i),
      .write_enable_i   (!(J || B)),
      
      .write_addr_i     (WA), 
      .read_addr1_i     (RA1), 
      .read_addr2_i     (RA2),
      
      .write_data_i     (data_for_rf),
      .read_data1_o     (reg_to_alu[0]), 
      .read_data2_o     (reg_to_alu[1]) 
    );
    
    alu_riscv alu(
      .a_i      (reg_to_alu[0]), 
      .b_i      (reg_to_alu[1]), 
      .alu_op_i (ALUop), 
      .flag_o   (flag),
      .result_o (data_from_alu)
    );

    always_ff @ (posedge clk_i) begin
      if (rst_i) pc <= 32'd0;
      else
        pc <= new_pc;
    end  
    
    always_comb begin
      case(WS)
        2'b00: data_for_rf = RF_const;
        2'b01: data_for_rf = data_from_alu;
        2'b10: data_for_rf = { {16{sw_i[15]}}, sw_i[15:0]};
        default: data_for_rf = 32'd0;
      endcase
    end
    
    assign out_o = reg_to_alu[0];
       
endmodule

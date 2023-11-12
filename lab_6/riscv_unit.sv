module riscv_unit(
  input  logic        clk_i,
  input  logic        rst_i
);
    
    logic [31:0] RA_instr;
    logic [31:0] RD_instr;
    logic [31:0] RD_memory;
    logic [31:0] WD_memory;
    logic [31:0] RA_memory;
    
    logic mem_req;
    logic mem_we;
    
    logic stall;
    logic new_stall;
    
    assign new_stall = !stall && mem_req;
    
    instr_mem inst_memory(
        .addr_i(RA_instr),
        .read_data_o(RD_instr)
    );
    
    riscv_core core(
        .clk_i(clk_i),
        .rst_i(rst_i),

        .stall_i(new_stall),
        .instr_i(RD_instr),
        .mem_rd_i(RD_memory),

        .instr_addr_o(RA_instr),
        .mem_addr_o(RA_memory),
        .mem_size_o(),
        .mem_req_o(mem_req),
        .mem_we_o(mem_we),
        .mem_wd_o(WD_memory)
    );
    
    data_mem data_memory(
        .clk_i(clk_i),
        .mem_req_i(mem_req),
        .write_enable_i(mem_we),
        .addr_i(RA_memory),
        .write_data_i(WD_memory),
        .read_data_o(RD_memory)
    );
    
    always_ff @ (posedge clk_i) begin
      if (rst_i) stall <= 1;
      else stall = new_stall;
    end 
    
    
endmodule

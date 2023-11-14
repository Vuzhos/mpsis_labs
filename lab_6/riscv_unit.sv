module riscv_unit(
  input  logic        clk_i,
  input  logic        rst_i
);
    
    logic [31:0] instr_addr;
    logic [31:0] instr;
    logic stall;
    logic new_stall;    
    
    logic [31:0] memory_addr;
    logic [31:0] memory_rd;
    logic [31:0] memory_wd;
    logic mem_req;
    logic mem_we;
    
    assign new_stall = !stall && mem_req;
    
    instr_mem instr_memory(
        .addr_i(instr_addr),
        .read_data_o(instr)
    );
    
    riscv_core core(
        .clk_i(clk_i),
        .rst_i(rst_i),

        .stall_i(new_stall),
        .instr_i(instr),
        .mem_rd_i(memory_rd),

        .instr_addr_o(instr_addr),
        .mem_addr_o(memory_addr),
        .mem_size_o(),
        .mem_req_o(mem_req),
        .mem_we_o(mem_we),
        .mem_wd_o(memory_wd)
    );
    
    data_mem data_memory(
        .clk_i(clk_i),
        .mem_req_i(mem_req),
        .write_enable_i(mem_we),
        .addr_i(memory_addr),
        .write_data_i(memo),
        .read_data_o(memory_rd)
    );
    
    always_ff @ (posedge clk_i) begin
      if (rst_i) stall <= 0;
      else stall <= new_stall;
    end 

endmodule

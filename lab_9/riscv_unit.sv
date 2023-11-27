module riscv_unit(
  input  logic        clk_i,
  input  logic        rst_i
);
    
    logic [31:0] instr_addr;
    logic [31:0] instr;
    logic stall;  
    
    logic [31:0] memory_addr;
    logic [31:0] memory_rd;
    logic [31:0] memory_wd;
    logic mem_req;
    logic mem_we;
    logic [2:0] mem_size_o;
    
    logic ready;
    logic [31:0] memory_readdata;
    logic [31:0] memory_address;
    logic [31:0] memory_writedata;
    logic [3:0] memory_byteenable;
    logic memory_writeenable;
    logic memory_requiered;
    
    instr_mem instr_memory(
        .addr_i(instr_addr),
        .read_data_o(instr)
    );
    
    riscv_core core(
        .clk_i(clk_i),
        .rst_i(rst_i),

        .stall_i(stall),
        .instr_i(instr),
        .mem_rd_i(memory_rd),

        .instr_addr_o(instr_addr),
        .mem_addr_o(memory_addr),
        .mem_size_o(mem_size_o),
        .mem_req_o(mem_req),
        .mem_we_o(mem_we),
        .mem_wd_o(memory_wd)
    );
    
    riscv_lsu lsu(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .core_req_i(mem_req),
        .core_we_i(mem_we),
        .core_size_i(mem_size_o),
        .core_addr_i (memory_addr),
        .core_wd_i (memory_wd),
        .core_rd_o (memory_rd),
        .core_stall_o (stall),
        .mem_req_o (memory_requiered),
        .mem_we_o (memory_writeenable),
        .mem_be_o (memory_be),
        .mem_addr_o (memory_address),
        .mem_wd_o (memory_writedata),
        .mem_rd_i (memory_readdata),
        .mem_ready_i (ready)
    );
    
    ext_mem data_mem(
        .clk_i (clk_i),
        .mem_req_i (memory_requiered),
        .write_enable_i (memory_writeenable),
        .byte_enable_i (memory_be),
        .addr_i (memory_address),
        .write_data_i (memory_writedata),
        .read_data_o (memory_readdata),
        .ready_o (ready)
    );
    

endmodule

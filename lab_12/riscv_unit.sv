module riscv_unit(
  input  logic        clk_i,
  input  logic        resetn_i,
  
  input  logic [15:0] sw_i,       // Переключатели

  output logic [15:0] led_o,      // Светодиоды

  input  logic        kclk_i,     // Тактирующий сигнал клавиатуры
  input  logic        kdata_i,    // Сигнал данных клавиатуры

  output logic [ 6:0] hex_led_o,  // Вывод семисегментных индикаторов
  output logic [ 7:0] hex_sel_o,  // Селектор семисегментных индикаторов

  input  logic        rx_i,       // Линия приема по UART
  output logic        tx_o,       // Линия передачи по UART

  output logic [3:0]  vga_r_o,    // красный канал vga
  output logic [3:0]  vga_g_o,    // зеленый канал vga
  output logic [3:0]  vga_b_o,    // синий канал vga
  output logic        vga_hs_o,   // линия горизонтальной синхронизации vga
  output logic        vga_vs_o    // линия вертикальной синхронизации vga
);
    logic sysclk, rst;
    sys_clk_rst_gen divider(.ex_clk_i(clk_i),.ex_areset_n_i(resetn_i),.div_i(10),.sys_clk_o(sysclk), .sys_reset_o(rst));
    
    logic [31:0] instr_addr;
    logic [31:0] instr;
    logic stall;  
    
    logic [31:0] memory_addr;
    logic [31:0] memory_rd;
    logic [31:0] memory_wd;
    logic mem_req;
    logic mem_we;
    logic [3:0] memory_be;
    logic [2:0] mem_size_o;
    
    logic [31:0] memory_readdata;
    logic [31:0] memory_address;
    logic [31:0] addr_for_periph;
    logic [31:0] memory_writedata;
    logic [3:0] memory_byteenable;
    logic memory_writeenable;
    logic memory_requiered;
    
    logic [31:0] memory_out;
    logic [31:0] vga_out;
    
    logic [7:0] addr;
    assign addr = memory_address[31:24];
    assign addr_for_periph = { {8{1'b0}}, memory_address[23:0]};
    
    instr_mem instr_memory(
        .addr_i         (instr_addr),
        .read_data_o    (instr)
    );
    
    riscv_core core(
        .clk_i          (sysclk),
        .rst_i          (rst),
        .stall_i        (stall),
        .instr_i        (instr),
        .mem_rd_i       (memory_rd),
        .instr_addr_o   (instr_addr),
        .mem_addr_o     (memory_addr),
        .mem_size_o     (mem_size_o),
        .mem_req_o      (mem_req),
        .mem_we_o       (mem_we),
        .mem_wd_o       (memory_wd)
    );
    
    riscv_lsu lsu(
        .clk_i          (sysclk),
        .rst_i          (rst),
        .core_req_i     (mem_req),
        .core_we_i      (mem_we),
        .core_size_i    (mem_size_o),
        .core_addr_i    (memory_addr),
        .core_wd_i      (memory_wd),
        .core_rd_o      (memory_rd),
        .core_stall_o   (stall),
        .mem_req_o      (memory_requiered),
        .mem_we_o       (memory_writeenable),
        .mem_be_o       (memory_be),
        .mem_addr_o     (memory_address),
        .mem_wd_o       (memory_writedata),
        .mem_rd_i       (memory_readdata),
        .mem_ready_i    (1)
    );
    
    ext_mem data_mem(
        .clk_i          (sysclk),
        .mem_req_i      ((addr == 0) && memory_requiered),
        .write_enable_i (memory_writeenable),
        .byte_enable_i  (memory_be),
        .addr_i         (addr_for_periph),
        .write_data_i   (memory_writedata),
        .read_data_o    (memory_out),
        .ready_o        ()
    );
    
    vga_sb_ctrl vga_ctrl(
        .clk_i          (clk_i),
        .rst_i          (rst),
        .clk100m_i      (sysclk),
        .req_i          ((addr == 7) && memory_requiered),
        .write_enable_i (memory_writeenable),
        .mem_be_i       (memory_be),
        .addr_i         (addr_for_periph),
        .write_data_i   (memory_writedata),
        .read_data_o    (vga_out),
        .vga_r_o        (vga_r_o),
        .vga_g_o        (vga_g_o),
        .vga_b_o        (vga_b_o),
        .vga_hs_o       (vga_hs_o),
        .vga_vs_o       (vga_vs_o)
    );
    
    always_comb begin
        case(addr)
            0: memory_readdata = memory_out;
            7: memory_readdata = vga_out;
            default: memory_readdata = 0;
        endcase
    end

endmodule



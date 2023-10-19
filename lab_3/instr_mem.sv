module instr_mem(
  input  logic [31:0] addr_i,
  output logic [31:0] read_data_o
);
    logic [31:0] memory [1023:0];
    initial $readmemh("program.txt", memory);
    
  always_ff @ (posedge addr_i) begin
        if (addr_i > 4095)
            read_data_o <= 0;
        else
            read_data_o <= memory[addr_i >>> 2];
    end
endmodule

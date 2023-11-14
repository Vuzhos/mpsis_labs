module data_mem(
  input  logic        clk_i,
  input  logic        mem_req_i,
  input  logic        write_enable_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o
);

    logic [31:0] memory [4095:0];

    always_ff @(posedge clk_i) begin
        if (!mem_req_i)
            read_data_o <= 32'hfa11_1eaf;
        else if (!write_enable_i) begin
            if (addr_i > 16383)
                read_data_o <= 32'hdead_beef;
            else
                read_data_o <= memory[addr_i >>> 2];
        end
         else begin
            if (addr_i > 16383)
                read_data_o <= 32'hdead_beef;
            else
                read_data_o <= 32'hfa11_1eaf;
                memory[addr_i >>> 2] <= write_data_i;
         end
    end 
 
endmodule

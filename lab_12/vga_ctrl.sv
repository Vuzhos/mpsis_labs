module vga_sb_ctrl (
  input  logic        clk_i,
  input  logic        rst_i,
  input  logic        clk100m_i,
  input  logic        req_i,
  input  logic        write_enable_i,
  input  logic [3:0]  mem_be_i,
  input  logic [31:0] addr_i,
  input  logic [31:0] write_data_i,
  output logic [31:0] read_data_o,

  output logic [3:0]  vga_r_o,
  output logic [3:0]  vga_g_o,
  output logic [3:0]  vga_b_o,
  output logic        vga_hs_o,
  output logic        vga_vs_o
);

    logic char_map_we;
    logic col_we;
    logic char_tiff_we;

    logic [31:0] char_map_data;
    logic [31:0] col_data;
    logic [31:0] char_tiff_data;

    logic [1:0] check;
    assign check = addr_i[13:12];

    vgachargen vga(
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        .clk100m_i  (clk100m_i),
        
        .char_map_wdata_i   (write_data_i),
        .char_map_addr_i    (addr_i[11:2]),
        .char_map_be_i      (mem_be_i),
        .char_map_we_i      (char_map_we),
        .char_map_rdata_o   (char_map_data),
        
        .col_map_wdata_i    (write_data_i),
        .col_map_addr_i     (addr_i[11:2]),
        .col_map_be_i       (mem_be_i),
        .col_map_we_i       (col_we),
        .col_map_rdata_o    (col_data),
        
        .char_tiff_wdata_i  (write_data_i),
        .char_tiff_addr_i   (addr_i[11:2]),
        .char_tiff_be_i     (mem_be_i),
        .char_tiff_we_i     (char_tiff_we),
        .char_tiff_rdata_o  (char_tiff_data),
        
        .vga_r_o    (vga_r_o),
        .vga_g_o    (vga_g_o),
        .vga_b_o    (vga_b_o),
        .vga_hs_o   (vga_hs_o),
        .vga_vs_o   (vga_vs_o)
    );
    
    always_comb begin
        if(rst_i) begin
            char_map_we  = 0;
            col_we   = 0;
            char_tiff_we = 0;
        end else begin
            if (req_i) begin
                case(check)
                    0: char_map_we = write_enable_i;
                    1: col_we = write_enable_i;
                    2: char_tiff_we = write_enable_i;
                    default : begin
                        char_map_we = 0;
                        col_we = 0;
                        char_tiff_we = 0;
                    end
                endcase
            end 
        end
    end
    
    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            read_data_o <= 0;
        end else begin
            if (req_i) begin
                case(check)
                    0: read_data_o  <= char_map_data;
                    1: read_data_o  <= col_data;
                    2: read_data_o  <= char_tiff_data;
                    default : read_data_o  <= read_data_o;
                endcase
            end
        end
  end
    
endmodule

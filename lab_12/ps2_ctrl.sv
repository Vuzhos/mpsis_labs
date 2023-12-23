module ps2_sb_ctrl(
  input  logic         clk_i,
  input  logic         rst_i,
  input  logic [31:0]  addr_i,
  input  logic         req_i,
  input  logic [31:0]  write_data_i,
  input  logic         write_enable_i,
  output logic [31:0]  read_data_o,

  output logic        interrupt_request_o,
  input  logic        interrupt_return_i,

  input  logic kclk_i,
  input  logic kdata_i
);
    logic [7:0] scan_code;
    logic       scan_code_is_unread;
    logic [7:0] keycode;
    logic       keycode_is_valid;

    PS2Receiver PS2_Receiver_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .kclk_i(kclk_i),
        .kdata_i(kdata_i),
        .keycodeout_o(keycode),
        .keycode_valid_o(keycode_is_valid)
    );
    
    assign interrupt_request_o = scan_code_is_unread;

    always_ff @(posedge clk_i) begin
        if(rst_i) begin
            scan_code <= 0;
            scan_code_is_unread <= 0;
        end else begin
            case(keycode_is_valid)
                1: begin
                    scan_code <= keycode;
                    scan_code_is_unread <= 1;
                end
                0: begin
                    if(interrupt_return_i) scan_code_is_unread <= 0;
                    if(req_i && !write_enable_i) begin
                        case(addr_i)
                            0: scan_code_is_unread <= 0;
                            4: scan_code_is_unread <= scan_code_is_unread;
                            default: scan_code_is_unread <= scan_code_is_unread;
                        endcase
                    end 
                    else if(req_i && write_enable_i) begin
                        case(addr_i)
                            24: begin
                                if((write_data_i < 2) && write_data_i == 1) begin
                                    scan_code <= 0;
                                    scan_code_is_unread <= 0;
                                end else begin
                                    scan_code <= scan_code;
                                    scan_code_is_unread <= scan_code_is_unread;
                                end
                            end
                            default: begin
                                scan_code <= scan_code;
                                scan_code_is_unread <= scan_code_is_unread;
                            end
                        endcase
                    end
                end 
            endcase
        end
    end


    always_comb begin
        if(rst_i) read_data_o = 0;
        else begin
            if(req_i && !write_enable_i) begin
                case(addr_i)
                    0: read_data_o = {24'b0, scan_code};
                    4: read_data_o = {31'b0, scan_code_is_unread};
                    default: read_data_o = read_data_o;
                endcase
            end 
        end
    end

endmodule

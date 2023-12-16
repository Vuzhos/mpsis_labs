module ps2_sb_ctrl(
/*
    Часть интерфейса модуля, отвечающая за подключение к системной шине
*/
    input  logic         clk_i,
    input  logic         rst_i,
    input  logic [31:0]  addr_i,
    input  logic         req_i,
    input  logic [31:0]  write_data_i,
    input  logic         write_enable_i,
    output logic [31:0]  read_data_o,

/*
    Часть интерфейса модуля, отвечающая за отправку запросов на прерывание
    процессорного ядра
*/

    output logic        interrupt_request_o,
    input  logic        interrupt_return_i,

/*
    Часть интерфейса модуля, отвечающая за подключение к модулю,
    осуществляющему прием данных с клавиатуры
*/
    input  logic kclk_i,
    input  logic kdata_i
);

    logic [7:0] scan_code;
    logic       scan_code_is_unread;
    
    logic keycode_valid;
    logic [7:0] keycode;
    
    PS2Receiver ps2(
        .clk_i (clk_i),
        .rst_i (rst_i),
        .kclk_i (kclk_i),
        .kdata_i (kdata_i),
        .keycodeout_o (keycode),
        .keycode_valid_o (keycode_valid)
    );
      
    always_ff @ (posedge clk_i) begin
        if(rst_i) begin
            scan_code <= 0;
            scan_code_is_unread <= 0;
        end
        else begin
            if (keycode_valid) begin
                scan_code <= keycode;
                scan_code_is_unread <= 1;
            end
            else if (interrupt_return_i) scan_code_is_unread <= 0;
        
            if (req_i) begin
                if (write_enable_i) begin
                    if (addr_i == 32'h24) begin
                        scan_code <= 0;
                        scan_code_is_unread <= 0;
                    end
                end
                else begin
                    if (addr_i == 0) begin
                        read_data_o <= {{24{1'b0}}, scan_code};
                        if (!keycode_valid) scan_code_is_unread <= 0;
                    end
                    else if (addr_i == 32'h4) read_data_o <= {{31{1'b0}}, scan_code_is_unread};
                end
            end
        end
    end
    
    assign interrupt_request_o = scan_code_is_unread;
endmodule

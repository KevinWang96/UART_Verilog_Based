/*
 * @Author: Yihao Wang
 * @Date: 2020-05-03 02:13:15
 * @LastEditTime: 2020-05-04 21:41:28
 * @LastEditors: Please set LastEditors
 * @Description: Testbench for data transfering between uart_tx_top and uart_rx_top
 * @FilePath: /uart/tb/tb_tx_rx_top.v
 */
 `timescale 1ns/1ps
 module tb_tx_rx_top;

    parameter   FRAME_WIDTH     =   10;
    parameter   BAUD_RATE       =   19200;
    parameter   SYS_CLK_FREQ    =   200_000_000;
    parameter   SYS_CYCLE_TIME  =   1_000_000_000 / SYS_CLK_FREQ;
    parameter   BIT_CYCLE_TIME  =   1_000_000_000 / BAUD_RATE;

    
    reg                         sys_clk;
    reg                         reset;
    reg                         uart_tx_en;
    reg [0:FRAME_WIDTH - 1]     uart_tx_din;

    wire                        uart_tx_dout;
    wire                        uart_tx_done;

    uart_tx_top #(
        .SYS_CLK_FREQ   (SYS_CLK_FREQ),
        .BAUD_RATE      (BAUD_RATE),
        .FRAME_WIDTH    (FRAME_WIDTH)
    )
    uart_tx_top_dut 
    (
        .sys_clk(sys_clk),
        .reset(reset),
        .uart_tx_en(uart_tx_en),
        .uart_tx_din(uart_tx_din),
        .uart_tx_dout(uart_tx_dout),
        .uart_tx_done(uart_tx_done),
        .uart_tx_bit_clk()
    );

    wire    [0:FRAME_WIDTH - 1]     uart_rx_dout;
    wire                            uart_rx_done;
    wire                            uart_rx_data_error;
    wire                            uart_rx_frame_error;

    uart_rx_top #(
        .SYS_CLK_FREQ(SYS_CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .FRAME_WIDTH(FRAME_WIDTH)
    )
    uart_rx_top_inst
    (
        .sys_clk(sys_clk),
        .reset(reset),
        .uart_rx_din(uart_tx_dout),
        .uart_rx_dout(uart_rx_dout),
        .uart_rx_done(uart_rx_done),
        .uart_rx_data_error(uart_rx_data_error),
        .uart_rx_frame_error(uart_rx_frame_error),
        .uart_rx_sample_clk()
    );

    always #(0.5 * SYS_CYCLE_TIME) sys_clk = ~ sys_clk;

    integer file;
    initial begin : test
        integer i;

        sys_clk = 1;
        reset = 1;
        uart_tx_en = 0;

        #(3.5 * BIT_CYCLE_TIME)
        reset = 0;

        for(i = 1; i <= 2 ** FRAME_WIDTH; i = i + 1) begin
            if(uart_tx_done) begin
                uart_tx_en = 1;
                uart_tx_din = i;
            end
            else begin
                uart_tx_en = 0;
                i = i - 1;
            end
            #(BIT_CYCLE_TIME);
        end

        #(50 * BIT_CYCLE_TIME)
        $fclose(file);
        $finish;
    end

    initial begin
        file = $fopen("./output.log", "w");
    end

    wire    sample_clk  =   uart_rx_top_inst.sample_clk_i;
    always @(posedge sample_clk) begin
        if(uart_rx_done)
            $fdisplay(file, "data(decimal): %1d, data(binary): %b, data_error: %b, frame_error: %b", 
                        uart_rx_dout, uart_rx_dout, uart_rx_data_error, uart_rx_frame_error);
    end

 endmodule
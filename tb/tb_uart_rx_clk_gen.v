/*
 * @Author: Yihao Wang
 * @Date: 2020-05-02 19:39:22
 * @LastEditTime: 2020-05-03 00:06:39
 * @LastEditors: Please set LastEditors
 * @Description: Testbench for uart_rx_clk_gen.v
 * @FilePath: /uart/tb/tb_uart_tx_clk_gen.v
 */
 `timescale 1ns/1ps
 module tb_uart_rx_clk_gen;

    parameter   SYS_CLK_FREQ    =   200_000_000;
    parameter   BAUD_RATE       =   19200;

    parameter   CYCLE_TIME      =   1_000_000_000 / SYS_CLK_FREQ;

    reg     sys_clk;
    reg     reset;
    wire    sample_clk;

    always #(0.5 * CYCLE_TIME) sys_clk = ~ sys_clk;

    // dut 
    uart_rx_clk_gen #(
        .SYS_CLK_FREQ   (SYS_CLK_FREQ),
        .BAUD_RATE      (BAUD_RATE)
    )
    uart_rx_clk_gen_dut
    (
        .sys_clk        (sys_clk),
        .reset          (reset), 
        .sample_clk     (sample_clk)
    );

    initial begin
        sys_clk = 1;
        reset = 1;

        #(3.5 * CYCLE_TIME)
        reset = 0;

        #5000000 // 5ms
        $finish;        
    end

 endmodule
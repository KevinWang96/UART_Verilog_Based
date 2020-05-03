/*
 * @Author: Yihao Wang
 * @Date: 2020-05-03 00:45:30
 * @LastEditTime: 2020-05-03 00:58:16
 * @LastEditors: Please set LastEditors
 * @Description: Top module of UART Rx (integrate clk_gen and receive_logic)
 * @FilePath: /uart/src/uart_rx_top.v
 */
 `timescale 1ns/1ps
 module uart_rx_top #(
     parameter  SYS_CLK_FREQ    =   200_000_000,
     parameter  BAUD_RATE       =   19200,  // target baud rate: 9600, 19200, 38400, 57600, 115200, etc
     parameter  FRAME_WIDTH     =   8
 )
 (
     sys_clk,
     reset,
     uart_rx_din,
     uart_rx_dout,
     uart_rx_done,
     uart_rx_data_error,
     uart_rx_frame_error
 );

    input                       sys_clk;
    input                       reset;
    input                       uart_rx_din;
    output  [0:FRAME_WIDTH - 1] uart_rx_dout;
    output                      uart_rx_done;
    output                      uart_rx_data_error;
    output                      uart_rx_frame_error;

    wire                        sample_clk;

    uart_rx_receive_logic #(
        .FRAME_WIDTH            (FRAME_WIDTH)
    )
    uart_rx_receive_logic_inst
    (
        .sample_clk             (sample_clk),
        .reset                  (reset),
        .uart_rx_din            (uart_rx_din),
        .uart_rx_dout           (uart_rx_dout),
        .uart_rx_done           (uart_rx_done),
        .uart_rx_data_error     (uart_rx_data_error),
        .uart_rx_frame_error    (uart_rx_frame_error)
    );

    uart_rx_clk_gen #(
        .SYS_CLK_FREQ           (SYS_CLK_FREQ),
        .BAUD_RATE              (BAUD_RATE)
    )
    uart_rx_clk_gen_inst
    (
        .sys_clk                (sys_clk),
        .reset                  (reset),
        .sample_clk             (sample_clk)
    );

 endmodule
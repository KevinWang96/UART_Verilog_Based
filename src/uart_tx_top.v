/*
 * @Author: Yihao Wang
 * @Date: 2020-05-03 00:23:42
 * @LastEditTime: 2020-05-03 03:13:55
 * @LastEditors: Please set LastEditors
 * @Description: Top module of UART Tx (integrate clk_gen and send_logic)
 * @FilePath: /uart/src/uart_tx_top.v
 */
 `timescale 1ns/1ps
 module uart_tx_top #(
     parameter  SYS_CLK_FREQ    =   200_000_000,
     parameter  BAUD_RATE       =   19200,      // target baud rate: 9600, 19200, 38400, 57600, 115200, etc
     parameter  FRAME_WIDTH     =   8
 )
 (
     sys_clk,
     reset,
     uart_tx_en,
     uart_tx_din,
     uart_tx_dout,
     uart_tx_done,
     uart_tx_bit_clk
 );

    input                       sys_clk;
    input                       reset;
    input                       uart_tx_en;
    input   [0:FRAME_WIDTH - 1] uart_tx_din;
    output                      uart_tx_dout;
    output                      uart_tx_done;
    output                      uart_tx_bit_clk;    // used by Tx async FIFO

    wire                        bit_clk_i;
    assign  uart_tx_bit_clk =   bit_clk_i;

    uart_tx_send_logic #(
        .FRAME_WIDTH    (FRAME_WIDTH)
    )
    uart_tx_send_logic_inst
    (
        .bit_clk        (bit_clk_i),
        .reset          (reset),
        .uart_tx_en     (uart_tx_en),
        .uart_tx_din    (uart_tx_din),
        .uart_tx_dout   (uart_tx_dout),
        .uart_tx_done   (uart_tx_done)
    );

    uart_tx_clk_gen #(
        .SYS_CLK_FREQ   (SYS_CLK_FREQ),
        .BAUD_RATE      (BAUD_RATE)
    )
    uart_tx_clk_gen_inst
    (
        .sys_clk        (sys_clk),
        .reset          (reset),
        .bit_clk        (bit_clk_i)
    );

 endmodule
/*
 * @Author: Yihao Wang
 * @Date: 2020-05-03 15:43:13
 * @LastEditTime: 2020-05-04 01:43:32
 * @LastEditors: Please set LastEditors
 * @Description: IP module of UART, supporting duplex transferring
 * @FilePath: /uart/src/uart_ip_top.v
 */
 `timescale 1ns/1ps
 module uart_ip_top #(
     parameter  FRAME_WIDTH     =   8,
     parameter  FIFO_DEPTH      =   128,    
     parameter  BAUD_RATE       =   12800,
     parameter  SYS_CLK_FREQ    =   2_000_000_000
 )
 (
     sys_clk,
     reset,
     din,
     ri,
     si,
     tx,
     dout,
     ro, 
     so,
     rx
 );
    
    input                       sys_clk;    // system logic
    input                       reset;      // async active high
    input   [0:FRAME_WIDTH - 1] din;
    input                       si;         // send of input port
    output                      ri;         // ready of input port
    output                      tx;         // 1-bit serial data output line
    output  [0:FRAME_WIDTH - 1] dout;
    input                       ro;         // ready pf output port
    output                      so;         // send of output port
    input                       rx;         // 1-bit serial data in line
    

    // Input buffer control signals
    wire                        in_buf_full;
    wire                        in_buf_w_en;
    wire    [0:FRAME_WIDTH - 1] in_buf_w_din;
    wire                        in_buf_empty;
    wire                        in_buf_r_en;
    wire    [0:FRAME_WIDTH - 1] in_buf_r_dout;

    // Output buffer control signals
    wire                        out_buf_full;
    wire                        out_buf_w_en;
    wire    [0:FRAME_WIDTH - 1] out_buf_w_din;
    wire                        out_buf_empty;
    wire                        out_buf_r_en;
    wire    [0:FRAME_WIDTH - 1] out_buf_r_dout;

    // Tx logic control signals
    wire                        bit_clk;
    wire                        uart_tx_en;
    wire    [0:FRAME_WIDTH - 1] uart_tx_din;
    wire                        uart_tx_dout;
    wire                        uart_tx_done;

    // Rx logic control signals
    wire                        sample_clk;
    wire                        uart_rx_din;
    wire    [0:FRAME_WIDTH - 1] uart_rx_dout;
    wire                        uart_rx_done;
    wire                        uart_rx_data_error;
    wire                        uart_rx_frame_error;

    
    // Async FIFO of input channel
    async_fifo #(
        .DEPTH              (FIFO_DEPTH),
        .WIDTH              (FRAME_WIDTH)
    )
    in_buf
    (
        .reset              (reset),

        .r_clk              (bit_clk),
        .r_en               (in_buf_r_en),
        .r_dout             (in_buf_r_dout),
        .r_depth            (),
        .r_empty            (in_buf_empty),

        .w_clk              (sys_clk),
        .w_en               (in_buf_w_en),
        .w_din              (in_buf_w_din),
        .w_depth            (),
        .w_full             (in_buf_full)
    );

    // Tx logic module
    uart_tx_top #(
        .SYS_CLK_FREQ       (SYS_CLK_FREQ),
        .BAUD_RATE          (BAUD_RATE),
        .FRAME_WIDTH        (FRAME_WIDTH)
    )
    tx_inst
    (
        .sys_clk            (sys_clk),
        .reset              (reset),
        .uart_tx_en         (uart_tx_en),
        .uart_tx_din        (uart_tx_din),
        .uart_tx_dout       (uart_tx_dout),
        .uart_tx_done       (uart_tx_done),
        .uart_tx_bit_clk    (bit_clk)
    );

    // Async FIFO of output channel
    async_fifo #(
        .DEPTH              (FIFO_DEPTH),
        .WIDTH              (FRAME_WIDTH)
    )
    out_buf
    (
        .reset              (reset),

        .r_clk              (sys_clk),
        .r_en               (out_buf_r_en),
        .r_dout             (out_buf_r_dout),
        .r_depth            (),
        .r_empty            (out_buf_empty),

        .w_clk              (sample_clk),
        .w_en               (out_buf_w_en),
        .w_din              (out_buf_w_din),
        .w_depth            (),
        .w_full             (out_buf_full)
    );

    // Rx logic module
    uart_rx_top #(
        .SYS_CLK_FREQ           (SYS_CLK_FREQ),
        .BAUD_RATE              (BAUD_RATE),
        .FRAME_WIDTH            (FRAME_WIDTH)
    )
    rx_inst
    (
        .sys_clk                (sys_clk),
        .reset                  (reset),
        .uart_rx_din            (uart_rx_din),
        .uart_rx_dout           (uart_rx_dout),
        .uart_rx_done           (uart_rx_done),
        .uart_rx_data_error     (uart_rx_data_error),
        .uart_rx_frame_error    (uart_rx_frame_error),
        .uart_rx_sample_clk     (sample_clk)
    );

    // Input channel logic
    assign  ri              =   si & (!in_buf_full);
    assign  in_buf_w_en     =   ri;
    assign  in_buf_w_din    =   (in_buf_w_en) ? din : 0;

    assign  in_buf_r_en     =   uart_tx_done & (!in_buf_empty);
    assign  uart_tx_en      =   uart_tx_done & (!in_buf_empty);
    assign  uart_tx_din     =   in_buf_r_dout;

    assign  tx              =   uart_tx_dout;

    // Output channel logic
    assign  so              =   (!out_buf_empty);
    assign  out_buf_r_en    =   so & ro;
    assign  dout            =   (out_buf_r_en) ? out_buf_r_dout : 0;

    assign  out_buf_w_en    =  uart_rx_done & (!out_buf_full);
    assign  out_buf_w_din   =  (out_buf_w_en) ? uart_rx_dout : 0;
    
    assign  uart_rx_din     =   rx;

 endmodule      
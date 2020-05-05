/*
 * @Author: Yihao Wang
 * @Date: 2020-05-03 15:43:13
 * @LastEditTime: 2020-05-04 22:11:55
 * @LastEditors: Please set LastEditors
 * @Description: IP module of UART, supporting duplex transferring
 * @FilePath: /uart/src/uart_ip_top.v
 */
 `define CHAR_XON 8'd17
 `define CHAR_XOFF 8'd19
 `timescale 1ns/1ps
 module uart_ip_top #(
     parameter  FRAME_WIDTH     =   8,
     parameter  FIFO_DEPTH      =   128,    
     parameter  BAUD_RATE       =   12800,
     parameter  SYS_CLK_FREQ    =   2_000_000_000,
     parameter  BUF_HIGH_LIMIT  =   90,             
     parameter  BUF_LOW_LIMIT   =   38
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
    wire    [0:$clog2(FIFO_DEPTH)]  out_buf_w_depth;

    // Tx logic control signals
    wire                        bit_clk;
    wire                        uart_tx_en;
    reg     [0:FRAME_WIDTH - 1] uart_tx_din;
    wire                        uart_tx_dout;
    wire                        uart_tx_done;

    // Rx logic control signals
    wire                        sample_clk;
    wire                        uart_rx_din;
    wire    [0:FRAME_WIDTH - 1] uart_rx_dout;
    wire                        uart_rx_done;
    wire                        uart_rx_data_error;
    wire                        uart_rx_frame_error;

    // Flow control signals
    wire                        xon_detect;
    reg                         xon_detect_s;           // 1-clock synchronization
    reg                         xon_detect_ss;          // 2-clock synchronization
    wire                        xoff_detect;
    reg                         xoff_detect_s;          // 1-clock synchronization
    reg                         xoff_detect_ss;         // 2-clock synchronization
    reg                         tx_stop_flag;           // 1: stop sending due to XOFF

    wire                        rx_buf_almost_full;     // if almost full, ask tx to send XOFF
    wire                        rx_buf_almost_empty;    // if almost empty, ask rx to send XON
    reg                         rx_buf_almost_full_s;
    reg                         rx_buf_almost_full_ss;
    reg                         rx_buf_almost_full_ss_d;
    reg                         rx_buf_almost_empty_s;
    reg                         rx_buf_almost_empty_ss;
    reg                         rx_buf_almost_empty_ss_d;

    wire                        tx_send_xoff;           // rx asks tx to send XOFF
    wire                        tx_send_xon;            // rx asks tx to send XON

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
        .w_depth            (out_buf_w_depth),
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

    // Detect flow control character
    assign  xon_detect      =   uart_rx_done & (uart_rx_dout == `CHAR_XON);
    assign  xoff_detect     =   uart_rx_done & (uart_rx_dout == `CHAR_XOFF);

    always @(posedge bit_clk, posedge reset) begin // double synchronization
        if(reset) begin
            xon_detect_s <= 0;
            xon_detect_ss <= 0;
            xoff_detect_s <= 0;
            xoff_detect_ss <= 0;
        end
        else begin
            xon_detect_s <= xon_detect;
            xon_detect_ss <= xon_detect_s;
            xoff_detect_s <= xoff_detect;
            xoff_detect_ss <= xoff_detect_s;
        end
    end

    always @(posedge bit_clk, posedge reset) begin
        if(reset) tx_stop_flag <= 0;
        else begin
            if(xoff_detect_ss) tx_stop_flag <= 1;
            if(xon_detect_ss) tx_stop_flag <= 0;
        end
    end

    // Detect the status of Rx buffer
    assign  rx_buf_almost_full  =   (out_buf_w_depth >= BUF_HIGH_LIMIT);
    assign  rx_buf_almost_empty =   (out_buf_w_depth <= BUF_LOW_LIMIT);

    always @(posedge bit_clk, posedge reset) begin // double synchronization and posedge detection
        if(reset) begin
            rx_buf_almost_empty_s <= 0;
            rx_buf_almost_empty_ss <= 0;
            rx_buf_almost_empty_ss_d <= 0;
            rx_buf_almost_full_s <= 0;
            rx_buf_almost_full_ss <= 0;
            rx_buf_almost_full_ss_d <= 0;
        end
        else begin
            rx_buf_almost_empty_s <= rx_buf_almost_empty;
            rx_buf_almost_empty_ss <= rx_buf_almost_empty_s;
            rx_buf_almost_empty_ss_d <= rx_buf_almost_empty_ss;
            rx_buf_almost_full_s <= rx_buf_almost_full;
            rx_buf_almost_full_ss <= rx_buf_almost_full_s;
            rx_buf_almost_full_ss_d <= rx_buf_almost_full_ss;
        end
    end

    assign  tx_send_xoff    =   (~rx_buf_almost_full_ss_d) & rx_buf_almost_full_ss;
    assign  tx_send_xon     =   (~rx_buf_almost_empty_ss_d) & rx_buf_almost_empty_ss;

    // Input channel logic
    assign  ri              =   si & (!in_buf_full);
    assign  in_buf_w_en     =   ri;
    assign  in_buf_w_din    =   (in_buf_w_en) ? din : 0;

    assign  in_buf_r_en     =   uart_tx_done & (~in_buf_empty) & (~tx_stop_flag) & (~tx_send_xoff) & (~tx_send_xon);
    assign  uart_tx_en      =   (uart_tx_done & (~in_buf_empty) & (~tx_stop_flag)) | tx_send_xoff | tx_send_xon;
    
    always @(*) begin // uart_tx_din
        if(tx_send_xoff) uart_tx_din = `CHAR_XOFF; // sending XOFF has highest priority
        else if(tx_send_xon) uart_tx_din = `CHAR_XON;
        else uart_tx_din = in_buf_r_dout;
    end

    assign  tx              =   uart_tx_dout;

    // Output channel logic
    assign  so              =   (!out_buf_empty);
    assign  out_buf_r_en    =   so & ro;
    assign  dout            =   (out_buf_r_en) ? out_buf_r_dout : 0;

    assign  out_buf_w_en    =  uart_rx_done & (!out_buf_full);
    assign  out_buf_w_din   =  (out_buf_w_en) ? uart_rx_dout : 0;
    
    assign  uart_rx_din     =   rx;

 endmodule      
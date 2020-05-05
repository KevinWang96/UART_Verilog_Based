/*
 * @Author: Yihao Wang
 * @Date: 2020-05-04 00:07:07
 * @LastEditTime: 2020-05-04 21:55:14
 * @LastEditors: Please set LastEditors
 * @Description: Testbench for uart_ip_top.v
 * @FilePath: /uart/tb/tb_uart_ip_top.v
 */
 `timescale 1ns/1ps
 module tb_uart_ip_top;

    parameter   SYS_CLK_FREQ    =   200_000_000;
    parameter   BAUD_RATE       =   19200;
    parameter   FRAME_WIDTH     =   8;
    parameter   FIFO_DEPTH      =   128;
    parameter   SYS_CYCLE_TIME  =   1_000_000_000 / SYS_CLK_FREQ;

    reg                         sys_clk;
    reg                         reset;

    reg     [0:FRAME_WIDTH - 1] din_0;
    reg                         si_0;
    wire                        ri_0;

    wire    [0:FRAME_WIDTH - 1] dout_0;
    reg                         ro_0;
    wire                        so_0;

    wire                        tx_0;
    wire                        rx_0;


    reg     [0:FRAME_WIDTH - 1] din_1;
    reg                         si_1;
    wire                        ri_1;

    wire    [0:FRAME_WIDTH - 1] dout_1;
    reg                         ro_1;
    wire                        so_1;

    wire                        tx_1;
    wire                        rx_1;

    assign  rx_1    =   tx_0;
    assign  rx_0    =   tx_1;

//////////////////////////////////////////////////////////
    // Probe
    wire    [0:ip_0.in_buf.PTR_WIDTH - 1]   in_buf_r_ptr;
    wire                        tx_en_0;
    wire                        in_buf_r_en_0;
    wire                        in_buf_empty_0;
    wire    [0:FRAME_WIDTH - 1] in_buf_r_dout_0;
    wire    [0:FRAME_WIDTH - 1] tx_din_0;

    assign  in_buf_r_ptr        =   ip_0.in_buf.r_ptr;
    assign  tx_en_0             =   ip_0.uart_tx_en;
    assign  in_buf_r_en_0       =   ip_0.in_buf_r_en;
    assign  in_buf_empty_0      =   ip_0.in_buf_empty;
    assign  in_buf_r_dout_0     =   ip_0.in_buf_r_dout;
    assign  tx_din_0            =   ip_0.uart_tx_din;
//////////////////////////////////////////////////////////

    uart_ip_top #(
        .SYS_CLK_FREQ   (SYS_CLK_FREQ),
        .BAUD_RATE      (BAUD_RATE),
        .FIFO_DEPTH     (FIFO_DEPTH),
        .FRAME_WIDTH    (FRAME_WIDTH)
    )
    ip_0
    (
        .sys_clk        (sys_clk),
        .reset          (reset),
        .din            (din_0),
        .ri             (ri_0),
        .si             (si_0),
        .dout           (dout_0),
        .ro             (ro_0),
        .so             (so_0),
        .tx             (tx_0),
        .rx             (rx_0)
    );

    uart_ip_top #(
        .SYS_CLK_FREQ   (SYS_CLK_FREQ),
        .BAUD_RATE      (BAUD_RATE),
        .FIFO_DEPTH     (FIFO_DEPTH),
        .FRAME_WIDTH    (FRAME_WIDTH)
    )
    ip_1
    (
        .sys_clk        (sys_clk),
        .reset          (reset),
        .din            (din_1),
        .ri             (ri_1),
        .si             (si_1),
        .dout           (dout_1),
        .ro             (ro_1),
        .so             (so_1),
        .tx             (tx_1),
        .rx             (rx_1)
    );

    always #(0.5 * SYS_CYCLE_TIME) sys_clk = ~ sys_clk;

    integer log_file;

    initial begin : Test
        integer i;

        log_file = $fopen("./uart_ip_top.log", "w");
        sys_clk = 1;
        reset = 1;
        si_0 = 0;
        ro_0 = 0;
        si_1 = 0;
        ro_1 = 0;

        #(3.5 * SYS_CYCLE_TIME)
        reset = 0;

        for(i = 1; i <= 2 ** FRAME_WIDTH; i = i + 1) begin
            si_0 = 1;
            din_0 = i;
            if(ri_0 == 0) i = i - 1;

            #(SYS_CYCLE_TIME);
        end
        si_0 = 0;

         #(1_000_000_000);
         $fclose(log_file);
         $finish;
    end

    always @(posedge sys_clk) begin
        ro_1 = 1;
        if(so_1)
            $fdisplay(log_file, "data(decimal): %1d, data(binary): %b;", dout_1, dout_1);
        #(SYS_CYCLE_TIME) ro_1 = 0;
        #(250_000);  // decrease read speed to test flow control
    end

 endmodule
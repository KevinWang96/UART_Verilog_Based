/*
 * @Author: Yihao Wang
 * @Date: 2020-05-02 01:33:13
 * @LastEditTime: 2020-05-02 02:42:14
 * @LastEditors: Please set LastEditors
 * @Description: Testbench for uart_tx_send_logic.v
 * @FilePath: /uart/tb/tb_uart_send_logic.v
 */
 `timescale 1ns/1ps
 module tb_uart_tx_send_logic;

    parameter   DATA_FRAME_WIDTH    =   4;
    parameter   CYCLE_TIME          =   5;
    parameter   NUM_TEST            =   5;
    
    reg                             bit_clk;
    reg                             reset;
    reg                             uart_tx_en;
    reg [0:DATA_FRAME_WIDTH - 1]    uart_tx_din;

    wire                            uart_tx_dout;
    wire                            uart_tx_done;

    always #(0.5 * CYCLE_TIME) bit_clk = ~ bit_clk;

    // dut
    uart_tx_send_logic #(
        .DATA_FRAME_WIDTH   (DATA_FRAME_WIDTH),
        .PARITY             (0)
    )
    uart_tx_send_logic_dut
    (
        .bit_clk        (bit_clk),
        .reset          (reset),
        .uart_tx_en     (uart_tx_en),
        .uart_tx_din    (uart_tx_din),
        .uart_tx_dout   (uart_tx_dout),
        .uart_tx_done   (uart_tx_done)
    );

    initial begin : test
        integer i;

        bit_clk = 1;
        reset = 1;
        uart_tx_en = 0;

        #(3.5 * CYCLE_TIME)
        reset = 0;

        for(i = 1; i < NUM_TEST + 1; i = i + 1) begin
            if(uart_tx_done) begin
                uart_tx_en = 1;
                uart_tx_din = i;
            end
            else begin
                uart_tx_en = 0;
                i = i - 1;
            end
            #(CYCLE_TIME);
        end

        #(5 * CYCLE_TIME)
        $finish;
    end

 endmodule
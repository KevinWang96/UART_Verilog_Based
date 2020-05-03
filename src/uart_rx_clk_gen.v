/*
 * @Author: your name
 * @Date: 2020-05-02 22:01:27
 * @LastEditTime: 2020-05-03 00:42:20
 * @LastEditors: Please set LastEditors
 * @Description: 
 *      a. Clock generator of Rx side 
 *      b. Divides system clock and generates sample_clock
 * @FilePath: /uart/src/uart_rx_clk_gen.v
 */
 `timescale 1ns/1ps
 module uart_rx_clk_gen #(
     parameter  SYS_CLK_FREQ    =   200_000_000,    // frequency of sys_clk (Hz)
     parameter  BAUD_RATE       =   19200           // target baud rate: 9600, 19200, 38400, 57600, 115200, etc
 )
 (
     sys_clk, 
     reset,
     sample_clk
 );

    input   sys_clk;        // positive edge triggering
    input   reset;          // async reset
    output  sample_clk;

    localparam  COUNT_VALUE =   SYS_CLK_FREQ / (BAUD_RATE * 16);   // the count value of counter

    reg                             sample_dff;     // a DFF is used to sample sample_clk to make it glitch-free
    reg [0:$clog2(COUNT_VALUE) - 1] counter;        // counter
    wire                            find_count;     // asserted when count value is equal to (COUNT_VALUE - 1)

    assign  sample_clk =   sample_dff;

    assign  find_count  =   (counter == COUNT_VALUE - 1);

    always @(posedge sys_clk, posedge reset) begin
        if(reset) begin
            counter <= 0;
            sample_dff <= 0;
        end
        else begin
            if(find_count) counter <= 0;
            else counter <= counter + 1;

            sample_dff <= find_count;
        end
    end

 endmodule
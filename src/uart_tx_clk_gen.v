/*
 * @Author: Yihao Wang
 * @Date: 2020-05-02 03:52:38
 * @LastEditTime: 2020-05-02 04:12:17
 * @LastEditors: Please set LastEditors
 * @Description: 
 *      a. Clock generator of Tx side 
 *      b. Divides system clock and generates bit_clock that satisfies 
            target baud rate 
 * @FilePath: /uart/src/uart_tx_clk_gen.v
 */
 module uart_tx_clk_gen #(
     parameter  SYS_CLK_FREQ    =   2_000_000;  // frequency of sys_clk (Hz)
     parameter  BAUD_RATE       =   19200;      // target baud rate: 9600, 19200, 38400, 57600, 115200, etc
 )
 (
     sys_clk, 
     reset,
     bit_clk
 );

    input   sys_clk;        // positive edge triggering
    input   reset;          // sync reset
    output  bit_clk;

    localparam  COUNT_VALUE =   SYS_CLK_FREQ / BAUD_RATE;   // the count value of counter

    reg                             sample_dff;     // a DFF is used to sample bit_clk to make it glitch-free
    reg [0:$clog2(COUNT_VALUE) - 1] counter;        // counter
    wire                            find_count;     // asserted when count value is equal to (COUNT_VALUE - 1)

    assign  bit_clk =   sample_dff;

    assign  find_count  =   (counter == COUNT_VALUE - 1);

    always @(posedge sys_clk) begin
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
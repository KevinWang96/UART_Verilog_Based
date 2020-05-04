/*
 * @Author: Yihao Wang
 * @Date: 2020-05-03 06:07:10
 * @LastEditTime: 2020-05-04 02:08:35
 * @LastEditors: Please set LastEditors
 * @Description: 
 *      a. Asynchronous FIFO supports one read port and one write port
 *      b. Register array based, write is synchronous and read is asynchronous
 * @FilePath: /uart/src/async_fifo.v
 */
 `timescale 1ns/1ps
 module async_fifo #(
     parameter  DEPTH   =   128,
     parameter  WIDTH   =   8
 )
 (
     reset,
     
     r_clk,
     r_en,
     r_dout,
     r_depth,
     r_empty,

     w_clk,
     w_en, 
     w_din,
     w_depth,
     w_full
 );
    
    localparam  PTR_WIDTH   =   $clog2(DEPTH) + 1;  // (n+1)-bit pointer

    input                       reset;
    input                       r_clk;
    input                       r_en;
    output  [0:WIDTH - 1]       r_dout;
    output  [0:PTR_WIDTH - 1]   r_depth;
    output  r_empty;

    input                       w_clk;
    input                       w_en;
    input   [0:WIDTH - 1]       w_din;
    output  [0:PTR_WIDTH - 1]   w_depth;
    output                      w_full;

    reg     [0:PTR_WIDTH - 1]   r_ptr;
    wire    [0:PTR_WIDTH - 1]   r_ptr_g;        // grey code
    reg     [0:PTR_WIDTH - 1]   r_ptr_g_s;      // after one clock synchronization
    reg     [0:PTR_WIDTH - 1]   r_ptr_g_ss;     // after two clock synchronization
    reg     [0:PTR_WIDTH - 1]   r_ptr_g_ss_b;   // grey code to binary

    reg     [0:PTR_WIDTH - 1]   w_ptr;
    wire    [0:PTR_WIDTH - 1]   w_ptr_g;        // grey code
    reg     [0:PTR_WIDTH - 1]   w_ptr_g_s;      // after one clock synchronization
    reg     [0:PTR_WIDTH - 1]   w_ptr_g_ss;     // after two clock synchronization
    reg     [0:PTR_WIDTH - 1]   w_ptr_g_ss_b;   // grey code to binary

    wire    [0:PTR_WIDTH - 1]   diff_r;
    wire    [0:PTR_WIDTH - 1]   diff_w;

    // Register array
    reg [0:WIDTH - 1]   mem [0:DEPTH - 1];

    // binary to grey code 
    assign  r_ptr_g         =   ((r_ptr >> 1) ^ r_ptr);
    assign  w_ptr_g         =   ((w_ptr >> 1) ^ w_ptr);

    // grey code to binary
    always @(*) begin : grey_to_binary
        integer i;
        for(i = 0; i < PTR_WIDTH; i = i + 1) begin
            if(i == 0) begin
                r_ptr_g_ss_b[i] = r_ptr_g_ss[i];
                w_ptr_g_ss_b[i] = w_ptr_g_ss[i];
            end
            else begin
                r_ptr_g_ss_b[i] = r_ptr_g_ss[i] ^ r_ptr_g_ss_b[i - 1];
                w_ptr_g_ss_b[i] = w_ptr_g_ss[i] ^ w_ptr_g_ss_b[i - 1];
            end
        end
    end

    // Two clock synchronization of r_ptr
    always @(posedge w_clk, posedge reset) begin
        if(reset) begin
            r_ptr_g_s <= 0;
            r_ptr_g_ss <= 0;
        end
        else begin
            r_ptr_g_s <= r_ptr_g;
            r_ptr_g_ss <= r_ptr_g_s;
        end
    end

    // Two clock synchronization of w_ptr
    always @(posedge r_clk, posedge reset) begin
        if(reset) begin
            w_ptr_g_s <= 0;
            w_ptr_g_ss <= 0;
        end
        else begin
            w_ptr_g_s <= w_ptr_g;
            w_ptr_g_ss <= w_ptr_g_s;
        end
    end

    // Generates depth, full and empty signals
    assign  diff_r  =   w_ptr_g_ss_b - r_ptr;
    assign  diff_w  =   w_ptr - r_ptr_g_ss_b;

    assign  r_empty =   (diff_r == 0);
    assign  r_depth =   diff_r;

    assign  w_full  =   (diff_w == DEPTH);
    assign  w_depth =   diff_w;

    // Data reading
    assign  r_dout  =   mem[r_ptr[1:PTR_WIDTH - 1]];
    always @(posedge r_clk, posedge reset) begin
        if(reset) r_ptr <= 0;
        else if(r_en)
            r_ptr <= r_ptr + 1;
    end

    // Data writing
    always @(posedge w_clk, posedge reset) begin
        if(reset) w_ptr <= 0;
        else if(w_en) begin
            mem[w_ptr[1:PTR_WIDTH - 1]] <= w_din;
            w_ptr <= w_ptr + 1;
        end
    end

 endmodule
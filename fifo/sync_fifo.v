// this module use pointer to argue the empty and full flag
// it is difficult to argue the empty and full flag in this module
// main reason is empty to full or full to empty is hard to deal, especially i_wren && i_rden
// thus, i_wren and i_rden generate can be controlled by outer interface
`timescale 1ns/1ps
module sync_fifo #(
    parameter WIDTH = 32,
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    i_clk,
    i_rstn,

    i_wren,
    i_rden,
    i_wdata,
    
    o_rdata,
    o_empty,
    o_full
);
    input           i_clk;
    input           i_rstn;

    input           i_wren;
    input           i_rden;
    input [31:0]    i_wdata;

    output [31:0]   o_rdata;
    output          o_empty;
    output          o_full;
    
    reg                full;
    reg                empty;
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;
    reg [ADDR_WIDTH:0] next_rptr;
    reg [ADDR_WIDTH:0] next_wptr;
    reg [WIDTH-1:0]    mem [DEPTH-1:0];

    wire               wptr_msb;
    wire               rptr_msb;
    wire               next_wptr_msb;  

    // WIDTH > 1
    // write and read transaction
    always @(posedge i_clk) begin
        if(i_wren)
            mem[wptr[ADDR_WIDTH-1:0]] <= i_wdata;
    end

    assign o_rdata = mem[rptr[ADDR_WIDTH-1:0]];

    // write and read pointer
    assign next_wptr = (wptr[ADDR_WIDTH-1:0] == DEPTH - 1) ? {~wptr[ADDR_WIDTH], {(ADDR_WIDTH){1'b0}}} : wptr + 1'b1;
    always @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn)
            wptr <= {(ADDR_WIDTH+1){1'b0}};
        else if(i_wren)
            wptr <= next_wptr;    
    end

    assign next_rptr = (rptr[ADDR_WIDTH-1:0] == DEPTH - 1) ? {~rptr[ADDR_WIDTH], {(ADDR_WIDTH){1'b0}}} : rptr + 1'b1;
    always@(posedge i_clk or negedge i_rstn) begin
        if(~i_rstn)
            rptr <= {(ADDR_WIDTH+1){1'b0}};
        else if(i_rden)
            rptr <= next_rptr;
    end

    assign wptr_msb = wptr[ADDR_WIDTH];
    assign rptr_msb = rptr[ADDR_WIDTH];
    assign next_wptr_msb = next_wptr[ADDR_WIDTH];

    // empty and full
    always@(posedge i_clk or negedge i_rstn)begin
        if(!i_rstn)
            empty <= 1'b1;
        else if(!i_wren && wptr == rptr)
            empty <= 1'b1;
        else if(i_wren && !i_rden && wptr == rptr)
            empty <= 1'b0;
        else if(i_rden && !i_wren && next_rptr == wptr)
            empty <= 1'b1;
    end

    always@(posedge i_clk or negedge i_rstn)begin
        if(!i_rstn)
            full <= 1'b0;
        else if(!i_rden && wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0] && wptr_msb != rptr_msb)
            full <= 1'b1;
        else if(i_rden && !i_wren && wptr[ADDR_WIDTH-1:0] == rptr[ADDR_WIDTH-1:0] && wptr_msb != rptr_msb)
            full <= 1'b0;
        else if(i_wren && !i_rden && next_wptr[ADDR_WIDTH-1:0]  == rptr[ADDR_WIDTH-1:0] && next_wptr[ADDR_WIDTH] != rptr[ADDR_WIDTH])
            full <= 1'b1;
    end

    assign o_empty = empty;
    assign o_full = full;
endmodule
module sync_FIFO #(
    parameter           WIDTH = 16,
    parameter           DEPTH = 2
)(
    input               clk,
    input               rst_n,
    input  [WIDTH-1:0]  data_wr,
    input               push,
    input               pop,
    input               flush,
    output [WIDTH-1:0]  data_rd,
    output              full,
    output              not_full,
    output              empty,
    output              not_empty 
);
    localparam          AW = ((DEPTH <= 2) ? 1 : 
                              (DEPTH <= 4) ? 2 :
                              (DEPTH <= 8) ? 3 :
                              (DEPTH <= 16) ? 4 :
                              (DEPTH <= 32) ? 5 :
                              (DEPTH <= 64) ? 6 :
                              (DEPTH <= 128) ? 7 :
                              (DEPTH <= 256) ? 8 :
                              (DEPTH <= 512) ? 9 :
                              (DEPTH <= 1024) ? 10 :
                              (DEPTH <= 2048) ? 11 :
                              (DEPTH <= 4096) ? 12 : 13);

    reg                 empty;
    reg                 full;
    reg                 not_empty;
    reg                 not_full;

    reg     [WIDTH-1:0] mem[DEPTH-1:0];

    reg     [AW:0]      wptr;
    reg     [AW:0]      rptr;

    wire    [AW:0]      next_wptr;
    wire    [AW:0]      next_rptr;

    wire                next_wptr_msb;

    wire                rptr_msb;
    wire                wptr_msb;
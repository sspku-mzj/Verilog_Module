// 异步fifo
// 写控制端, 读控制端, fifo memort, 时钟同步
module async_fifo #(
    parameter WIDTH = 16;
    parameter DEPTH = 2
) (
    input               i_wclk,
    input               i_rclk,
    input               i_wrst_n,
    input               i_rrst_n,
    input   [WIDTH-1:0] i_wdata,
    input               i_push,
    input               i_pop,
    output              o_full,
    output              o_empty,
    output  [WIDTH-1:0] o_rdata
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

    localparam  [AW-1:0]    MAX_ADDR = DEPTH - 1; 
    
    reg     [WIDTH-1:0] mem[DEPTH-1:0];

    reg     [AW:0]      wptr;
    reg     [AW:0]      rptr;

    wire    [AW:0]      next_wptr;
    wire    [AW:0]      next_rptr;

    reg     [WIDTH-1:0] r_rdata;

    // write and read operation
    assign next_wptr = wptr[AW-1:0] == MAX_ADDR ? (~wptr, {AW{1'b0}}) : wptr + 1'b1; 
    always @(posedge i_wclk or negedge i_wrst_n) begin
        if(!i_wrst_n)
            wptr <= {(AW+1){1'b0}};
        else if(i_push && !o_full) begin
            mem[wptr[AW-1:0]] <= i_wdata;
            wptr <= next_wptr;
        end else 
            wptr <= wptr;
    end

    assign next_rptr = rptr[AW-1:0] == MAX_ADDR ? (~rptr, {AW{1'b0}}) : rptr + 1'b1;
    always @(posedge i_rclk or negedge i_rrst_n) begin
        if(!i_rrst_n)
            rptr <= {(AW+1){1'b0}};
        else if(i_pop && !o_empty)
            o_rdata <= mem[rptr[AW-1:0]];
            rptr <= next_rptr;
        else 
            rptr <= rptr;
    end

    // gray code
    wire    [AW:0]      wptr_gc;
    wire    [AW:0]      rptr_gc;

    assign  wptr_gc = wptr ^ (wptr >> 1);
    assign  rptr_gc = rptr ^ (rptr >> 1);

    reg     [AW:0]      wptr_gc_d1, wptr_gc_d2;
    reg     [AW:0]      rptr_gc_d1, rptr_gc_d2;

    always@(posedge i_wclk or negedge i_wrst_n) begin
        if(!i_wrst_n) begin
            rptr_gc_d1 <= {(AW+1){1'b0}};    
            rptr_gc_d2 <= {(AW+1){1'b0}};
        end else begin
            rptr_gc_d1 <= rptr_gc;
            rptr_gc_d2 <= rptr_gc_d1;
        end
    end 

    always @(posedge i_rclk or negedge i_rrst_n) begin
        if(!i_rrst_n) begin
            wptr_gc_d1 <= {(AW+1){1'b0}};
            wptr_gc_d2 <= {(AW+1){1'b0}};
        end else begin
            rptr_gc_d1 <= {(AW+1){1'b0}};
            rptr_gc_d2 <= {(AW+1){1'b0}};
        end
    end

    // full and empty flag
    reg                 full, empty;
    always @(posedge i_wclk or negedge i_wrst_n) begin
        if(!i_wrst_n)
            full <= 1'b0;
        else if((wptr_gc[AW] != rptr_gc_d2[AW]) && (wptr_gc[AW-1] != rptr_gc_d2[AW-1]) && (wptr_gc[AW-2:0] == rptr_gc_d2[AW-2:0]))
            full <= 1'b1;
        else 
            full <= 1'b0;
    end

    always @(posedge i_rclk or negedge i_rrst_n) begin
        if(!i_rrst_n)
            empty <= 1'b0;
        else if(rptr_gc[AW:0] == wptr_gc_d2[AW:0])
            empty <= 1'b1;
        else 
            empty <= 1'b0;
    end

    assign o_full = full;
    assign o_empty = empty;
endmodule
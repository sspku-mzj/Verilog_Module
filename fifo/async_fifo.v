`timescale 1ns/1ps
module async_fifo #(
    parameter WIDTH = 16,
    parameter DEPTH = 8,
    parameter AW = $clog2(DEPTH)
)(
    input wire              i_wrstn,
    input wire              i_rrstn,

    input wire              i_wclk,
    input wire              i_rclk,
    input wire              i_wen,
    input wire              i_ren,
    input wire [WIDTH-1:0]  i_wdata,
    output reg [WIDTH-1:0]  o_rdata,

    output reg              o_full,
    output reg              o_empty
);

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    reg [AW:0]              wptr;
    reg [AW:0]              next_wptr;
    reg [AW:0]              gray_wptr;
    reg [AW:0]              next_gray_wptr;
    reg [AW:0]              gray_wptr_d1;
    reg [AW:0]              gray_wptr_d2;

    reg [AW:0]              rptr;
    reg [AW:0]              next_rptr;
    reg [AW:0]              gray_rptr;
    reg [AW:0]              next_gray_rptr;
    reg [AW:0]              gray_rptr_d1;
    reg [AW:0]              gray_rptr_d2;

// read and write pointer 
// bin to gray
    assign next_wptr = wptr + 1'b1;
    assign next_gray_wptr = next_wptr ^ (next_wptr >> 1);
    
    always@(posedge i_wclk or negedge i_wrstn) begin
        if(!i_wrstn) begin
            wptr <= {(AW+1){1'b0}};
            gray_wptr <= {(AW+1){1'b0}};
        end
        else if(i_wen && !o_full) begin
            wptr <= next_wptr;
            gray_wptr <= next_gray_wptr;
        end
    end

    always@(posedge i_rclk or negedge i_rrstn) begin        // sync wptr to read clock domian
        if(!i_rrstn) begin
            gray_wptr_d1 <= {(AW+1){1'b0}};
            gray_wptr_d2 <= {(AW+1){1'b0}};    
        end
        else begin
            gray_wptr_d1 <= gray_wptr;
            gray_wptr_d2 <= gray_wptr_d1;
        end
    end

    assign next_rptr = rptr + 1'b1;
    assign next_gray_rptr = next_rptr ^ (next_rptr >> 1); 

    always @(posedge i_rclk or negedge i_rrstn) begin
        if(!i_rrstn) begin
            rptr <= {(AW+1){1'b0}};
            gray_rptr <= {(AW+1){1'b0}};
        end
        else if(i_ren && !o_empty) begin
            rptr <= next_rptr;
            gray_rptr <= next_gray_rptr;
        end
    end

    always@(posedge i_rclk or negedge i_rrstn) begin        // sync rptr to write clock domain
        if(!i_rrstn) begin
            gray_rptr_d1 <= {(AW+1){1'b0}};
            gray_rptr_d2 <= {(AW+1){1'b0}};
        end
        else begin
            gray_rptr_d1 <= gray_rptr;
            gray_rptr_d2 <= gray_rptr_d1;
        end
    end

    // write and read operation
    integer [AW-1:0] i;
    
    always@(posedge i_wclk or negedge i_wrstn) begin
        if(!i_wrstn) begin
            for(i=0;i<DEPTH;i=i+1) begin
                mem[i] <= {(WIDTH){1'b0}};
            end
        end
        else if(i_wen && !o_full) begin
            mem[wptr[AW-1:0]] <= i_wdata;
        end
    end

    always@(posedge i_rclk or negedge i_rrstn) begin
        if(!i_rrstn) begin
            o_rdata <= {(WIDTH){1'b0}};
        end
        else if(i_ren && !o_empty) begin
            o_rdata <= mem[rptr[AW-1:0]];
        end
    end

    // full and empty flag
    // gray_wptr and gray_rptr(try)
    assign o_full = (next_gray_wptr == {~gray_rptr_d2[AW:AW-1], gray_rptr_d2[AW-2:0]}) ? 1'b1 : 1'b0;
    assign o_empty = (next_gray_rptr == gray_wptr_d2) ? 1'b1 : 1'b0;

endmodule
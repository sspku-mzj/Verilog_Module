`timescale 1ns/1ps
module tb_sync_fifo;

    reg             i_clk;
    reg             i_rstn;

    reg             i_wren_random;
    reg [31:0]      i_wdata;
    reg             i_rden_random;
    reg [31:0]      o_rdata;
    wire            i_wren;
    wire            i_rden;

    wire            o_empty;
    wire            o_full;  
    initial begin
        i_rstn  = 1'b1;
        i_clk   = 1'b1;

        i_rden_random  = 1'b0;
        i_wren_random  = 1'b0;
        i_wdata = 32'b0;

        #2 i_rstn = 1'b0;
        #5 i_rstn = 1'b1;
    end

    assign i_wren = i_wren_random & !o_full;
    assign i_rden = i_rden_random & !o_empty;

    initial begin
        repeat(1000) begin
            #5 i_wren_random = {$random}%2;
               i_rden_random = {$random}%2;
        end
    end

    initial #4000 $finish;

    always #0.5 i_clk = ~i_clk;
    always #1   i_wdata = {$random}%10;

    sync_fifo u_sync_fifo(
        .i_clk       (i_clk),  
        .i_rstn      (i_rstn),
        .i_wren      (i_wren),
        .i_rden      (i_rden),
        .i_wdata     (i_wdata),
    
        .o_rdata     (o_rdata),
        .o_empty     (o_empty),
        .o_full      (o_full)
    );
    
    initial begin
        $fsdbDumpfile("sync_fifo.fsdb");
        $fsdbDumpvars;
        $fsdbDumpMDA;
    end
endmodule
`timescale  1ns/1ps

module tb_async_fifo;

reg             i_wclk;
reg             i_rclk;
reg             i_rstn;

reg             i_wen;
reg             i_ren;
reg     [15:0]  i_wdata;

wire [15:0]     o_rdata;

initial begin
    i_rstn = 1'b1;
    i_wclk = 1'b1;
    i_rclk = 1'b1;

    i_wen = 1'b0;
    i_ren = 1'b0;

    # 1
    i_rstn = 1'b0;

    # 2
    i_rstn = 1'b1; 
end

initial begin
    #20 i_wen = 1;
        i_ren = 0;
    #40 i_wen = 0;
        i_ren = 1;
    #30 i_wen = 1;
        i_ren = 0;
    #13 i_ren = 1;
    #10
        repeat(100) begin
            #5  i_wen = {$random}%2;
                i_ren = {$random}%2;
        end
end

always #1.5 i_wclk = ~i_wclk;
always #1   i_rclk = ~i_rclk;
always #3   i_wdata = {$random}%16'hFF;

async_fifo  u_async_fifo(
    .i_wrstn     (i_rstn),
    .i_rrstn     (i_rstn),
    .i_wclk      (i_wclk),
    .i_rclk      (i_rclk),
    .i_wen       (i_wen),
    .i_ren       (i_ren),
    .i_wdata     (i_wdata),
    .o_rdata     (o_rdata),
    .o_full      (o_full),
    .o_empty     (o_empty)
);

initial begin
    #1000 $finish;
end

initial begin
    $fsdbDumpfile("async_fifo.fsdb");
    $fsdbDumpvars;
    $fsdbDumpMDA;
end

endmodule
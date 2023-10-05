module sync_FIFO #(
    parameter           WIDTH = 16,
    parameter           DEPTH = 2
)(
    input               i_clk,
    input               i_rst_n,
    input  [WIDTH-1:0]  i_wdata,
    input               i_push,
    input               i_pop,
    input               i_flush,
    output [WIDTH-1:0]  o_rdata,
    output              o_full,
    output              o_not_full,
    output              o_empty,
    output              o_not_empty 
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

    generate
        if(DEPTH == 1) begin
            reg [WIDTH-1:0]     r_rdata;
            reg                 r_full;
            reg                 r_not_full;
            reg                 r_empty;
            reg                 r_not_empty;
            always @(posedge i_clk or negedge i_rst_n) begin
                if(!i_rst_n) begin
                    r_rdata <= 'b0;
                    r_empty <= 1'b1;
                    r_not_empty <= 1'b0;
                    r_full <= 1'b0;
                    r_not_full <= 1'b1;
                end
                else if(i_flush) begin
                    r_rdata <= 'b0;
                    r_empty <= 1'b1;
                    r_not_empty <= 1'b0;
                    r_full <= 1'b0;
                    r_not_full <= 1'b1;
                end else begin
                    case({i_pop, i_push})                                           // 这里很重要的一点是,时序电路中,逻辑不全会补充触发器使数据不变,而组合电路会产生锁存器
                        2'01 : begin
                            r_rdata <= i_wdata;
                            r_empty <= 1'b0;
                            r_not_empty <= 1'b1;
                            r_full <= 1'b1;
                            r_not_full <= 1'b0;
                        end
                        2'b10 : begin
                            r_empty <= 1'b1;
                            r_not_empty <= 1'b0;
                            r_full <= 1'b0;
                            r_not_full <= 1'b1;
                        end
                        2'b11 : begin
                            r_rdata <= i_wdata;
                            r_empty <= 1'b1;
                            r_not_empty <= 1'b0;
                            r_full <= 1'b0;
                            r_not_full <= 1'b1;
                        end
                    endcase         
                end
            end
            assign o_rdata      = r_rdata;
            assign o_full       = r_full;
            assign o_not_full   = r_not_full;
            assign o_empty      = r_empty;
            assign o_not_empty  = r_not_empty;
        end
        else begin :
            // write and read data
            always @(posedge i_clk) begin
                if(i_push) begin
                    mem[wptr[AW-1:0]] <= i_wdata;
                end
            end

            assign o_rdata = mem[rptr[AW-1:0]];

            // write and read pointer
            assign next_wptr = (wptr[AW-1:0] == MAX_ADDR) ? {~wptr[AW], {AW{1'b0}}} : wptr + 1'b1;
            always @(posedge i_clk or posedge i_rst_n) begin
                if(!i_rst_n) begin
                    wptr <= {(AW+1){1'b0}};
                end else if(i_flush) begin
                    wptr <= {(AW+1){1'b0}};
                end else if(i_push) begin
                    wptr <= next_wptr;
                end
            end

            assign next_rptr = (rptr[AW-1:0] == MAX_ADDR) ? {~rptr[AW], {AW{1'b0}}} : rptr + 1'b1;
        end
    endgenerate
// 最低位优先级最高,每个clk最高优先级左移一位
module arbiter_rr #(
    parameter WIDTH = 3
)(
    input               clk,
    input               rst,
    input   [WIDTH-1:0] req,
    output  [WIDTH-1:0] grant
);

    reg     [WIDTH-1:0] onehot;

    always @(posedge clk or negedge rst) begin
        if(!rst)
            onehot <= {{(WIDTH-1){1'b0}},1'b1};
        else 
            if(|req)
                onehot <= {grant[WIDTH-2:0],grant[WIDTH-1]};
    end

// double_req防止减法时不够减

    wire [2*WIDTH-1:0]  double_req = {req,req};
    wire [2*WIDTH-1:0]  double_grant = double_req & ~(double_req - onehot);

    assign grant = double_grant[WIDTH-1:0] | double_grant[2*WIDTH-1:WIDTH];
    
endmodule
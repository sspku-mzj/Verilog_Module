// 从低位到高位依次判断,借助一个pre_req记录低位是否已经request
// 当最低位request时,从该位到最高位pre_req均为1,grant均为0

module arbiter_parameter #(
    parameter REQ_WIDTH = 16
)(
    input   [REQ_WIDTH-1:0] req,
    output  [REQ_WIDTH-1:0] grant
);
    logic   [REQ_WIDTH-1:0] pre_req;

    always_comb begin 
        pre_req[0] = req[0];
        grant[0] = req[0];
        for(int i = 1; i < REQ_WIDTH; i=i+1) begin
            grant[i] = req[i] & !pre_req[i-1];
            pre_req[i] = req[i] | pre_req[i-1];
        end
    end
    assign grant = req & (~(req-1));
endmodule
// 以最低位为最高优先级
module arbiter_parameter2 #(
    parameter REQ_WIDTH = 16
)(
    input   [REQ_WIDTH-1:0] req,
    output  [REQ_WIDTH-1:0] grant
);
    
    assign grant = req & (~(req-1));
endmodule
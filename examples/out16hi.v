module out16hi(
    scl,
    sda,
    outhigh
);
    input           scl,sda;                // 串行数据输入
    output  [15:0]  outhigh;                // 根据输入的串行数据设置高电平位

    reg     [5:0]   mstate;
    reg     [3:0]   pdata;
    reg     [3:0]   pdatabuf;               // 记录串行数据位时, 用寄存器和最终数据寄存器
    reg     [15:0]  outhigh;
    reg             StartFlag;
    reg             EndFlag;                // 数据开始和结束标志

    always @(negedge sda) begin
        if(scl) begin
            StartFlag <= 1;                 // 串行数据开始标志
        end
        else if(EndFlag)
            StartFlag <= 0;
    end

    always @(posedge sda) begin
        if(scl) begin
            EndFlag <= 1;                   // 串行数据结束标志
            pdatabuf <= pdata;              // 把收到的4位数据存入寄存器
        end
        else
            EndFlag <= 0;                   // 数据接收还没有结束
    end 

    parameter ready = 6'b00_0000;
              sbit0 = 6'b00_0001;
              sbit1 = 6'b00_0010;
              sbit2 = 6'b00_0100;
              sbit3 = 6'b00_1000;
              sbit4 = 6'b01_0000;

    always @(pdatabuf) begin                // 把收到的数据变为相应位的高电平
        case(pdatabuf)
            4'b0001: outhigh = 16'b0000_0000_0000_0001;
            4'b0010: outhigh = 16'b0000_0000_0000_0010;
            4'b0011: outhigh = 16'b0000_0000_0000_0100;
            4'b0100: outhigh = 16'b0000_0000_0000_1000;
            4'b0101: outhigh = 16'b0000_0000_0001_0000;
            4'b0110: outhigh = 16'b0000_0000_0010_0000;
            4'b0111: outhigh = 16'b0000_0000_0100_0000;
            4'b1000: outhigh = 16'b0000_0000_1000_0000;
            4'b1001: outhigh = 16'b0000_0001_0000_0000;
            4'b1010: outhigh = 16'b0000_0010_0000_0000;
            4'b1011: outhigh = 16'b0000_0100_0000_0000;
            4'b1100: outhigh = 16'b0000_1000_0000_0000;
            4'b1101: outhigh = 16'b0001_0000_0000_0000;
            4'b1110: outhigh = 16'b0010_0000_0000_0000;
            4'b1111: outhigh = 16'b0100_0000_0000_0000;
            4'b0000: outhigh = 16'b1000_0000_0000_0000;
        endcase
    end

    always @(posedge scl) begin             // 在检测到开始标志后, 每次scl正跳变沿时接收数据, 共4位
        if(StartFlag)
            case(mstate)
                sbit0: begin
                    mstate <= sbit1;
                    pdata[3] <= sda;
                end
                sbit1: begin
                    mstate <= sbit2;
                    pdata[2] <= sda;
                end
                sbit2: begin
                    mstate <= sbit3;
                    pdata[1] <= sda;
                end
                sbit3: begin
                    mstate <= sbit4;
                    pdata[0] <= sda;
                end
                sbit4: begin
                    mstate <= sbit0;
                end
                default: begin
                    mstate <= sbit0;
                end
            endcase
        else 
            mstate <= sbit0;
    end

endmodule
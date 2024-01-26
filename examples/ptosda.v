// 并行数据流转换成串行数据流
// M1:将4位并行数据转换为符合以下协议串行数据流,数据流用scl和sda两条线传输,sclk为输入的时钟信号,data[3:0]为输入数据,ack为M1请求M0发新数据信号
// M2:接收串行数据,并转换成16条信号线的高电平
// M0:测试用信号模块,接收M1发送的ack信号,并产生新的测试数据data[3:0]

//-------------------------- 通信协议--------------------------------
// scl为不断输出的时钟信号, 如果scl为高电平, sda由高变低时, 串行数据流开始;
// 如果scl为高电平时, sda由低变高时, 串行数据结束。
// sda信号的串行数据位必须在scl为低电平时变化, 若变为高则为1, 否则为0。
//------------------------------------------------------------------
// M1:输入信号:sclk, data[3:0]
//    输出信号:scl, sda, ack
module ptosda (
    rst,
    sclk,

    ack,
    scl,
    sda,
    data
);
    input           sclk, rst;                                  // 输入时钟,输入复位信号
    input   [3:0]   data;                                       // 并行口数据输入

    output          ack;
    output          scl;                                        
    output          sda;                                        // 串行输出

    reg             scl;
    reg             link_sda;                                   // 控制sdabuf输出到串行总线上
    reg             ack;                                        // ask for new data
    reg             sdabuf;                                     // sdabuf输出串行数据
    reg     [3:0]   databuf;                                    // databuf接收并行数据
    reg     [7:0]   state;

    assign sda = link_sda ? sdabuf : 1'bz;

    parameter   ready = 8'b0000_0000;
                start = 8'b0000_0001;
                bit1  = 8'b0000_0010;
                bit2  = 8'b0000_0100;
                bit3  = 8'b0000_1000;
                bit4  = 8'b0001_0000;
                bit5  = 8'b0010_0000;
                stop  = 8'b0100_0000;
                IDLE  = 8'b1000_0000;
    
    always @(posedge sclk or negedge rst) begin                 // 由输入的sclk时钟信号产生串行输出时钟scl
        if(!rst)
            scl <= 1;
        else 
            scl <= ~scl; 
    end

    always@(posedge ack)                                        // 请求新数据时存入并行总线上要转换的数据
        databuf <= data;
    
    // 主状态机:产生控制信号,根据databuf中保存的数据,按照协议产生sda串行信号
    always@(negedge sclk or negedge rst)
        if(!rst) begin
            link_sda <= 0;                                      // 断开sdabuf和sda串行总线
            state <= ready;
            sdabuf <= 1;
            ack <= 0;                                           // 重置请求
        end
        else begin
            case(state)
                ready:
                    if(ack) begin                               // 并行数据请求开启
                        link_sda <= 1;                          // 将sdabuf与sda串行总线连接
                        state <= start;
                    end
                    else begin                                  // 并行数据尚未到达
                        link_sda <= 0;                          // sda总线让出,此时sda可作为输入
                        state <= ready;
                        ack <= 1;                               // 如果并行数据请求未开启,则启动
                    end
                start:
                    if(scl && ack) begin                        // 产生sda的开始信号
                        sdabuf <= 0;                            // sda连接的前提下,输出开始信号
                        state <= bit1;
                    end
                    else 
                        state <= start;
                bit1:
                    if(!scl) begin                              // 在scl为低电平时送出最高位databuf[3]
                        sdabuf <= databuf[3];
                        state <= bit2;
                        ack <= 0;
                    end
                    else 
                        state <= bit1;
                bit2:
                    if(!scl) begin                              // 在scl为低电平时送出次高位databuf[2]
                        sdabuf <= databuf[2];
                        state <= bit3;
                    end
                    else 
                        state <= bit2;
                bit3:
                    if(!scl) begin                              // 在scl为低电平时送出次低位databuf[1]
                        sdabuf <= databuf[1];
                        state <= bit4;
                    end
                    else 
                        state <= bit3;
                bit4:
                    if(!scl) begin                              // 在scl为低电平时送出最低位databuf[0]
                        sdabuf <= databuf[0];
                        state <= bit5;
                    end
                    else 
                        state <= bit4;
                bit5:
                    if(!scl) begin                              // 为产生结束信号做准备,先把sda变低
                        sdabuf <= 0;
                        state <= stop;
                    end
                    else 
                        state <= bit5;
                stop:
                    if(scl) begin                               // scl为高时,将sda由低变高产生结束信号  
                        sdabuf <= 1;
                        state <= IDLE;
                    end
                    else 
                        state <= stop;
                IDLE: begin
                    link_sda <= 0;                              // 将sdabuf与sda串行总线脱开
                    state <= ready;
                end
                default: begin
                    link_sda <= 0;
                    sdabuf <= 1;
                    state <= ready;
                end
            endcase
        end
    
endmodule
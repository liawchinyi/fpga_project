/**************************************************************
            uart发送(并转串)
            根据uart时序,将帧数据发送给上位机                      
**************************************************************/
module uart_tx(
    input                   clk                  ,
    input                   rst_n                ,
    output                  busy                 ,
    input  [7:0]            tx_data              ,
    input                   tx_data_vld          ,
    output                  tx                  
);
//
parameter BAUD = 9600; //需要计数的1bit宽度的周期计算公式: 时钟频率/波特率
parameter CLK_FRE = 50_000_000;//时钟频率
//
reg                 tx_flag         ;//传输标志 1表示需要传输 0表示不传输

reg  [12:0]         cnt_baud        ;//记录1bit时间
wire                add_cnt_baud    ;
wire                end_cnt_baud    ;

reg  [3:0]          cnt_bit         ;//记录到第几bit
wire                add_cnt_bit     ;
wire                end_cnt_bit     ;

reg  [9:0]          tx_data_r       ;

reg                 tx_r            ;
//
/**************************************************************
            寻找数据传输开始的位置
            检测下降沿                  
**************************************************************/
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tx_flag <= 0;
    end
    else if(tx_data_vld)begin
        tx_flag <= 1;
    end
    else if(end_cnt_bit)begin
        tx_flag <= 0;
    end
end

/**************************************************************
            传输数据
            记录bit时间                    
**************************************************************/
always@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        cnt_baud <= 13'd0;
    end
    else if(add_cnt_baud)begin
        if(end_cnt_baud)begin
            cnt_baud <= 13'd0;
        end
        else begin
            cnt_baud <= cnt_baud + 1'b1;
        end
    end
assign add_cnt_baud = tx_flag;
assign end_cnt_baud = add_cnt_baud && (cnt_baud ==  (CLK_FRE/BAUD - 1));

always@(posedge clk or negedge rst_n)
    if(!rst_n)begin
        cnt_bit <= 4'd0;
    end
    else if(add_cnt_bit)begin
        if(end_cnt_bit)begin
            cnt_bit <= 4'd0;
        end
        else begin
            cnt_bit <= cnt_bit + 1'b1;
        end
    end
assign add_cnt_bit = end_cnt_baud;
assign end_cnt_bit = add_cnt_bit && (cnt_bit ==  (10 - 1));

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tx_data_r <= 10'h3ff;
    end
    else if(tx_data_vld)begin
        tx_data_r <= {1'b1,tx_data,1'b0};
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tx_r <= 1'b1;
    end
    else if(tx_flag && cnt_baud == 0)begin//LSB发送
        tx_r <= tx_data_r[cnt_bit];
    end
end
assign tx = tx_r;
assign busy = tx_flag;

endmodule
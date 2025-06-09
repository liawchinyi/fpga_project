/**************************************************************
            完成串口接口功能(串转并)                     
**************************************************************/
module uart_rx(
    input                   clk                  ,
    input                   rst_n                ,
    input                   rx                   ,
    output [7:0]            rx_data              ,
    output                  rx_data_vld          
);
//
parameter BAUD = 9600; //需要计数的1bit宽度的周期计算公式: 时钟频率/波特率
parameter CLK_FRE = 50_000_000;//时钟频率
//
reg                 rx_r            ;
wire                nedge           ;

reg  [12:0]         cnt_baud        ;//记录1bit时间
wire                add_cnt_baud    ;
wire                end_cnt_baud    ;
reg                 rx_flag         ;//采集标志 bit计数标志

reg  [3:0]          cnt_bit         ;//记录到第几bit
wire                add_cnt_bit     ;
wire                end_cnt_bit     ;

reg  [9:0]          rx_data_r       ;
//
/**************************************************************
            寻找数据传输开始的位置
            检测下降沿                  
**************************************************************/
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rx_r <= 1;
    end
    else begin
        rx_r <= rx;
    end
end
assign nedge = !rx && rx_r;
/**************************************************************
            接受数据
            记录bit时间                    
**************************************************************/
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        rx_flag <= 0;
    end
    else if(nedge)begin
        rx_flag <= 1;
    end
    else if(end_cnt_bit)begin
        rx_flag <= 0; 
    end
end

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
assign add_cnt_baud = rx_flag;
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
        rx_data_r <= 10'h3ff;
    end
    else if(cnt_baud == ((CLK_FRE/BAUD)>>1))begin//LSB采样
        rx_data_r[cnt_bit] <= rx_r;
        //rx_data_r <= {rx_r,rx_data_r[9:1]};
    end
end
assign rx_data = rx_data_r[8:1];
assign rx_data_vld = end_cnt_bit;

endmodule
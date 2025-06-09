/**************************************************************
         完成UART回环
         BAUD:9600
         数据格式:1bit起始位+8bit数据位+1bit停止位                        
**************************************************************/
module top (
    input               clk             ,
    input               rst_n           ,
    input               rx              ,
    output              tx              
);
//参数

//内部信号
wire [7:0]          rx_data             ;
wire                rx_data_vld         ;
wire                busy                ;
wire [7:0]          tx_data             ;
wire                tx_data_vld         ;
//内部逻辑

//uart接受
uart_rx u_uart_rx(
    /* input                    */.clk                 (clk                 ),
    /* input                    */.rst_n               (rst_n               ),
    /* input                    */.rx                  (rx                  ),
    /* output [7:0]             */.rx_data             (rx_data             ),
    /* output                   */.rx_data_vld         (rx_data_vld         )
);

//ctrl
ctrl u_ctrl(
    /* input                    */.clk                 (clk                 ),
    /* input                    */.rst_n               (rst_n               ),
    /* input  [7:0]             */.rx_data             (rx_data             ),
    /* input                    */.rx_data_vld         (rx_data_vld         ),
    /* input                    */.busy                (busy                ),//0表示空闲 1表示忙
    /* output [7:0]             */.tx_data             (tx_data             ),
    /* output                   */.tx_data_vld         (tx_data_vld         )
);

//uart发送
uart_tx u_uart_tx(
    /* input                    */.clk                 (clk                 ),
    /* input                    */.rst_n               (rst_n               ),
    /* output                   */.busy                (busy                ),
    /* input  [7:0]             */.tx_data             (tx_data             ),
    /* input                    */.tx_data_vld         (tx_data_vld         ),
    /* output                   */.tx                  (tx                  )
);
    
endmodule
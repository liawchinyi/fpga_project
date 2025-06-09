/**************************************************************
        uart控制模块
        缓存、处理数据
        经过fifo                     
**************************************************************/
module ctrl(
    input                   clk                  ,
    input                   rst_n                ,
    input  [7:0]            rx_data              ,
    input                   rx_data_vld          ,
    input                   busy                 ,//0表示空闲 1表示忙
    output [7:0]            tx_data              ,
    output                  tx_data_vld          
);
//
//
wire                        clock_sig               ; 
wire [7:0]                  data_sig                ; 
wire                        rdreq_sig               ; 
wire                        wrreq_sig               ; 
wire                        empty_sig               ; 
wire                        full_sig                ; 
wire [7:0]                  q_sig                   ; 
wire [7:0]                  usedw_sig               ; 

reg                         tx_data_vld_r           ;
//
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        tx_data_vld_r <= 0;
    end
    else begin
        tx_data_vld_r <= rdreq_sig;
    end
end


fifo_8_256	fifo_8_256_inst (
	.clock          ( clock_sig         ),
	.data           ( data_sig          ),
	.rdreq          ( rdreq_sig         ),
	.wrreq          ( wrreq_sig         ),
	.empty          ( empty_sig         ),
	.full           ( full_sig          ),
	.q              ( q_sig             ),
	.usedw          ( usedw_sig         )
	);
    assign clock_sig = clk;
    assign data_sig = rx_data;
    assign rdreq_sig = !empty_sig && !busy;//fifo有数据并且发送模块空闲
    assign wrreq_sig = rx_data_vld;

    assign tx_data = q_sig;
    //assign tx_data_vld = rdreq_sig;前显模式时序
    assign tx_data_vld = tx_data_vld_r;


endmodule
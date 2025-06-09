
/*

 National Metrology Centre
 Chin-Yi LIAW
 2 June 2023

DO NOT USE JTAG, MODE0/1 and DONE pins. 
If you really need to use these pins, please refer to SUG100-2.6E_Gowin Software User Guide.pdf.

*/

module uart_test(
	input                        clk,       // Pin 52 27MHz Crystal Oscillator
	input                        rst_n,     // Pin 4 Button S1
	input                        clk_10MHz, // Pin 25 external CLK input (unused)
    input                        pulse_in,  // Pin 27 external 1Hz pulse input
    output wire [5:0]            led,
	input                        uart_rx,   // Pin 28 UART RX input (3.3V) Pin 85 1.8V
	output                       uart_tx,   // Pin 17 UART TX output (to USB)
    output wire                  tx_out,    // Pin 29 Copy of uart_tx
    output                       pulse_out, // Pin 30 1Hz pulse output
    output                       clk_out,   // Pin 26 copy of 27MHz Clock
    output reg                   Red_LED,   // Pin 31 Red LED (Open Collector)
    input                        btn        // Pin 3 Button S2 (unused)
);

parameter                        CLK_FRE  = 27;     //Mhz
parameter                        UART_FRE = 1200; //UART Baud Rate
localparam                       IDLE =  0;
localparam                       SEND =  1;   //send 
localparam                       WAIT =  2;   //wait 1 second and send uart received data
reg[7:0]                         tx_data;
reg[7:0]                         tx_str;
reg                              tx_data_valid;
wire                             tx_data_ready;
reg[7:0]                         tx_cnt;
wire[7:0]                        rx_data;
wire                             rx_data_valid;
reg                              rx_enable;
reg[31:0]                        wait_cnt;
reg[3:0]                         state;

assign led[2] = tx_data_valid;
assign led[3] = rx_data_valid;
assign clk_out = clk;
assign tx_out = uart_tx;

parameter DATA_NUM = 6;   // 中文字符使用UTF8，占用3个字节
reg [DATA_NUM * 8 - 1:0] send_data;
reg [31:0] Trigger_Test_Time;


always@(posedge clk or negedge rst_n)
begin
    if(rst_n==1'b0) begin
	Trigger_Test_Time[31:0] <= 32'd0;
    rx_enable <= 1'b1;	// rx enable pin. always can receive data,
    Red_LED <= 0;
	end
    else if (Trigger_Test_Time[31:0] > 27000000) begin
	Trigger_Test_Time[31:0] <= 32'd0;
    Red_LED <= !Red_LED;
	end
    else begin
	Trigger_Test_Time[31:0] <= Trigger_Test_Time[31:0] + 32'd1;
	end
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin
		wait_cnt <= 32'd0;
		tx_data <= 8'd0;
		state <= IDLE;
		tx_cnt <= 8'd0;
		tx_data_valid <= 1'b0;
	end
	else
	case(state)
		IDLE:
			state <= SEND;
		SEND:
		begin
			wait_cnt <= 32'd0;
			tx_data <= tx_str;

			if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < DATA_NUM - 1)  //Send 5 bytes data
			begin
				tx_cnt <= tx_cnt + 8'd1; //Send data counter
			end
			else if(tx_data_valid && tx_data_ready)  //last byte sent is complete
			begin
				tx_cnt <= 8'd0;
				tx_data_valid <= 1'b0;
				state <= WAIT;
			end
			else if(~tx_data_valid)
			begin
				tx_data_valid <= 1'b1;
			end
		end
		WAIT:
		begin
			wait_cnt <= wait_cnt + 32'd1;

			/*if(rx_data_valid == 1'b1)
			begin
				tx_data_valid <= 1'b1;
				tx_data <= rx_data;   // send uart received data
			end
			else */
            if(tx_data_valid && tx_data_ready)
			begin
				tx_data_valid <= 1'b0;
			end
			else if(wait_cnt >= CLK_FRE * 1000_00) // wait for 1 second
                begin
				state <= SEND;              
                end
		end
		default:
			state <= IDLE;
	endcase
end

always@(*)begin
    send_data <= {time_adjust[31:0],16'h0d0a};
	tx_str <= send_data[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];
    end

uart_rx uart_rx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.rx_data                    (rx_data                  ),
	.rx_data_valid              (rx_data_valid            ),
    .LED                        (led[4]                   ),
	.rx_data_ready              (rx_enable                ),
	.rx_pin                     (uart_rx                  )
);

uart_tx uart_tx_inst
(
	.clk                        (clk                      ),
	.rst_n                      (rst_n                    ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (uart_tx                  )
);

wire data_ready;
wire [31:0] time_adjust;

uart_message u1(
    .clk        (clk),
	.rst_n      (rst_n),
    .byteReady  (rx_data_valid),
	.LED        (led[1]),
    .rx_data    (rx_data),
    .data_ready (data_ready),
    .phase_shift(time_adjust)
);

divider u2(
	.clk_in     (clk),
    .pulse_in   (pulse_in),
	.LED        (led[0]),
	.pulse_out  (pulse_out),
    .time_delay (time_adjust)
);



endmodule
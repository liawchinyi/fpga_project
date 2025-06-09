`timescale 10 ns/1 ns  // time-unit = 1 ns, precision = 10 ps

//https://learn.lushaylabs.com/tang-nano-9k-debugging/

module testTB();

  reg Sys_Clk, Reset_N ;
  wire tx_pin,rx_pin,pulse_out,led;
  reg [31:0] Trigger_Test_Time;
  reg [23:0] adjust;

parameter                     	 CLK_FRE  = 27;//Mhz
parameter                        UART_FRE = 115200;//Mhz
localparam                       IDLE =  0;
localparam                       SEND =  1;   //send 
localparam                       WAIT =  2;   //wait 1 second and send uart received data
reg[7:0]                         tx_data;
reg[7:0]                         tx_str;
reg                              tx_data_valid;
reg 				 pulse_in;
wire                             tx_data_ready;
reg[7:0]                         tx_cnt;
wire[7:0]                        rx_data;
wire                             rx_data_valid;
reg                              rx_data_ready;
reg[31:0]                        wait_cnt;
reg[3:0]                         state;

/*iverilog */
initial begin
   $dumpfile("./wave.vcd"); //???vcd????
   $dumpvars(0, testTB); //tb????
end

initial begin
    $display("Starting UART RX");
    $monitor("LED Value %b", led);

    Sys_Clk = 0; 
    Reset_N = 0; 
    pulse_in = 0;
    adjust[23:0] = 24'h111;
    #10 Reset_N = 1'b0;
    #20 Reset_N = 1'b1;
    #600000 ; // wait for 30 time units
    #1000 pulse_in = 1;
    #100 pulse_in = 0;
    #1000 adjust[23:0] = 24'h222;
    #600000 ; // wait for 30 time units
    #100 pulse_in = 1;
    #100 pulse_in = 0;
    #1000 adjust[23:0] = 24'h555;
    #600000 ; // wait for 30 time units
    #100 pulse_in = 1;
    #100 pulse_in = 0;
    #1000000 $finish;
end

always #2 Sys_Clk =  ! Sys_Clk; 

always@(posedge Sys_Clk or negedge Reset_N)
begin
    if(Reset_N==1'b0) begin
	Trigger_Test_Time[31:0] <= 32'd0;
	end
    else begin
	Trigger_Test_Time[31:0] <= Trigger_Test_Time[31:0] + 32'd1;
	end
end

always@(posedge Sys_Clk or negedge Reset_N)
begin
	if(Reset_N==1'b0)
	begin
	    pulse_in = 0; 
	end
	else if(Trigger_Test_Time[31:0]==32'd0000)
	begin
	    rx_data_ready = 1'b1;	//always can receive data,
	end
	else if(Trigger_Test_Time[31:0]==32'd1000)
	begin
	    pulse_in = 1;
	end
	else if(Trigger_Test_Time[31:0]==32'd2000)
	begin
	    pulse_in = 0;
	end
end

parameter DATA_NUM =  5;
wire [DATA_NUM * 8 - 1:0] send_data = {adjust[23:0],16'h0d0a};//0d is carriage return,0a is line feed

always@(posedge Sys_Clk or negedge Reset_N)
begin
	if(Reset_N == 1'b0)
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
			if(Trigger_Test_Time[31:0]==32'd8000) 
			state <= SEND;
		SEND:
		begin
			wait_cnt <= 32'd0;
			tx_data <= tx_str;

			if(tx_data_valid == 1'b1 && tx_data_ready == 1'b1 && tx_cnt < DATA_NUM - 1)  //Send 12 bytes data
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

			if(rx_data_valid == 1'b1)
			begin
				tx_data_valid <= 1'b1;
				tx_data <= rx_data;   // send uart received data
			end
			else if(tx_data_valid && tx_data_ready)
			begin
				tx_data_valid <= 1'b0;
			end
			else if(wait_cnt >= CLK_FRE * 1000) // wait for 1 second 1000_000
			begin
				state <= SEND;
			end
		end
		default:
			state <= IDLE;
	endcase
end

always@(*)
	tx_str <= send_data[(DATA_NUM - 1 - tx_cnt) * 8 +: 8];

uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_rx_inst
(
	.clk                        (Sys_Clk                  ),
	.rst_n                      (Reset_N                  ),
	.rx_data                    (rx_data                  ),
	.rx_data_valid              (rx_data_valid            ),
	.rx_data_ready              (rx_data_ready            ),
	.rx_pin                     (tx_pin                   )
);

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(UART_FRE)
) uart_tx_inst
(
	.clk                        (Sys_Clk                  ),
	.rst_n                      (Reset_N                  ),
	.tx_data                    (tx_data                  ),
	.tx_data_valid              (tx_data_valid            ),
	.tx_data_ready              (tx_data_ready            ),
	.tx_pin                     (tx_pin                   )
);

wire data_ready;
wire [23:0] time_adjust;

uart_message u2(
    .clk(Sys_Clk),
    .byteReady(rx_data_valid),
    .rx_data(rx_data),
    .data_ready(data_ready),
    .phase_shift(time_adjust)
);

divider u1(
    .clk_in(Sys_Clk),
    .pulse_in(pulse_in),
    .LED(led),
    .pulse_out(pulse_out),
    .time_delay(time_adjust)
);

endmodule
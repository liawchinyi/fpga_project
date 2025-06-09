
/*
 Chin-Yi LIAW
 National Metrology Centre
 01 June 2023
*/

module divider (
		input clk_in, 
		input pulse_in,
		output reg LED,
		output reg pulse_out,
		input wire [31:0] time_delay // Max shift 0.63 Sec on 27MHz CLK
		);

localparam IDLE =  0;
localparam COUNT = 1;   //count to falling edge
localparam WAIT =  2;   //wait 1 second and send uart received data
localparam TRIG =  3;   //make rising edge

reg [2:0] state = WAIT;
reg [24:0] counter = 1;
reg [31:0] delay_counter = 1;

    always @(posedge clk_in) begin
	case (state)
	WAIT: begin
		if (pulse_in == 1) begin
			state <= TRIG;	
		end
        else begin
			delay_counter <= 1;
			pulse_out <= 0;
        end
		end
	TRIG: begin
   		if (delay_counter >= time_delay) begin // rising edge
			pulse_out <= 1;			
			state <= COUNT;
			counter <= 1;
            //LED <= 1;
   		end
   		else begin
			delay_counter <= delay_counter + 1;
   		end
		end
	COUNT: begin
		if (counter == 540) begin // 200 for 10MHz clock, 540 for 27MHz clock
			state <= IDLE;
			pulse_out <= 0;
            //LED <= 0;
		end
		else begin
			counter <= counter + 1;
		end
		end
	IDLE: begin
      		counter <= 1;
        	state <= WAIT;
            LED <= !LED;
		end
	endcase
    end


endmodule
/*
always @(posedge clk_in) //clock in
begin
   if(delay_counter == time_delay) // 200 pulse high
   begin
	counter <= counter + 1;
   end
   else
   begin
	delay_counter <= delay_counter + 1;
   end

   if(counter == 5000000) // 200 pulse high
   begin
	pulse_out <= 0;
   end

   if(counter == 10000000) // 10000000
   begin
      	counter <= 1;
        delay_counter <= 1;
        pulse_out <= 1;
      	LED <= !LED;
   end
end
*/
/*
Assuming the global clock is 50MHz and we want 5Hz clock
using formula global clock frequency / desired frequency / 2 = counter end value
counter end value = 50e6/5/2=10e6/2=5,000,000
during positive edge, increase counter by one, when it reaches 5,000,000 reset back to 0 in non-blocking assignment.
during positive edge, if counter is 5,000,000 set clkOutput as NOT clkOutput.
*/

// https://learn.lushaylabs.com/tang-nano-9k-data-visualization/

module uart_message (
    input clk,
    input rst_n,
    input byteReady,
    output reg LED,
    input[7:0] rx_data,
    output reg data_ready,
    output reg [31:0] phase_shift
);

    reg byte_received;  // high when a byte has been received
    reg crc_en;

    localparam WAIT_FOR_NEXT_CHAR_STATE = 0;
    localparam WAIT_FOR_TRANSFER_FINISH = 1;
    localparam SAVING_CHARACTER_STATE = 2;
    localparam IDLE_STATE = 3;
    localparam CHECK_CRC  = 4;
    localparam COPY_OUT   = 5;

    reg [3:0] state = WAIT_FOR_NEXT_CHAR_STATE;
    reg [127:0] data_received;

    always @(posedge clk) begin
	case (state)
	WAIT_FOR_NEXT_CHAR_STATE: begin
		if (byteReady == 0) begin
			state <= WAIT_FOR_TRANSFER_FINISH;
			data_ready <= 0;
            crc_en <= 0;
		end
		end
	WAIT_FOR_TRANSFER_FINISH: begin
		if (byteReady == 1)
			state <= SAVING_CHARACTER_STATE;
		end
	SAVING_CHARACTER_STATE: begin
		// implement a shift-left register (since we receive the data MSB first)
		data_received <= {data_received[119:0], rx_data};

		if (data_received[15:0] == 16'h0d0a) begin
			//phase_shift[31:0] <= data_received[47:16];
			data_ready <= 1;
            crc_en <= 1;
            LED <= !LED;
			state <= IDLE_STATE;
			end
		else begin
			state <= WAIT_FOR_NEXT_CHAR_STATE;
		end
		end
	IDLE_STATE: begin
		state <= WAIT_FOR_NEXT_CHAR_STATE;
		end
	CHECK_CRC: begin
		state <= COPY_OUT;
        
		end
	COPY_OUT: begin
		state <= WAIT_FOR_NEXT_CHAR_STATE;
        phase_shift[31:0] <= data_received[55:24];
		end
	endcase
    end

reg [31:0] Data;

wire [15:0] crc_out;

crc u3(
    .data_in    (Data),
    .crc_en     (crc_en),
    .crc_out    (CRC16),
	.clk        (clk),
	.rst_n      (rst_n)
);

endmodule

/*
In this version we check if the character from UART (data) equals the backspace or delete keys (8 or 127 in ascii) 
in which case we decrement the character index and replace the previous character with a space (32 in ascii). 
Otherwise like before we increment the character index and store the character as-is.
*/
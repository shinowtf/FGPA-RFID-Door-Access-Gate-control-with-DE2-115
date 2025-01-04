module digitalAssign(clk, rst, rst_n, a, b, c, d, e,  indicator, HEX, door, status1, status2, status3, status4, status5, i1, i2, i3, i4, i5, led);
input clk, rst, rst_n, a, b, c, d, e, i1, i2, i3, i4, i5;
output reg[7:0]indicator;
output reg door;
reg[4:0] current_state,next_state;
output [6:0] HEX;
output reg [6:0] status1, status2, status3, status4, status5;
output reg [17:0] led;

parameter IDLE=3'b000, VAL=3'b001, DENIED=3'b010,GRANTED=3'b011,OPEN=3'b100, CLOSE=3'b101;
reg [7:0] result;
wire [11:0] A1; 
reg [23:0] slow_counter;
// Slower clock signal
wire slow_clk;

// Instantiate the ClockDivider
ClockDivider #(
    .DIV_FACTOR(15_000_000) // Adjust as needed
) clock_divider_inst (
    .clk_in(clk),
    .rst(rst),
    .clk_out(slow_clk)
);
wire [17:0] open_led, close_led;  // wire to capture the LED output from `open`

    open open_inst (
        .clock (clk),
        .rst_n (rst_n),
        .led   (open_led)
		);
	  close close_inst (
        .clock (clk),
        .rst_n (rst_n),
        .led   (close_led)
		);


always@(*) begin
indicator[7:0] = 1'b0;
door = 1'b0;
			if (!rst_n) begin
            slow_counter = 24'd0;
            led          = 18'b111111111111111111;
         end
case (current_state)

IDLE: begin 
result=3'd0;
indicator[0] = 1'b1;
status1 = 7'b1001111; //hex3
status2 = 7'b1000000; //hex2
status3 = 7'b1000111; //hex1
status4 = 7'b0000110; //hex0
status5 = 7'b1111111; //hex4
led          = 18'b000000000000000000;
	if (a==0)  //sw0 start button
		next_state=IDLE;
	else if(a == 1)
		next_state=VAL;
end

VAL: begin 
status1 = 7'b0001100;
status2 = 7'b0001110;
status3 = 7'b1001111;
status4 = 7'b1000000;
status5 = 7'b1111111;
result=3'd1;
led          = 18'b000000000000000000;
indicator[1] = 1'b1;
		if(b==1) begin //password:11010
			if((i1==1)&&(i2==1)&&(i3==0)&&(i4==1)&&(i5==0))begin //verify button sw1
				next_state=GRANTED;
			end else begin
				next_state=DENIED;
		end
	end
	else begin
		next_state=VAL;
	end
end

DENIED: begin 
status1 = 7'b1001000;
status2 = 7'b1000000;
status3 = 7'b0001100;
status4 = 7'b0000110;
status5 = 7'b1111111;
indicator[2] = 1'b1;
result=3'd2;
led          = 18'b000000000000000000;
		next_state=DENIED;
end

GRANTED: begin 
status1 = 7'b0001100;
status2 = 7'b0001000;
status3 = 7'b0010010;
status4 = 7'b0010010;
status5 = 7'b1111111;
indicator[0] = 1'b1;
indicator[1] = 1'b1;
indicator[2] = 1'b1;
indicator[3] = 1'b1;
indicator[4] = 1'b1;
indicator[5] = 1'b1;
indicator[6] = 1'b1;
indicator[7] = 1'b1;
led          = 18'b000000000000000000;
result=3'd3;
	if(c == 1) 
		next_state=OPEN;
	else
		next_state=GRANTED;
end
	
OPEN: begin
    // Set initial values
    status1       = 7'b1000000;
    status2       = 7'b0001100;
    status3       = 7'b0000110;
    status4       = 7'b1001000; 
    status5       = 7'b1111111;
    indicator[4]  = 1'b1;
    result        = 3'd4;
    door          = 1'b1;
	 
	 
	  led = open_led;
    // Next-state logic
    if (d == 1) 
        next_state = CLOSE;
    else
        next_state = OPEN;
end

CLOSE: begin 
status1 = 7'b1000111;
status2 = 7'b1000000;
status3 = 7'b0010010;
status4 = 7'b0000110;
status5 = 7'b1000110;
indicator[5] = 1'b1;
result=3'd5;
led = close_led;
 if (e == 1) 
        next_state = IDLE;
    else
        next_state = CLOSE;
end
endcase
end 

always@(posedge slow_clk or negedge rst)
begin
	if (!rst) begin
         current_state <= IDLE;
   end else begin
			current_state<=next_state;
	end
end


    bin_to_bcd bcd1_converter (
        .binary(result),
        .bcd(A1)
    );

    seven_seg seg2 (
        .bcd(A1[7:0]),
        .hex_out(HEX)
    );

 
endmodule 


module bin_to_bcd (
    input [7:0] binary, // 8-bit Binary input (0 to 255)
    output reg [11:0] bcd // 3-digit BCD output (hundreds, tens, ones)
);
    integer i;
    reg [19:0] shift_reg; // Temporary shift register:
                          // [19:16]: Hundreds digit
                          // [15:12]: Tens digit
                          // [11:8] : Ones digit
                          // [7:0]  : Input binary working area

    always @(*) begin
        // Initialize shift register: top 12 bits for BCD digits, bottom 8 bits for binary
        shift_reg = {12'd0, binary};

        // Perform 8 iterations of double-dabble (one per binary bit)
        for (i = 0; i < 8; i = i + 1) begin
            // Adjust hundreds digit if >= 5
            if (shift_reg[19:16] >= 5)
                shift_reg[19:16] = shift_reg[19:16] + 3;

            // Adjust tens digit if >= 5
            if (shift_reg[15:12] >= 5)
                shift_reg[15:12] = shift_reg[15:12] + 3;

            // Adjust ones digit if >= 5
            if (shift_reg[11:8] >= 5)
                shift_reg[11:8] = shift_reg[11:8] + 3;

            // Shift everything left by 1 bit
            shift_reg = shift_reg << 1;
        end

        // Extract the three BCD digits from the shift register
        bcd = shift_reg[19:8]; // [19:16] hundreds, [15:12] tens, [11:8] ones
    end
endmodule

// Seven Segment Display Driver
module seven_seg (
    input [3:0] bcd, // 4-bit BCD input
    output reg [6:0] hex_out // Seven Segment Output
);
always @(*)
        case (bcd)
            4'd0: hex_out = 7'b1000000; // 0
            4'd1: hex_out = 7'b1111001; // 1
            4'd2: hex_out = 7'b0100100; // 2
            4'd3: hex_out = 7'b0110000; // 3
            4'd4: hex_out = 7'b0011001; // 4
            4'd5: hex_out = 7'b0010010; // 5
            4'd6: hex_out = 7'b0000010; // 6
            4'd7: hex_out = 7'b1111000; // 7
            4'd8: hex_out = 7'b0000000; // 8
            4'd9: hex_out = 7'b0010000; // 9
            default: hex_out = 7'b1111111; // Blank Display
        endcase
endmodule

module close (
    input         clock,       // 50 MHz clock from DE2-115, for instance
    input         rst_n,     // Active-low reset
    output reg [17:0] led
);

    // A simple counter to slow down LED transitions
    // so you can visually see them on the board.
    // Adjust as needed for your desired blink rate.
    reg [23:0] slow_counter;

    always @(posedge clock or negedge rst_n) begin
        if (!rst_n) begin
            slow_counter = 24'd0;
            led          = 18'b000000000000000000;
        end else begin
            // Once led = 4'b1111, we stop updating the logic
            if (led == 18'b111111111111111111) begin
                // Do nothing: freeze
                slow_counter = slow_counter;
                led          = led;
            end else begin
                // Continue counting and update LED
                slow_counter = slow_counter + 1'b1;
                // Example: increment LED every time slow_counter overflows
                if (slow_counter == 24'h999999) begin
                    led[8:0] = {led[7:0], ~led[8]};
						  led[17:9] = {~led[9], led[17:10]};
                    slow_counter = 24'd0;
                end
            end
        end
    end

endmodule

module open (
    input         clock,       // 50 MHz clock from DE2-115, for instance
    input         rst_n,     // Active-low reset
    output reg [17:0] led
);

    // A simple counter to slow down LED transitions
    // so you can visually see them on the board.
    // Adjust as needed for your desired blink rate.
    reg [23:0] slow_counter;

    always @(posedge clock or negedge rst_n) begin
        if (!rst_n) begin
            slow_counter = 24'd0;
            led          = 18'b111111111111111111;
        end else begin
            // Once led = 4'b1111, we stop updating the logic b000000000000000000
            if (led == 18'b000000000000000000) begin
                // Do nothing: freeze
                slow_counter = slow_counter;
                led          = led;
            end else begin
                // Continue counting and update LED
                slow_counter = slow_counter + 1'b1;
                // Example: increment LED every time slow_counter overflows
                if (slow_counter == 24'h999999) begin
						  led[8:0] = {~led[0], led[8:1]};
						  led[17:9] = {led[16:9], ~led[17]};
                    slow_counter = 24'd0;
                end
            end
        end
    end

endmodule

module ClockDivider(
    input wire clk_in,       // 50 MHz input clock
    input wire rst,        // Reset signal
    output reg clk_out       // Slower output clock
);
    parameter DIV_FACTOR = 25_000_000; // Divide by 25M to get a 1Hz clock from 50 MHz
    
    reg [31:0] counter; // Counter variable
    
    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == (DIV_FACTOR - 1)) begin
                counter <= 0;
                clk_out <= ~clk_out; // Toggle output clock
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule

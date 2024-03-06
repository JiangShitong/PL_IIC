`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/01/2024 09:07:25 AM
// Design Name: 
// Module Name: i2c_slave_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module i2c_slave_controller(
	inout sda,
	inout scl
	);
	
	localparam DEVICE_ADDRESS = 7'b1000000;
	localparam CONFIGURATION_REG = 8'b00000000;	
	
	localparam DEVICE = 0;
	localparam DEVICE_ACK = 1;
	localparam REG_ADDRESS = 2;
	localparam REG_ADDRESS_ACK = 3;	
	localparam WRITE_DATA1 = 4;
	localparam WRITE_DATA1_ACK = 5;	
	localparam WRITE_DATA2 = 6;	
	localparam WRITE_DATA2_ACK = 7;	
	localparam READ_DATA1 = 8;	
	localparam READ_DATA1_ACK = 9;
	localparam READ_DATA2 = 10;
	localparam READ_DATA2_ACK = 11;	
	
	reg [7:0] device_addr;
	reg [7:0] reg_addr;
	reg [7:0] counter;
	reg [7:0] state = 0;
	reg [7:0] data_in = 0;
	reg [15:0] data_out = 16'h0000;
	reg sda_out = 0;
	reg sda_in = 0;
	reg start = 0;
	reg write_enable = 0;
	reg write_command;
	
	assign sda = (write_enable == 1) ? sda_out : 'bz;
	
	always @(negedge sda) begin
		if ((start == 0) && (scl == 1)) begin
			start <= 1;	
			counter <= 7;
		end
	end
	
	always @(posedge sda) begin
		if ((start == 1) && (scl == 1)) begin
			state <= DEVICE;
			start <= 0;
			write_enable <= 0;
		end
	end
	
	always @(posedge scl) begin
		if (start == 1) begin
			case(state)
				DEVICE: begin
					device_addr[counter] <= sda;
					if(counter == 0) state <= DEVICE_ACK;
					else counter <= counter - 1;					
				end
				
				DEVICE_ACK: begin
					if(device_addr[7:1] == DEVICE_ADDRESS) begin						
						if(device_addr[0] == 0) begin 						
							write_command <= 1;
							counter <= 7;
							state <= REG_ADDRESS;
						end
						else begin
						write_command <= 0;
						state <= READ_DATA1;
						counter <= 15;
						end
					end
				end
				
				REG_ADDRESS: begin
					reg_addr[counter] <= sda;
					if(counter == 0) state <= REG_ADDRESS_ACK;
					else counter <= counter - 1;					
				end		

				REG_ADDRESS_ACK: begin
					if(reg_addr[7:0] == CONFIGURATION_REG) begin
						counter <= 15;
						if(write_command == 1) begin 
							state <= WRITE_DATA1;
						end
						else begin
						state <= READ_DATA1;
						end
					end
				end				
				
				WRITE_DATA1: begin
					data_out[counter] <= sda;
					if(counter == 8) begin
						state <= WRITE_DATA1_ACK;
					end else counter <= counter - 1;
				end
				
				READ_DATA1: begin
					if(counter == 8) state <= READ_DATA1_ACK;
					else counter <= counter - 1;		
				end		

				READ_DATA1_ACK: begin
					state <= READ_DATA2;	
				end

				READ_DATA2: begin
					if(counter == 0) state <= READ_DATA2_ACK;
					else counter <= counter - 1;		
				end		

				READ_DATA2_ACK: begin
					state <= DEVICE;	
				end					

				WRITE_DATA1_ACK: begin
						if(write_command == 1) begin 
							state <= WRITE_DATA2;
						end
						else begin
						state <= READ_DATA2;
				end	
				end
				
				WRITE_DATA2: begin
					data_out[counter] <= sda;
					if(counter == 0) begin
						state <= WRITE_DATA2_ACK;
					end else counter <= counter - 1;
				end				
				
				WRITE_DATA2_ACK: begin
					state <= DEVICE;					
				end
				
				READ_DATA2: begin
					if(counter == 0) state <= DEVICE;
					else counter <= counter - 1;		
				end
				
			endcase
		end
	end
	
	always @(negedge scl) begin
		case(state)
			
			DEVICE: begin
				write_enable <= 0;			
			end
			
			DEVICE_ACK: begin
				sda_out <= 0;
				write_enable <= 1;	
			end

			REG_ADDRESS: begin
				write_enable <= 0;			
			end
			
			REG_ADDRESS_ACK: begin
				sda_out <= 0;
				write_enable <= 1;	
			end			
			
			WRITE_DATA1: begin
				write_enable <= 0;
			end
			
			WRITE_DATA1_ACK: begin
			    write_enable <= 1;
				sda_out <= 0;
		    end
			
			WRITE_DATA2: begin
				write_enable <= 0;
			end
			
			READ_DATA1: begin
				sda_out <= data_out[counter];
				write_enable <= 1;
			end		

			READ_DATA1_ACK: begin
				write_enable <= 0;
			end					
			
			READ_DATA2: begin
				sda_out <= data_out[counter];
				write_enable <= 1;
			end
			
			READ_DATA2_ACK: begin
				write_enable <= 0;
			end			
			
			WRITE_DATA2_ACK: begin
				sda_out <= 0;
				write_enable <= 1;
			end
		endcase
	end
endmodule

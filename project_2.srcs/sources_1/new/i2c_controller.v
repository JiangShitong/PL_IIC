
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/01/2024 08:57:37 AM
// Design Name: 
// Module Name: i2c_controller
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
module i2c_controller(
	input wire clk, 
	input wire rst,
    input wire write_config,
	input wire write_calibration,
	input wire set_current_address,	
	input wire set_voltage_address,
	input wire set_power_address,
	input wire read_request,	

	inout i2c_sda,
	output wire i2c_scl  
	);

	localparam IDLE = 0;
	localparam START = 1;
	localparam DEVICE = 2;
	localparam DEVICE_ACK = 3;
	localparam ADDRESS = 4;	
	localparam ADDRESS_ACK = 5;
	localparam WRITE_DATA1 = 6;
	localparam WRITE_DATA1_ACK = 7;	
	localparam WRITE_DATA2 = 8;
	localparam WRITE_DATA2_ACK = 9;	
	localparam READ_DATA1 = 10;
	localparam READ_DATA1_ACK = 11;
	localparam READ_DATA2 = 12;
	localparam READ_DATA2_ACK = 13;		
	localparam STOP = 14;
	
	localparam DIVIDE_BY = 250; //400kHz max 400kHz, min 1kHz
	
	wire rst_n;
	assign rst_n = !rst;
	reg [7:0] reg_addr;
	reg [6:0] device_addr;
	reg [15:0] data_in;
	reg enable;
	reg rw;
	wire sda_in;
	assign sda_in = i2c_sda;
	(*mark_debug = "true" *)(*keep = "true"*) reg [15:0] data_out;
	wire ready;
	
	(*mark_debug = "true" *)(*keep = "true"*) reg [7:0] state;
	reg [7:0] saved_device;
	reg [7:0] saved_address;
	reg [15:0] saved_data;
	reg [7:0] counter;
	(*mark_debug = "true" *)(*keep = "true"*)reg [20:0] counter_for_divide_clk;
	reg write_enable;
	reg sda_out;
	reg i2c_scl_enable;
	reg i2c_clk;

	assign ready = ((rst_n == 1) && (state == IDLE)) ? 1 : 0;
	assign i2c_scl = (i2c_scl_enable == 0 ) ? 1 : i2c_clk;
	assign i2c_sda = (write_enable == 1) ? sda_out : 1'bz;

//divided clock	
	always @(posedge clk or negedge rst_n) begin
	    if(!rst_n) begin
		    i2c_clk <= 1'd0;
			counter_for_divide_clk <= 'd0;
	    end
		else if (counter_for_divide_clk == (DIVIDE_BY/2) - 1) begin
			i2c_clk <= ~i2c_clk;
			counter_for_divide_clk <= 0;
		end
		else counter_for_divide_clk <= counter_for_divide_clk + 1;
	end 

//SCL enable	
	always @(posedge i2c_clk or negedge rst_n) begin
		if(!rst_n) begin
			i2c_scl_enable <= 0;
		end else begin
			if ((state == IDLE)  || (state == STOP)) begin
				i2c_scl_enable <= 0;
			end else begin
				i2c_scl_enable <= 1;
			end
		end	
	end
	

wire continuous_read;
	always @(posedge i2c_clk or negedge rst_n) begin
		if(!rst_n) begin
			state <= IDLE;
			saved_device <= 'd0;
			saved_data <= 'd0;
			saved_address <= 'd0;
			counter <= 'd0;
			data_out <= 'd0;
		end		
		else begin
			case(state)			
				IDLE: begin
					if (enable | continuous_read)begin
						state <= START;
						saved_device <= {device_addr, rw};
						saved_data <= data_in;
						saved_address <= reg_addr;
					end			
					else state <= IDLE;
				end

				START: begin
					counter <= 7;
					state <= DEVICE;
				end

				DEVICE: begin
					if (counter == 0) begin 
						state <= DEVICE_ACK;
					end else counter <= counter - 1;
				end	

				DEVICE_ACK: begin
					if (i2c_sda == 0) begin					
					    if(saved_device[0] == 0) begin						
						state <= ADDRESS;
						counter <= 7;
						end
						else begin
						state <= READ_DATA1;
						counter <= 15;
						end
					end 
					else state <= STOP;
				end				

				ADDRESS: begin
					if (counter == 0) begin 
						state <= ADDRESS_ACK;
					end else counter <= counter - 1;
				end					

				ADDRESS_ACK: begin
					if (i2c_sda == 0) begin
						counter <= 15;
						if(reg_addr == 8'd2 && !rw) state <= STOP;
						else if(reg_addr == 8'd4 && !rw) state <= STOP;
						else if(reg_addr == 8'd3 && !rw) state <= STOP;
						else state <= WRITE_DATA1;
					end 
					else state <= STOP;
				end

				WRITE_DATA1: begin
					if(counter == 8) begin
						state <= WRITE_DATA1_ACK;
						counter <= counter - 1;
					end else counter <= counter - 1;
				end
				
				WRITE_DATA1_ACK: begin
					if (i2c_sda == 0) begin
                    state <= WRITE_DATA2;
					end else state <= STOP;
				end		
				
				WRITE_DATA2: begin
					if(counter == 0) begin
						state <= WRITE_DATA2_ACK;
					end else counter <= counter - 1;
				end
				
				WRITE_DATA2_ACK: begin
                    state <= STOP;
				end					

				READ_DATA1: begin
					data_out[counter] <= i2c_sda;
					if (counter == 8) begin 
					    state <= READ_DATA1_ACK;
					    counter <= counter - 1;
					end
					else counter <= counter - 1;
				end
				
				READ_DATA1_ACK: begin
                    state <= READ_DATA2;
				end		

				READ_DATA2: begin
					data_out[counter] <= i2c_sda;
					if (counter == 0) state <= READ_DATA2_ACK;
					else counter <= counter - 1;
				end				
				
				READ_DATA2_ACK: begin
					state <= STOP;
				end

				STOP: begin
					state <= IDLE;
				end
			endcase
		end
	end
	
	always @(negedge i2c_clk or negedge rst_n) begin
		if(!rst_n) begin
			write_enable <= 0;
			sda_out <= 0;
		end else begin
			case(state)
			    IDLE: begin
				    write_enable <= 1;
					sda_out <= 1;
			    end
				
				START: begin
					write_enable <= 1;
					sda_out <= 0;
				end
				
				DEVICE: begin
					sda_out <= saved_device[counter];			
				end
				
				DEVICE_ACK: begin
					write_enable <= 0;
					sda_out <= 1'bz;
				end	

				ADDRESS: begin
				    write_enable <= 1;
					sda_out <= saved_address[counter];
				end				
				
				ADDRESS_ACK: begin
					write_enable <= 0;
					sda_out <= 1'bz;
				end
				
				WRITE_DATA1: begin 
					write_enable <= 1;
					sda_out <= saved_data[counter];
				end
				
				READ_DATA1: begin
					write_enable <= 0;
					sda_out <= 1'bz;
				end			
				
				READ_DATA1_ACK: begin
					write_enable <= 1;
					sda_out <= 0;
				end		

				READ_DATA2: begin
					write_enable <= 0;
					sda_out <= 1'bz;
				end			
				
				READ_DATA2_ACK: begin
					write_enable <= 1;
					sda_out <= 0;
				end					
				
				WRITE_DATA1_ACK: begin
					write_enable <= 0;
					sda_out <= 1'bz;
				end					
				
				WRITE_DATA2: begin 
					write_enable <= 1;
					sda_out <= saved_data[counter];
				end
				
				WRITE_DATA2_ACK: begin
					write_enable <= 0;
					sda_out <= 1'bz;
				end									
				
				STOP: begin
					write_enable <= 1;
					sda_out <= 0;
				end
			endcase
		end
	end

reg write_config_reg;
	always @(posedge i2c_clk or negedge rst_n) begin
		if(!rst_n) begin
			write_config_reg <= 0;
		end else begin
		    write_config_reg <= write_config;
		end	
	end

wire write_config_enable;
assign write_config_enable = (~write_config_reg) & write_config;

reg write_calibration_reg;
wire write_calibration_enable;
always @(posedge i2c_clk or negedge rst_n) begin
	if(!rst_n) begin
		write_calibration_reg <= 0;
	end else begin
	    write_calibration_reg <= write_calibration;
	end	
end
assign write_calibration_enable = (~write_calibration_reg) & write_calibration;

reg set_current_address_reg;
wire set_current_address_enable;
	always @(posedge i2c_clk or negedge rst_n) begin
		if(!rst_n) begin
			set_current_address_reg <= 0;
		end else begin
		    set_current_address_reg <= set_current_address;
		end	
	end
assign set_current_address_enable = (~set_current_address_reg) & set_current_address;

reg set_voltage_address_reg;
wire set_voltage_address_enable;
always @(posedge i2c_clk or negedge rst_n) begin
	if(!rst_n) begin
		set_voltage_address_reg <= 0;
	end else begin
	    set_voltage_address_reg <= set_voltage_address;
	end	
end
assign set_voltage_address_enable = (~set_voltage_address_reg) & set_voltage_address;

reg  set_power_address_reg;
wire set_power_address_enable;
always @(posedge i2c_clk or negedge rst_n) begin
	if(!rst_n) begin
		set_power_address_reg <= 0;
	end else begin
	    set_power_address_reg <= set_power_address;
	end	
end
assign set_power_address_enable = (~set_power_address_reg) & set_power_address;

reg read_request_reg;
wire read_request_enable;
assign continuous_read = !read_request_enable & read_request & read_request_reg;
always @(posedge i2c_clk or negedge rst_n) begin
	if(!rst_n) begin
		read_request_reg <= 0;
	end else begin
	    read_request_reg <= read_request;
	end	
end
assign read_request_enable = (~read_request_reg) & read_request;

wire [5:0] config_state;
assign config_state = {write_config_enable, write_calibration_enable, set_current_address_enable, set_voltage_address_enable, set_power_address_enable, read_request_enable};

always @(posedge i2c_clk or negedge rst_n) begin
    if(!rst_n) begin
	data_in <= 16'd0;
	device_addr <= 7'd0;
	reg_addr <= 8'd0;
	enable <= 1'd0;
	rw <= 1'd0;
	end
	else begin
		case(config_state)
		'b1000_00:begin
			data_in <= 16'b1101_0000_0000_0111;
			device_addr <= 7'b1000000;
			rw <= 1'd0;
			reg_addr <= 8'd0;
			enable <= 1'd1;
		end
		'b0100_00:begin
			data_in <= 16'd512;
			device_addr <= 7'b1000000;
			rw <= 1'd0;
			reg_addr <= 8'd5;
			enable <= 1'd1;	
		end
		'b0010_00:begin
			data_in <= 16'd0;
			device_addr <= 7'b1000000;
			rw <= 1'd0;
			reg_addr <= 8'd4;
			enable <= 1'd1;	
		end	
		'b0001_00:begin
			data_in <= 16'h0000;
			device_addr <= 7'b1000000;
			rw <= 1'd0;
			reg_addr <= 8'd2;
			enable <= 1'd1;	
		end			
		'b0000_10:begin
			data_in <= 16'h0000;
			device_addr <= 7'b1000000;
			rw <= 1'd0;
			reg_addr <= 8'd3;
			enable <= 1'd1;	
		end		
		'b0000_01:begin
			data_in <= 16'h0000;
			device_addr <= 7'b1000000;
			rw <= 1'd1;			
			enable <= 1'd1;	
		end			
		default:begin
			enable <= 1'd0;
		end
		endcase
	end
end

ila_0 your_instance_name (
	.clk(clk), // input wire clk


	.probe0(reg_addr), // input wire [7:0]  probe0  
	.probe1(device_addr), // input wire [6:0]  probe1 
	.probe2(data_in), // input wire [15:0]  probe2 
	.probe3(enable), // input wire [0:0]  probe3 
	.probe4(rw), // input wire [0:0]  probe4 
	.probe5(data_out), // input wire [15:0]  probe5 
	.probe6(state), // input wire [7:0]  probe6 
	.probe7(i2c_clk), // input wire [0:0]  probe7
	.probe8(counter_for_divide_clk), // input wire [7:0]  probe8
	.probe9(i2c_sda), // input wire [0:0]  probe9 
	.probe10(i2c_scl), // input wire [0:0]  probe10
    .probe11(write_enable), // input wire [0:0]  probe11
    .probe12(sda_out)			
);

endmodule

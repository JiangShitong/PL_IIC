`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/01/2024 09:04:47 AM
// Design Name: 
// Module Name: i2c_controller_tb
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

module i2c_controller_tb;

parameter  I2C_frequency = 400000;                   //max 400kHz, min 1kHz
parameter  I2C_tranmit_time0 = 400000/I2C_frequency;
parameter  I2C_tranmit_time = 100000*I2C_tranmit_time0;

	// Inputs
	reg clk;
	reg rst;
    reg write_config, write_calibration, read_current;


	// Bidirs
	wire i2c_sda;
	wire i2c_scl;

	// Instantiate the Unit Under Test (UUT)
	i2c_controller master (
		.clk(clk), 
		.rst_n(rst), 
        .write_config(write_config),
	    .write_calibration(write_calibration),
	    .read_current(read_current),
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl)
	);
	
		
	i2c_slave_controller slave (
    .sda(i2c_sda), 
    .scl(i2c_scl)
    );
	
	initial begin
		clk = 0;
		forever begin
			clk = #5 ~clk;
		end		
	end

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		write_config = 0;
		write_calibration = 0;
		read_current = 0;

		// Wait 100 ns for global reset to finish
		#(5*I2C_tranmit_time);
        
		// Add stimulus here
		rst = 1;
		#(5*I2C_tranmit_time);

        write_config = 1;
		#(5*I2C_tranmit_time);
		write_config = 0;

        read_current = 1;
		#(5*I2C_tranmit_time);
		read_current = 0;	    
		$finish;
		
	end      
endmodule

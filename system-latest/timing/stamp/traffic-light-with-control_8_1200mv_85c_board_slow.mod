/*
 Copyright (C) 2020  Intel Corporation. All rights reserved.
 Your use of Intel Corporation's design tools, logic functions 
 and other software and tools, and any partner logic 
 functions, and any output files from any of the foregoing 
 (including device programming or simulation files), and any 
 associated documentation or information are expressly subject 
 to the terms and conditions of the Intel Program License 
 Subscription Agreement, the Intel Quartus Prime License Agreement,
 the Intel FPGA IP License Agreement, or other applicable license
 agreement, including, without limitation, that your use is for
 the sole purpose of programming logic devices manufactured by
 Intel and sold by Intel or its authorized distributors.  Please
 refer to the applicable agreement for further details, at
 https://fpgasoftware.intel.com/eula.
*/
MODEL
/*MODEL HEADER*/
/*
 This file contains Slow Corner delays for the design using part EP4CE6E22C8
 with speed grade 8, core voltage 1.2V, and temperature 85 Celsius

*/
MODEL_VERSION "1.0";
DESIGN "traffic-light-with-control";
DATE "03/21/2026 21:16:41";
PROGRAM "Quartus Prime";



INPUT rst_n;
INPUT clk;
OUTPUT SVNSEG_DIG[0];
OUTPUT SVNSEG_DIG[1];
OUTPUT SVNSEG_DIG[2];
OUTPUT SVNSEG_DIG[3];
OUTPUT SVNSEG_SEG[0];
OUTPUT SVNSEG_SEG[1];
OUTPUT SVNSEG_SEG[2];
OUTPUT SVNSEG_SEG[3];
OUTPUT SVNSEG_SEG[4];
OUTPUT SVNSEG_SEG[5];
OUTPUT SVNSEG_SEG[6];
OUTPUT SVNSEG_SEG[7];

/*Arc definitions start here*/
pos_clk__SVNSEG_DIG[0]__delay:		DELAY (POSEDGE) clk SVNSEG_DIG[0] ;
pos_clk__SVNSEG_DIG[1]__delay:		DELAY (POSEDGE) clk SVNSEG_DIG[1] ;
pos_clk__SVNSEG_DIG[2]__delay:		DELAY (POSEDGE) clk SVNSEG_DIG[2] ;
pos_clk__SVNSEG_DIG[3]__delay:		DELAY (POSEDGE) clk SVNSEG_DIG[3] ;
pos_clk__SVNSEG_SEG[0]__delay:		DELAY (POSEDGE) clk SVNSEG_SEG[0] ;
pos_clk__SVNSEG_SEG[1]__delay:		DELAY (POSEDGE) clk SVNSEG_SEG[1] ;
pos_clk__SVNSEG_SEG[2]__delay:		DELAY (POSEDGE) clk SVNSEG_SEG[2] ;
pos_clk__SVNSEG_SEG[3]__delay:		DELAY (POSEDGE) clk SVNSEG_SEG[3] ;
pos_clk__SVNSEG_SEG[4]__delay:		DELAY (POSEDGE) clk SVNSEG_SEG[4] ;
pos_clk__SVNSEG_SEG[5]__delay:		DELAY (POSEDGE) clk SVNSEG_SEG[5] ;
pos_clk__SVNSEG_SEG[6]__delay:		DELAY (POSEDGE) clk SVNSEG_SEG[6] ;

ENDMODEL

//********************************************************************************************************
// This model is the property of Cypress Semiconductor Corp.
// and is protected by the US copyright laws, any unauthorized
// copying and distribution is prohibited.
// Cypress reserves the right to change any of the functional 
// specifications without any prior notice.
// Cypress is not liable for any damages which may result from
// the use of this functional model
// -------------------------------------------------------------------------------------------------------
// File name : config.v
// -------------------------------------------------------------------------------------------------------
// Functionality : Verilog behavourial Model for I2C F-RAM
// Source:  CYPRESS Data Sheet : 
// Version:  1.0 Mar 11, 2014
// -------------------------------------------------------------------------------------------------------
// Developed by CYPRESS SEMICONDUCTOR
//
// version |   author     | mod date | changes made
//    1.0  |    MEDU      | 11/03/14 |  New Model
// -------------------------------------------------------------------------------------------------------
// PART DESCRIPTION :
// Part:        All parts of F-RAM I2C
//
// Descripton:  Verilog behavourial Model  for  F-RAM I2C parts
// ----------------------------------------------------------------------------------------------------------  

//*******************************************************
// Define the F-RAM part
//*******************************************************
`define FM24CL16B
   
`ifdef FM24V10
   `define addrBits 17
   `define Memblksize 131072
   `define freq_fs_1MHz
      
   parameter Vddmax    =  3.6;      
   parameter hasWP = 1;
   parameter hasA0 = 0;
   parameter hasDeviceSelect = 1;   
   parameter hasSleep = 1;      
   parameter hasDeviceid = 1;         
   parameter hasSN = 0;
   parameter single_byte_addr = 0;
   parameter tPU = 250000;
   parameter tREC = 400000;
   parameter hasHSMode = 1;     
   
   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h44;
   parameter DEV_ID_LSB = 8'h00;   
   
`endif

`ifdef FM24VN10
   `define addrBits 17
   `define Memblksize 131072
   `define freq_fs_1MHz
   
   parameter Vddmax    =  3.6;
   parameter hasWP = 1;
   parameter hasA0 = 0;
   parameter hasDeviceSelect = 1;      
   parameter hasSleep = 1; 
   parameter hasDeviceid = 1;            
   parameter hasSN = 1;
   parameter single_byte_addr = 0; 
   parameter tPU = 250000;   
   parameter tREC = 400000;
   parameter hasHSMode = 1;        
   
   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h44;
   parameter DEV_ID_LSB = 8'h80;   
   
`endif

`ifdef FM24V05
   `define addrBits 16
   `define Memblksize 65536
   `define freq_fs_1MHz  
      
   parameter Vddmax    =  3.6;      
   parameter hasWP = 1;
   parameter hasA0 = 1;
   parameter hasDeviceSelect = 1;   
   parameter hasSleep = 1;     
   parameter hasDeviceid = 1;            
   parameter hasSN = 0;
   parameter single_byte_addr = 0;   
   parameter tPU = 250000;      
   parameter tREC = 400000;
   parameter hasHSMode = 1;     
   
   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h43;
   parameter DEV_ID_LSB = 8'h00;   
`endif

`ifdef FM24V02
   `define addrBits 15
   `define Memblksize 32768
   `define freq_fs_1MHz    
      
   parameter Vddmax    =  3.6;      
   parameter hasWP = 1;
   parameter hasA0 = 1;
   parameter hasDeviceSelect = 1;   
   parameter hasSleep = 1; 
   parameter hasDeviceid = 1;            
   parameter hasSN = 0;
   parameter single_byte_addr = 0;  
   parameter tPU = 250000;         
   parameter tREC = 400000;
   parameter hasHSMode = 1;     
   
   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h42;
   parameter DEV_ID_LSB = 8'h00;  
   
`endif

`ifdef FM24V01
   `define addrBits 14
   `define Memblksize 16384
   `define freq_fs_1MHz  
      
   parameter Vddmax    =  3.6;      
   parameter hasWP = 1;
   parameter hasA0 = 1;
   parameter hasDeviceSelect = 1;   
   parameter hasSleep = 1;   
   parameter hasDeviceid = 1;            
   parameter hasSN = 0;
   parameter single_byte_addr = 0; 
   parameter tPU = 250000;            
   parameter tREC = 400000;
   parameter hasHSMode = 1;     
   
   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h41;
   parameter DEV_ID_LSB = 8'h00;    
`endif

`ifdef FM24CL64B
   `define addrBits 13
   `define Memblksize 8192
   `define freq_1MHz   
      
   parameter Vddmax    =  3.65;      
   parameter hasWP = 1;
   parameter hasA0 = 1;
   parameter hasDeviceSelect = 1;   
   parameter hasSleep = 0;  
   parameter hasDeviceid = 0;            
   parameter hasSN = 0;
   parameter single_byte_addr = 0;   
   parameter hasHSMode = 0;
   parameter tPU = 1000000;               
   parameter tREC = 0;

   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h00;
   parameter DEV_ID_LSB = 8'h00;
   
`endif

`ifdef FM24CL16B
   `define addrBits 11
   `define Memblksize 2048
   `define freq_1MHz      
      
   parameter Vddmax    =  3.65;      
   parameter hasWP = 1;
   parameter hasA0 = 0;
   parameter hasDeviceSelect = 0;   
   parameter hasSleep = 0;  
   parameter hasDeviceid = 0;            
   parameter hasSN = 0;
   parameter single_byte_addr = 1;   
   parameter hasHSMode = 0;
   parameter tPU = 1000000;                  
   parameter tREC = 0;   
   
   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h00;
   parameter DEV_ID_LSB = 8'h00;   
`endif

`ifdef FM24CL04B
   `define addrBits 9
   `define Memblksize 512
   `define freq_1MHz      
      
   parameter Vddmax    =  3.65;      
   parameter hasWP = 1;
   parameter hasA0 = 0;
   parameter hasDeviceSelect = 1;   
   parameter hasSleep = 0;  
   parameter hasDeviceid = 0;            
   parameter hasSN = 0;
   parameter single_byte_addr = 1; 
   parameter hasHSMode = 0;   
   parameter tPU = 1000000;                     
   parameter tREC = 0;   
   
   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h00;
   parameter DEV_ID_LSB = 8'h00;   
`endif

`ifdef FM24C64B
   `define addrBits 13
   `define Memblksize 8192
   `define freq_1MHz      
      
   parameter Vddmax    =  5.5;      
   parameter hasWP = 1;
   parameter hasA0 = 1;
   parameter hasDeviceSelect = 1;   
   parameter hasSleep = 0;  
   parameter hasDeviceid = 0;            
   parameter hasSN = 0;
   parameter single_byte_addr = 0;   
   parameter hasHSMode = 0;
   parameter tPU = 10000000;
   parameter tREC = 0;   
   
   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h00;
   parameter DEV_ID_LSB = 8'h00;   
`endif

`ifdef FM24C16B
   `define addrBits 11
   `define Memblksize 2048
   `define freq_1MHz      
      
   parameter Vddmax    =  5.5;      
   parameter hasWP = 1;
   parameter hasA0 = 0;
   parameter hasDeviceSelect = 0;   
   parameter hasSleep = 0;  
   parameter hasDeviceid = 0;            
   parameter hasSN = 0;
   parameter single_byte_addr = 1;   
   parameter hasHSMode = 0;
   parameter tPU = 1000000;   
   parameter tREC = 0;   

   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h00;
   parameter DEV_ID_LSB = 8'h00;
   
`endif

`ifdef FM24C04B
   `define addrBits 9
   `define Memblksize 512
   `define freq_1MHz      
      
   parameter Vddmax    =  5.5;      
   parameter hasWP = 1;
   parameter hasA0 = 0;
   parameter hasDeviceSelect = 1;      
   parameter hasSleep = 0;  
   parameter hasDeviceid = 0;            
   parameter hasSN = 0;
   parameter single_byte_addr = 1;   
   parameter hasHSMode = 0;  
   parameter tPU = 1000000;      
   parameter tREC = 0;   
   
   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h00;
   parameter DEV_ID_LSB = 8'h00;   
`endif

`ifdef FM24W256
   `define addrBits 15
   `define Memblksize 32768
   `define freq_1MHz      
      
   parameter Vddmax    =  5.5;      
   parameter hasWP = 1;
   parameter hasA0 = 1;
   parameter hasDeviceSelect = 1;   
   parameter hasSleep = 0;  
   parameter hasDeviceid = 0;            
   parameter hasSN = 0;
   parameter single_byte_addr = 0;   
   parameter hasHSMode = 0;   
   parameter tPU = 1000000;         
   parameter tREC = 0;   

   parameter DEV_ID_MSB = 8'h00;
   parameter DEV_ID_ISB = 8'h00;
   parameter DEV_ID_LSB = 8'h00;   
`endif


// Parameter definitions
  
`ifdef freq_100KHz
   parameter tHIGH   =  4000;
   parameter tLOW    =  4700;
   parameter tSUDATA =   250;
   parameter tHDDATA =     0;
   parameter tSUSTO  =  4000;
   parameter tBUF    =  4700;
   parameter tSUSTA  =  4700;
   parameter tHDSTA  =  4000;   
   parameter tAA     =  3000;         // 3000 : MAX spec
`endif

`ifdef freq_400KHz
   parameter tHIGH   =   600;
   parameter tLOW    =  1300;
   parameter tSUDATA =   100;
   parameter tHDDATA =     0;
   parameter tSUSTO  =   600;
   parameter tBUF    =  1300;
   parameter tSUSTA  =   600;
   parameter tHDSTA  =   600;   
   parameter tAA     =   900;         // 900 : MAX spec
`endif


// For FM24C04B, FM24C16B, FM24C64B, FM24CL04B, FM24CL16B, FM24CL64B, FM24W256
`ifdef freq_1MHz
   parameter tHIGH   =  400;
   parameter tLOW    =  600;
   parameter tSUDATA =  100;
   parameter tHDDATA =    0;
   parameter tSUSTO  =  250;
   parameter tBUF    =  500;
   parameter tSUSTA  =  250;
   parameter tHDSTA  =  250;  
   parameter tAA     =  550;          // 550 : MAX spec
`endif

// For FM24V01, FM24V02, FM24V05, FM24V10, FM24VN10
`ifdef freq_fs_1MHz
   parameter tHIGH   =  260;
   parameter tLOW    =  500;
   parameter tSUDATA =   50;
   parameter tHDDATA =    0;
   parameter tSUSTO  =  260;
   parameter tBUF    =  500;
   parameter tSUSTA  =  260;
   parameter tHDSTA  =  260;  
   parameter tAA     =  450;          // 450 : MAX spec
`endif

`ifdef freq_3p4MHz
   parameter tHIGH   =   60;
   parameter tLOW    =  160;
   parameter tSUDATA =   10;
   parameter tHDDATA =    0;
   parameter tSUSTO  =  160;
   parameter tBUF    =  300;
   parameter tSUSTA  =  160;
   parameter tHDSTA  =  160; 
   parameter tAA     =  130;          // 130 : MAX spec  
`endif

//_______________________________________________________________________
//	Uncomment only if you want to initialize memory with values from a file
//
//`define		initMemFile		"init.dat"
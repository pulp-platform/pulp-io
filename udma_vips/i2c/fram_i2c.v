//********************************************************************************************************
// This model is the property of Cypress Semiconductor Corp.
// and is protected by the US copyright laws, any unauthorized
// copying and distribution is prohibited.
// Cypress reserves the right to change any of the functional 
// specifications without any prior notice.
// Cypress is not liable for any damages which may result from
// the use of this functional model
// -------------------------------------------------------------------------------------------------------
// File name : FRAM_I2C.v
// -------------------------------------------------------------------------------------------------------
// Functionality : Verilog behavourial Model for I2C F-RAM
// Source:  CYPRESS Data Sheet : 
// Version:  1.2 Feb 24, 2014
// -------------------------------------------------------------------------------------------------------
// Developed by CYPRESS SEMICONDUCTOR
//
// version |   author     | mod date | changes made
//    1.1  |    MEDU      | 20/03/17 |  Added tPU
//    1.0  |    MEDU      | 24/02/14 |  New Model
// -------------------------------------------------------------------------------------------------------
// PART DESCRIPTION :
// Part:        All parts of F-RAM I2C
//
// Descripton:  Verilog behavourial Model  for  F-RAM I2C parts
// ----------------------------------------------------------------------------------------------------------  

`timescale 1ns/10ps

module FRAM_I2C (power_cycle, A0, A1, A2, WP, SDA, SCL, RESET);

   input                power_cycle;
   
   input                A0;                             // chip select bit
   input                A1;                             // chip select bit
   input                A2;                             // chip select bit

   input                WP;                             // write protect pin

   inout                SDA;                            // serial data I/O
   input                SCL;                            // serial data clock
   
   input                RESET;                          // system reset

`include "config.v"   

 
// *******************************************************************************************************
// **   DECLARATIONS                                                                                    **
// *******************************************************************************************************

  
   reg                  SDA_DO;                         // serial data - output
   reg                  SDA_OE;                         // serial data - output enable

   wire                 SDA_DriveEnable;                // serial data output enable
   reg                  SDA_DriveEnableDlyd;            // serial data output enable - delayed

   wire [02:00]         ChipAddress;                    // hardwired chip address

   reg  [03:00]         BitCounter;                     // serial bit counter

   reg                  START_Rcvd;                     // START bit received flag
   reg                  STOP_Rcvd;                      // STOP bit received flag
   reg                  SLAVE_ADDR_Rcvd;                // SRAM slave address byte received flag
   reg                  ADHI_Rcvd;                      // byte address hi received flag
   reg                  ADLO_Rcvd;                      // byte address lo received flag
   reg                  MACK_Rcvd;                      // master acknowledge received flag

   reg                  WrCycle;                        // memory write cycle
   reg                  RdCycle;                        // memory read cycle

   reg  [07:00]         ShiftRegister;                  // input data shift register

   reg  [07:00]         SlaveAddress;                    // Slave Address register
   wire                 RdWrBit;                        // read/write control bit

   reg  [`addrBits-1:00]         StartAddress;                   // memory access starting address

   reg  [07:00]         WrDataByte [0:127];             // memory write data buffer
   wire [07:00]         RdDataByte;                     // memory read data

   reg  [`addrBits-1:00]         WrCounter;                      // memory write buffer counter

   reg  [06:00]         WrPointer;                      // memory write buffer pointer
   reg  [`addrBits-1:00]         RdPointer;                      // memory read address pointer

   reg                  WriteActive;                    // memory write cycle active

   reg  [07:00]         MemoryBlock [0:`Memblksize-1];           // SRAM memory array
   
   reg [24:0] addrMax, addrBeg, addrEnd;
   reg [7:0] device_id[0:2];   
   reg [7:0] serial_no[0:7];
   
   reg       generate_ack;
   

   integer              LoopIndex;                      // iterative loop index
   integer              wr_status;

   real                 Vdd;
   reg                  fram_busy;
   reg                  comm_nacked;
   
   integer i;
   real    j;   
   reg     time_low;
   reg     memProt;
   
   reg     rsvd_slave_id_rcvd;
   reg     special_cmd;
   reg     sleep_mode;
   reg     device_id_read;
   reg     serial_no_read;

   time negSCLTim;
   time posSCLTim;
   time negSDATim;
   time posSDATim;
   time STARTTim;
   time STOPTim;

   parameter [7:0] RSVD_SLAVE_ID  = 'hF8;
   parameter [7:0] SLEEP_ADDR  = 'h86;   
   parameter [7:0] DEVICE_ID_ADDR  = 'hF9;      
   parameter [7:0] SERIAL_NO_ADDR  = 'hCD;         

   wire Vddx_hi = ((Vdd >= 2.0) && (sleep_mode == 0));   
   wire Vddx_lo = (Vdd < 2.0 || (sleep_mode == 'b1));
   
   wire FRAM_1MBit  = (`Memblksize == 131072);
   wire FRAM_16KBit = (`Memblksize == 2048);
   wire FRAM_4KBit  = (`Memblksize == 512);

   time powerup_time = 0;
   time powerdown_time = 0;

   `define powerup_access ((powerup_time > powerdown_time) && (($time - powerup_time) >= tPU))

   wire slave_address_match = (ShiftRegister[07:04] == 4'b1010) & (!hasDeviceSelect || (( hasA0 == 0 & ShiftRegister[03:02] == ChipAddress[02:01]) || ( hasA0 == 1 & ShiftRegister[03:01] == ChipAddress[02:00])));
   
// *******************************************************************************************************
// **   INITIALIZATION                                                                                  **
// *******************************************************************************************************

   initial begin
      SDA_DO = 0;
      SDA_OE = 0;
   end

   initial begin
      START_Rcvd = 0;
      STOP_Rcvd  = 0;
      SLAVE_ADDR_Rcvd  = 0;
      ADHI_Rcvd  = 0;
      ADLO_Rcvd  = 0;
      MACK_Rcvd  = 0;
   end

   initial begin
      BitCounter  = 0;
      SlaveAddress = 0;
   end

   initial begin
         device_id[0] = DEV_ID_MSB;
         device_id[1] = DEV_ID_ISB;
         device_id[2] = DEV_ID_LSB;
      
     `ifdef FM24VN10
         // Serial Number
         serial_no[0] = 'h00;
         serial_no[1] = 'h00;
         serial_no[2] = 'h00;         
         serial_no[3] = 'h00;
         serial_no[4] = 'h00;
         serial_no[5] = 'h00;         
         serial_no[6] = 'h00;
         serial_no[7] = 'h00;
      `endif
   end
    
   initial begin
      WrCycle = 0;
      RdCycle = 0;
      STOPTim = 0;
      STARTTim = 0;
      WriteActive = 0;
      sleep_mode = 0;
      negSCLTim = 0;
      posSCLTim = 0;      

      addrMax = 24'h0000;
      for(i=0; i<`addrBits; i=i+1)
      addrMax[i]=1;   

      addrBeg = 24'h0000;
      addrEnd = addrMax;
      
      $display("*");
      $display("* F-RAM Size:                          %h",addrMax+1);
      $display("* Begin. address:                      %h",addrBeg);
      $display("* End address:                         %h",addrEnd);
      $display("*");
      $display("===========================================================");
      $display;
      memProt = 1'b0;
      fram_busy = 0;  
      wr_status = 0;
      pwr_up;
   end

   initial begin
    `ifdef initMemFile
        //
        // memory initialization with data from file
        //
        $readmemh(`initMemFile,MemoryBlock);
        $display("Simulated memory array initialization with data from %s...",`initMemFile);
    `else
        //
        // memory initialization with 00
        //
        for(i=0; i<`Memblksize; i=i+1)
            begin
            MemoryBlock[i] = 8'h00;
            end
            $display("Simulated memory array initialization with 8'h00...");
    `endif   
   end
   
   assign ChipAddress = (hasA0 == 1) ? {A2,A1,A0} : {A2,A1,1'b0};


// -------------------------------------------------------------------------------------------------------
//    START Bit Detection
// -------------------------------------------------------------------------------------------------------

   always @(negedge SDA) begin
      if ((SCL == 1) && (fram_busy == 0 || sleep_mode == 1) && (`powerup_access == 1)) begin
            STARTTim = $time;
            if((STARTTim - STOPTim) >= tBUF) begin
               if((STARTTim - posSCLTim) >= tSUSTA) begin
                  START_Rcvd <= 1;
                  STOP_Rcvd  <= 0;
                  SLAVE_ADDR_Rcvd  <= 0;
                  ADHI_Rcvd  <= 0;
                  ADLO_Rcvd  <= 0;
                  MACK_Rcvd  <= 0;
                  rsvd_slave_id_rcvd <= 0;
                  device_id_read <= 0;
                  serial_no_read <= 0;
                  generate_ack <= 0;
                  
                  WrCycle <= #1 0;
                  RdCycle <= #1 0;
                  comm_nacked <= 'b0;

                  BitCounter <= 0;
               end
               else begin
                  $display(" WARNING: START ignored (tSUSTA - Setup time for START condition - not respected: %d < tSUSTA) ",(STARTTim - posSCLTim),$time);                                        
               end
            end
            else begin
               $display(" WARNING: START ignored (tBUF - Bus free time between STOP and next START condition - not respected: %d < tBUF) ",STARTTim - STOPTim,$time);                     
            end
      end
   end

// -------------------------------------------------------------------------------------------------------
//      STOP Bit Detection
// -------------------------------------------------------------------------------------------------------

   always @(posedge SDA) begin
      if ((SCL == 1) && (fram_busy == 0) && (`powerup_access == 1)) begin
         START_Rcvd <= 0;
         STOP_Rcvd  <= 1;
         SLAVE_ADDR_Rcvd  <= 0;
         ADHI_Rcvd  <= 0;
         ADLO_Rcvd  <= 0;
         MACK_Rcvd  <= 0;
         rsvd_slave_id_rcvd <= 0;
         device_id_read <= 0;
         serial_no_read <= 0;
         special_cmd <= 0;         
         WrCycle <= #1 0;
         RdCycle <= #1 0;
         comm_nacked <= 'b0;
         generate_ack <= 0;

         BitCounter <= 10;
         STOPTim = $time;
      end
   end

// -------------------------------------------------------------------------------------------------------
//     Input Shift Register
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCL) begin
      generate_ack <= 0;
      if((fram_busy == 0) && (`powerup_access == 1)) begin
         ShiftRegister[00] <= SDA;
         ShiftRegister[01] <= ShiftRegister[00];
         ShiftRegister[02] <= ShiftRegister[01];
         ShiftRegister[03] <= ShiftRegister[02];
         ShiftRegister[04] <= ShiftRegister[03];
         ShiftRegister[05] <= ShiftRegister[04];
         ShiftRegister[06] <= ShiftRegister[05];
         ShiftRegister[07] <= ShiftRegister[06];
      end
   end

// -------------------------------------------------------------------------------------------------------
//     Input Bit Counter
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCL) begin
      if ((BitCounter < 10) && (fram_busy == 0) && (`powerup_access == 1)) BitCounter <= BitCounter + 1;
   end

// -------------------------------------------------------------------------------------------------------
//      Slave Address Register
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCL && (fram_busy == 0 || sleep_mode == 1) && (`powerup_access == 1)) begin
      if (START_Rcvd & (BitCounter == 8)) begin
         if (!WriteActive & slave_address_match) begin
            if(sleep_mode == 1) begin
                #tREC;
                sleep_mode <= 0;
                fram_busy  <= 0;
            end
            else begin
                if (ShiftRegister[00] == 0) WrCycle <= 1; 
                if (ShiftRegister[00] == 1) RdCycle <= 1;

                if(FRAM_1MBit || FRAM_4KBit) begin
                   StartAddress[`addrBits-1] <= ShiftRegister[01];         // Copy block/page select bit
                   RdPointer[`addrBits-1]    <= ShiftRegister[01];         // Copy block/page select bit
                end
                else if(FRAM_16KBit) begin
                   StartAddress[`addrBits-1] <= ShiftRegister[01];         // Copy block/page select bit
                   RdPointer[`addrBits-1]    <= ShiftRegister[01];         // Copy block/page select bit 

                   StartAddress[`addrBits-2] <= ShiftRegister[02];         // Copy block/page select bit
                   RdPointer[`addrBits-2]    <= ShiftRegister[02];         // Copy block/page select bit 

                   StartAddress[`addrBits-3] <= ShiftRegister[03];         // Copy block/page select bit
                   RdPointer[`addrBits-3]    <= ShiftRegister[03];         // Copy block/page select bit                    
                end

                SlaveAddress     <= ShiftRegister[07:00];
                SLAVE_ADDR_Rcvd <= 1;
                $display("\nFRAM Slave Address %h received\n", ShiftRegister[07:00]);            
            end
         end
         else if (!WriteActive && (ShiftRegister[07:00] == RSVD_SLAVE_ID)) begin
               rsvd_slave_id_rcvd <= 1;
               special_cmd        <= 0;
               sleep_mode <= 0;
               $display("\nFRAM Rsvd Slave ID %h received\n", ShiftRegister[07:00]);               
         end
         else if (!WriteActive && (ShiftRegister[07:00] == SLEEP_ADDR) && (special_cmd == 1'b1) && hasSleep) begin
               sleep_mode <= 1;
               $display("\nFRAM Sleep Mode Command %h Received\n", ShiftRegister[07:00]);               
         end         
         else if (!WriteActive && (ShiftRegister[07:00] == DEVICE_ID_ADDR) && (special_cmd == 1'b1) && hasDeviceid) begin
               device_id_read <= 1;
               RdPointer <= 0;
               RdCycle <= 1;               
               $display("\nFRAM Device ID Command %h Received\n", ShiftRegister[07:00]);               
         end                  
         else if (!WriteActive && (ShiftRegister[07:00] == SERIAL_NO_ADDR) && (special_cmd == 1'b1) && hasSN) begin
               serial_no_read <= 1;
               RdPointer <= 0;
               RdCycle <= 1;               
               $display("\nFRAM Serial Number Read Command %h Received\n", ShiftRegister[07:00]);               
         end                           
         else if (!WriteActive && (special_cmd == 1'b1)) begin
               special_cmd <= 0;
         end

         START_Rcvd <= 0;
      end
   end

   assign RdWrBit = SlaveAddress[00];

// F-RAM enters sleep once stop is recevied   
   always @(posedge STOP_Rcvd) begin
      if((sleep_mode == 1)&& (`powerup_access == 1))
      begin
         fram_busy  <= 1;  
         special_cmd <= 0;                        
      end
   end   

// -------------------------------------------------------------------------------------------------------
//      Sleep Slave Address
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCL && (fram_busy == 0) && (`powerup_access == 1)) begin
      if (rsvd_slave_id_rcvd & (BitCounter == 8) & (fram_busy == 0)) begin
         if (!WriteActive & (rsvd_slave_id_rcvd == 1'b1 && slave_address_match)) begin
               $display("\FRAM Slave Address received for Reserved Command\n");
               special_cmd = 1;
         end
         else
         begin
               special_cmd = 0;
         end
         
         rsvd_slave_id_rcvd = 0;
      end
   end
   
// -------------------------------------------------------------------------------------------------------
//      Byte Address Register
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCL && fram_busy == 0) begin
      if (SLAVE_ADDR_Rcvd && (BitCounter == 8) && (fram_busy == 0) && (`powerup_access == 1)) begin
         if (RdWrBit == 0) begin
         
            if(FRAM_1MBit) begin
             `ifndef FM24CL04B
             `ifndef FM24C04B				    
               StartAddress[`addrBits-2:08] <= ShiftRegister[07:00];
               RdPointer[`addrBits-2:08]    <= ShiftRegister[07:00];
             `endif
             `endif				 
               ADHI_Rcvd <= 1;
            end
            else if(FRAM_16KBit || FRAM_4KBit) begin
               StartAddress[07:00] <= ShiftRegister[07:00];
               RdPointer[07:00]    <= ShiftRegister[07:00];
               ADLO_Rcvd <= 1;
            end            
            else begin
             `ifndef FM24CL04B
             `ifndef FM24C04B
               StartAddress[`addrBits-1:08] <= ShiftRegister[07:00];
               RdPointer[`addrBits-1:08]    <= ShiftRegister[07:00];
             `endif
             `endif
               ADHI_Rcvd <= 1;
            end
         end

         WrCounter <= 0;
         WrPointer <= 0;

         SLAVE_ADDR_Rcvd <= 0;
      end
   end

   always @(negedge SCL) begin
      if (ADHI_Rcvd & (BitCounter == 8) && (fram_busy == 0) && (`powerup_access == 1)) begin
         if (RdWrBit == 0) begin
            StartAddress[07:00] <= ShiftRegister[07:00];
            RdPointer[07:00]    <= ShiftRegister[07:00];

            ADLO_Rcvd <= 1;
         end

         WrCounter <= 0;
         WrPointer <= 0;

         ADHI_Rcvd <= 0;
      end
   end

// -------------------------------------------------------------------------------------------------------
//      Write Data Buffer
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCL) begin
      if (ADLO_Rcvd & (BitCounter == 8) && (fram_busy == 0) && (`powerup_access == 1)) begin
         if (RdWrBit == 0) begin
            WrDataByte[WrPointer] <= ShiftRegister[07:00];

            WrCounter <= WrCounter + 1;
            WrPointer <= WrPointer + 1;
         end
      end
   end
   
 
// -------------------------------------------------------------------------------------------------------
//      Acknowledge Generator
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCL) begin
      if (!WriteActive && (fram_busy == 0) && (`powerup_access == 1)) begin
         if (BitCounter == 8) begin
            if ((WrCycle || (rsvd_slave_id_rcvd == 1'b1 && slave_address_match) || (START_Rcvd & ((ShiftRegister[07:00] == RSVD_SLAVE_ID && (hasSleep || hasDeviceid || hasSN)) || (special_cmd == 1'b1 & ((hasSleep && ShiftRegister[07:00] == SLEEP_ADDR) || (hasSN && ShiftRegister[07:00] == SERIAL_NO_ADDR) || (hasDeviceid && ShiftRegister[07:00] == DEVICE_ID_ADDR))) || (!hasDeviceSelect || (( hasA0 == 0 & ShiftRegister[03:02] == ChipAddress[02:01]) || ( hasA0 == 1 & ShiftRegister[03:01] == ChipAddress[02:00])))))) & !comm_nacked) begin
               SDA_DO <= 0;
               SDA_OE <= 1;
               generate_ack <= 1;
            end
            else
               comm_nacked <= 'b1;              
         end
         if (BitCounter == 9) begin
            BitCounter <= 0;

         if (!RdCycle) begin
             SDA_DO <= 0;
             SDA_OE <= 0;
         end

         end
      end
   end 

// -------------------------------------------------------------------------------------------------------
//      Acknowledge Detect
// -------------------------------------------------------------------------------------------------------

   always @(posedge SCL) begin
      if ((RdCycle) & (BitCounter == 8) && (fram_busy == 0) && (`powerup_access == 1)) begin
         if ((SDA == 0) & (SDA_OE == 0)) MACK_Rcvd <= 1;
      end
   end

   always @(negedge SCL) MACK_Rcvd <= 0;

// -------------------------------------------------------------------------------------------------------
//      Write Cycle Timer
// -------------------------------------------------------------------------------------------------------

   always @(posedge STOP_Rcvd) begin
      if (WrCycle && (WP == 0) && (WrCounter > 0) && (fram_busy == 0) && (`powerup_access == 1)) begin
         WriteActive = 1;
         #10;
         WriteActive = 0;
      end
   end

   always @(posedge STOP_Rcvd) begin
      #(100.0);
      STOP_Rcvd = 0;
   end

// -------------------------------------------------------------------------------------------------------
//      Write Cycle Processor
// -------------------------------------------------------------------------------------------------------

   always @(negedge WriteActive) begin
      if((fram_busy == 0) && (`powerup_access == 1)) begin
         for (LoopIndex = 0; LoopIndex < WrCounter; LoopIndex = LoopIndex + 1) begin
            if(memProt == 1'b0 || (((StartAddress[`addrBits-1:00] + LoopIndex[06:00]) < addrBeg) || ((StartAddress[`addrBits-1:00] + LoopIndex[06:00]) > addrEnd)))
                begin
               MemoryBlock[StartAddress[`addrBits-1:00] + LoopIndex[06:00]] = WrDataByte[LoopIndex[06:00]];
//               $display("Write = %X , Addr = %X", StartAddress[`addrBits-1:00] + LoopIndex[06:00], WrDataByte[LoopIndex[06:00]]);
               wr_status = 1;
                end 
            else
               $display("WARNING: Write to Block Protected Area");

         end
      end
   end

  
// -------------------------------------------------------------------------------------------------------
//      Read Data Multiplexor
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCL) begin
      if ((BitCounter == 8) && (fram_busy == 0) && (`powerup_access == 1)) begin
         if (WrCycle & ADLO_Rcvd) begin
            RdPointer <= StartAddress + WrPointer + 1;
         end
           
         if (RdCycle) begin
            RdPointer <= RdPointer + 1;
//            $display("Read = %X, Addr = %X", RdPointer[`addrBits-1:00], MemoryBlock[RdPointer[`addrBits-1:00]]);
         end
      end
   end

   assign RdDataByte   = (device_id_read == 1) ? (device_id[RdPointer[01:00]]) : ((serial_no_read == 1) ? serial_no[RdPointer[02:00]] : (MemoryBlock[RdPointer[`addrBits-1:00]]));
   
// -------------------------------------------------------------------------------------------------------
//      Read Data Processor
// -------------------------------------------------------------------------------------------------------

   always @(negedge SCL) begin
      if (RdCycle && (fram_busy == 0) && (`powerup_access == 1)) begin
         if (BitCounter == 8) begin
            SDA_DO <= 0;
            SDA_OE <= 0;
         end
         else if (BitCounter == 9) begin
            SDA_DO <= RdDataByte[07];

            if (MACK_Rcvd) SDA_OE <= 1;
         end
         else begin
            SDA_DO <= RdDataByte[7-BitCounter];
         end
      end
   end

// -------------------------------------------------------------------------------------------------------
//      SDA Data I/O Buffer
// -------------------------------------------------------------------------------------------------------

   bufif1 (SDA, 1'b0, SDA_DriveEnableDlyd);

   assign SDA_DriveEnable = !SDA_DO & SDA_OE;
   
   always @(SDA_DriveEnable) begin
      if(generate_ack)
         SDA_DriveEnableDlyd <= SDA_DriveEnable;      
      else
         SDA_DriveEnableDlyd <= #(tAA) SDA_DriveEnable;
   end

// -------------------------------------------------------------------------------------------------------
//      TASKS
// -------------------------------------------------------------------------------------------------------

always @(posedge power_cycle)
begin
    $display(" F-RAM Power UP : %d", $time);
    powerup_time = $time;
    pwr_up;
end

always @(negedge power_cycle)
begin
    $display(" F-RAM Power DOWN : %d ", $time);   
    powerdown_time = $time;    
    pwr_down;
end

task pwr_down;
begin
    for(j=Vddmax;j>=0;j=j-0.1)
    begin
        #1 Vdd = j;
    end
end
endtask

task pwr_up;
begin
    for(j=0.0;j<=Vddmax;j=j+0.1)
    begin
        #1 Vdd = j;
    end   
end  
endtask

// -------------------------------------------------------------------------------------------------------
//      Timing check
// -------------------------------------------------------------------------------------------------------
always @(negedge SCL) 
begin
    negSCLTim = $time;
    if((negSCLTim - STARTTim ) < tHDSTA)
    begin
           START_Rcvd <= 0;
           $display(" WARNING: START ignored (tHDSTA - Hold time for START condition - not respected: %d < tHDSTA) ",(negSCLTim - STARTTim ),$time);                        
    end
end 

always @(posedge SCL) 
begin
    posSCLTim = $time;
end 

always @(negedge SDA) 
    negSDATim = $time;

always @(posedge SDA) 
    posSDATim = $time;
    
specify
   $width(posedge SCL, tHIGH);
   $width(negedge SCL, tLOW);

   $setup(SDA, posedge SCL, tSUDATA);

   $hold(SCL, posedge SDA &&& (SCL == 1), tSUSTO);         
   $hold(SDA, posedge SCL, tHDDATA);   
   $hold(SCL, negedge SDA &&& (SCL == 1), tHDDATA);      
endspecify

endmodule

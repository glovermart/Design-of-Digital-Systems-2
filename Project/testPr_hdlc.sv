//////////////////////////////////////////////////
// Title:   testPr_hdlc
// Author: 
// Date:  
//////////////////////////////////////////////////

/* testPr_hdlc contains the simulation and immediate assertion code of the
   testbench. 

   For this exercise you will write immediate assertions for the Rx module which
   should verify correct values in some of the Rx registers for:
   - Normal behavior
   - Buffer overflow 
   - Aborts

   HINT:
   - A ReadAddress() task is provided, and addresses are documentet in the 
     HDLC Module Design Description
*/

program testPr_hdlc(
  in_hdlc uin_hdlc
);
  
  int TbErrorCnt;

  /****************************************************************************
   *                                                                          *
   *                               Coverage                                   *
   *                                                                          *
   ****************************************************************************/

    covergroup reg_cover @(posedge uin_hdlc.Clk);
    Address : coverpoint uin_hdlc.Address {
      bins TX_SC    = {0};
      bins TX_Buff  = {1};
      bins RX_SC    = {2};
      bins RX_Buff  = {3};
      bins RX_Len   = {4};
      ignore_bins other = {[5:7]};
    }
    WrEnable : coverpoint uin_hdlc.WriteEnable {
      bins write = {1};
      bins notwrite = {0};
    }
    RdEnable : coverpoint uin_hdlc.ReadEnable {
      bins read = {1};
      bins notRead = {0};
    }
    DataIn : coverpoint uin_hdlc.DataIn {
      bins DataIn[] = {[0:255]};
    }
    DataOut : coverpoint uin_hdlc.DataOut {
      bins DataIn[] = {[0:255]};
    }
    WriteAddress : cross Address, WrEnable {
      ignore_bins Read_only = (binsof(Address.RX_Buff) && binsof(WrEnable.write)) || (binsof(Address.RX_Len) && binsof(WrEnable.write));
    }

    ReadAddress : cross Address, RdEnable {
      ignore_bins Write_only = (binsof(Address.TX_Buff) && binsof(RdEnable.read));
    }

    Data_In_Address      : cross Address, DataIn;
    Data_Out_Address     : cross Address, DataOut;

  endgroup

   covergroup rx_cover @(posedge uin_hdlc.Clk);
    Rx_ValidFrame : coverpoint uin_hdlc.Rx_ValidFrame { 
      bins valid = {1};
      bins Invalid = {0};
    }
    
    Rx_Data : coverpoint uin_hdlc.Rx_Data {
      bins range[3] = {[255:0]};
    }
    Rx_AbortSignal : coverpoint uin_hdlc.Rx_AbortSignal {
      bins abort = {1};
      bins notAbort = {0};
    } 

    Rx_Ready : coverpoint uin_hdlc.Rx_Ready {
      bins ready = {1};
      bins busy = {0};
    } 
    
    Rx_EoF : coverpoint uin_hdlc.Rx_EoF {
      bins frameEnd = {1};
      bins other = default;
    } 

    Rx_FrameSize : coverpoint uin_hdlc.Rx_FrameSize {
      bins  RxFrameSize[] = {[0:126]};
      ignore_bins Invalid = {[127:255]};
    }
    Rx_Overflow : coverpoint uin_hdlc.Rx_Overflow {
      bins overflow = {1};
      bins normal = {0};
    } 

    Rx_FCSerr : coverpoint uin_hdlc.Rx_FCSerr {
      bins errors = {1};
      bins normal = {0};
    }
    
    Rx_NewByte : coverpoint uin_hdlc.Rx_NewByte {
      bins newByte = {1};
      bins other = default;
    } 
    
    Rx_AbortDetect : coverpoint uin_hdlc.Rx_AbortDetect {
      bins aborted = {1};
      bins normal = {0};
    } 

    Rx_FrameError : coverpoint uin_hdlc.Rx_FrameError {
      bins error = {1};
      bins normal = {0};
    } 

    Rx_Drop : coverpoint uin_hdlc.Rx_Drop;
   
  endgroup

  covergroup tx_cover @(posedge uin_hdlc.Clk);
  
    
    Tx_ValidFrame : coverpoint uin_hdlc.Tx_ValidFrame {
      bins valid = {1};
      bins Invalid = {0};
    } 

    Tx_Data : coverpoint uin_hdlc.Tx_Data {
    bins TxData[] = {[0:255]};
    }

    Tx_AbortedTrans : coverpoint uin_hdlc.Tx_AbortedTrans {
      bins abort = {1};
      bins notAbort = {0};
    } 

    Tx_FrameSize : coverpoint uin_hdlc.Tx_FrameSize {
      bins TxFrameSize[] = {[0:126]};
      ignore_bins Invalid = {[127:255]};
    }
    
    Tx_Done : coverpoint uin_hdlc.Tx_Done {
      bins ready = {1};
      bins notReady = {0};
    } 

    Tx_Full : coverpoint uin_hdlc.Tx_Full {
      bins overflow = {1};
      bins normal = {0};
    } 

  endgroup


  reg_cover   reg_cover_inst = new();
  rx_cover     rx_cover_inst = new();
  tx_cover     tx_cover_inst = new();
 


  // VerifyAbortReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer is zero after abort.
  // Specification 2,1
  task VerifyAbortReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    
  //Read data in RX status/ control register (Rx_SC), address = 0x2
   ReadAddress(3'b010,ReadData);
  
  //Check that RX buffer has no data to be read 
    assert ( ReadData[0] != 1'b1) $display("PASS: VerifyAbortReceive:: Rx_Buff has no data");
    else begin
      $error("FAIL: VerifyAbortReceive:: Rx_Buff has data");
      TbErrorCnt++;
    end

  //Check that there is no error in received RX frame
    assert ( ReadData[2] != 1'b1) $display("PASS: VerifyAbortReceive:: No Frame Error");
    else begin
      $error("FAIL: VerifyAbortReceive:: Frame Error");
      TbErrorCnt++;
    end
  //Check that RX frame was aborted (that abort signal is asserted)
     assert ( ReadData[3] == 1'b1) $display("PASS: VerifyAbortReceive:: Abort Signal Asserted");
    else begin
      $error("FAIL: VerifyAbortReceive:: Value in RX_SC is not an abort signal");
      TbErrorCnt++;
    end
  // Check that RX buffer has not overflown
    assert ( ReadData[4] != 1'b1) $display("PASS: VerifyAbortReceive:: No Overflow Signal");
    else begin
      $error("FAIL: VerifyAbortReceive:: Overflow Signal");
      TbErrorCnt++;
    end
  // Check that Rx Data Buffer is empty (after abort signal is asserted)
    ReadAddress(3'b011,ReadData);
    assert(ReadData == 8'b0) $display("PASS: VerifyAbortReceive:: Rx Data Buffer is empty");
    else begin
      $error("FAIL: VerifyAbortReceive:: Rx Data Buffer is not Empty!");
      TbErrorCnt++;
    end


  endtask

  // VerifyNormalReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  task VerifyNormalReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    logic [7:0] datalength;

    wait(uin_hdlc.Rx_Ready);

    //Read data in RX status/ control register (Rx_SC), address = 0x2
   	ReadAddress(3'b010, ReadData);

    //Check that RX buffer has some data to be read 
    assert (ReadData[0] == 1'b1) $display("PASS: VerifyNormalReceive:: Rx_Buff has data to read");
    else begin 
      $error("FAIL: VerifyNormalReceive:: Rx_Buff has NO data to read!");
      TbErrorCnt++;
    end
    
    // Read data in Frame length register (Rx_Len)
    ReadAddress(3'b100,datalength);

    // Verify that data has same size as frame length register : Check that there is no frame error
    assert(datalength == Size) $display("PASS: VerifyNormalReceive:: No Frame error");
    else begin
      $error("FAIL: VerifyNormalReceive :: Frame error!");
      TbErrorCnt++;
    end

    //Check that RX frame was not aborted (that abort signal is not asserted)
    assert (ReadData[3] != 1'b1) $display("PASS: VerifyNormalReceive:: No Abort Signal");
    else begin 
      $error("FAIL: VerifyNormalReceive:: Abort Signal Detected!");
      TbErrorCnt++;
    end

    // Check that RX buffer has not overflown
    assert (ReadData[4] != 1'b1) $display("PASS: VerifyNormalReceive:: No Overflow Signal");
    else begin 
      $error("FAIL: VerifyNormalReceive:: Overflow Signal Detected!");
      TbErrorCnt++;
    end

    // For incoming data check that receive buffer has correct data
    for(int i= 0; i < Size; i++ )
    begin  
    // Reaad data in RX data buffer
    ReadAddress (3'b011,ReadData);
    assert(ReadData == data[i]) $display("PASS: VerifyNormalReceive:: Rx_Buff has correct data");
    else begin 
      $error("FAIL: VerifyNormalReceive :: Rx_Buff has not got correct data!");
      TbErrorCnt++;
    end
    end

      //Specification 14: Rx_FrameSize should equal the number of bytes received in a frame 
      //(max. 126 bytes =128bytes in buffer – 2 FCS bytes)
    ReadAddress(3'b100, ReadData);

    assert (ReadData == Size)
      $display("PASS: Rx_FrameSize equals number of bytes in frame");
    else begin
      $display("ERROR: Rx_FrameSize is not equal to number of bytes in frame!");
      TbErrorCnt++;
    end
  endtask

  // VerifyNormalReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  task VerifyOverflowReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
	  logic [7:0] datalength;
    wait(uin_hdlc.Rx_Ready);

   //Read data in RX status/ control register (Rx_SC), address = 0x2
    ReadAddress(3'b010, ReadData);

    //Check that RX buffer has some data to be read 
    assert (ReadData[0] == 1'b1) $display("PASS: VerifyOverflowReceive:: Rx_Buff has data to read");
    else begin 
      $error("FAIL: VerifyOverflowReceive:: Rx_Buff has NO data to read!");
      TbErrorCnt++;
    end

    // Read data in Frame length register (Rx_Len)
     ReadAddress(3'b100,datalength);
    assert(datalength == Size) $display("PASS: VerifyOverflowReceive :: No Frame Error");
    else begin
      $error("FAIL: VerifyOverflowReceive :: Frame Error");
      TbErrorCnt++;
    end
    
    //Check that RX frame was not aborted (that abort signal is not asserted)
    assert (ReadData[3] != 1'b1) $display("PASS: VerifyOverflowReceive :: No Abort Signal");
    else begin 
      $error("FAIL: VerifyOverflowReceive:: Abort Signal Detected!");
      TbErrorCnt++;
    end

    // Check that RX buffer has  overflown
    assert (ReadData[4] == 1'b1) $display("PASS: VerifyOverflowReceive :: Overflow Signal Asserted");
    else begin
      $error("FAIL: VerifyOverflowReceive :: Overflow Signal NOT Asserted");
      TbErrorCnt++;
    end

  endtask

  // Attempting to read RX Buffer after frame error should result in zeros
  // Specification 16
  task VerifyFrameError(logic [127:0][7:0] data, int Size);
	logic [7:0] ReadData;

  //Read data in RX status/ control register (Rx_SC), address = 0x2	
	ReadAddress(3'b010, ReadData);
	
  // Check that Frame error signal is asserted - Error in received RX frame
	assert(ReadData[2] == 1'b1 ) $display("PASS: VerifyFrameError::FrameError Detected");
	else begin 
		$error ("FAIL: VerifyFrameError::FrameError Detection Failed!");
    TbErrorCnt++;
	end   

  // Reaad data in RX data buffer and check that it is empty - filled with zeros
	ReadAddress(3'b011,ReadData);
	assert (ReadData == 8'b0) $display("PASS: VerifyFrameError :: Rx Buffer Empty After FrameError");
	else begin
	  $error("FAIL: VerifyFrameError :: Rx Buffer not empty after FrameError");
    TbErrorCnt++;
	end
  endtask

 // Attempting to read RX Buffer after dropped frame should result in zeros
 // Specification 2,3
  task VerifyDroppedFrame(logic [127:0][7:0] data, int Size);
        logic [7:0] ReadData;
        
        // Write to Rx_Drop bit in RX status/ control register (Rx_SC), address = 0x2  
        WriteAddress(3'b010, 8'b00000010);

            // Read  the data buffer and check that it is empty
            ReadAddress(3'b011,ReadData);
        assert (ReadData == 8'b0) $display("PASS: VerifyDroppedFrame :: Rx Buffer Empty After FrameDrop");
        else begin
          $error("FAIL: VerifyDroppedFrame :: Rx Buffer not empty after FrameDrop");
          TbErrorCnt++;
	end
  endtask


// Specification 18: Tx_Full should be asserted after writing 126 or more bytes to the TX buffer (overflow).
task VerifyOverflowTransmit( int Size);
    logic [7:0] ReadData;
// Read the TX status/ control register (Tx_SC), address = 0x0
    ReadAddress(3'h0, ReadData);

// Check that Tx_Full should be asserted after writing 126 or more bytes to the TX buffer (overflow).
    if (Size >= 126) begin
    assert(ReadData[4] == 1'b1)
      $display("PASS: VerifyOverflowTransmit:: TX_Full flag asserted");
    else begin
      $display("FAIL: VerifyOverflowTransmit:: TX_Full flag not asserted");
      TbErrorCnt++;
    end
    end
  endtask
  

  task VerifyAbortTransmit (logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    
  //Read data in TX status/ control register (Rx_SC), address = 0x2

  for(int i = 0; i < 2; i++) begin
      ReadAddress(3'h0, ReadData);
      if (ReadData & (1 << 3))
        break;
    end
    
  //Check that RX frame was aborted (that abort signal is asserted)
     assert ( ReadData[3] == 1'b1) $display("PASS: VerifyAbortTransmit:: Tx_AbortedTrans Asserted");
    else begin
      $error("FAIL: VerifyAbortTransmit:: Tx_AbortedTrans not asserted");
      TbErrorCnt++;
    end

  endtask

// Specification 4
  task VerifyNormalTransmit (logic [127:0][7:0] data, int Size);
    
  for (int i = 0; i < Size - 1; i++)
     begin
        wait(uin_hdlc.Tx_RdBuff);
       assert( data[i] == uin_hdlc.Tx_DataOutBuff)       
      $display("PASS: VerifyNoramlTransmit:: TX_Buff has correct data");
    else begin
      $display("FAIL: VerifyNoramlTransmit:: TX_Buff data incorrect!");
      TbErrorCnt++;
    end
       @(posedge uin_hdlc.Clk);
      
     end

  endtask
  /****************************************************************************
   *                                                                          *
   *                             Simulation code                              *
   *                                                                          *
   ****************************************************************************/

  initial begin
    $display("*************************************************************");
    $display("%t - Starting Test Program", $time);
    $display("*************************************************************");

    Init();

    //Receive: Size, Abort, FCSerr, NonByteAligned, Overflow, Drop, SkipRead
    Receive( 10, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 40, 1, 0, 0, 0, 0, 0); //Abort
    Receive(126, 0, 0, 0, 1, 0, 0); //Overflow
    Receive( 45, 0, 0, 0, 0, 0, 0); //Normal
    Receive(126, 0, 0, 0, 0, 0, 0); //Normal
    Receive(122, 1, 0, 0, 0, 0, 0); //Abort
    Receive(126, 0, 0, 0, 1, 0, 0); //Overflow
    Receive( 25, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 47, 0, 0, 0, 0, 0, 0); //Normal
    // Receive( 11, 0, 0, 0, 0, 0, 1); //SkipRead
    Receive( 50, 0, 0, 0, 0, 1, 0); //Drop
    Receive( 78, 0, 1, 0, 0, 0, 0); //FCSerr
    Receive( 78, 0, 0, 1, 0, 0, 0); //NonByteAligned

//Transmit: Size, Abort, Overflow
    Transmit( 40,0,0); //Normal
    Transmit(127,0,1); //Overflow
    Transmit( 14,0,0); //Normal
    Transmit( 20,1,0); //Abort

    $display("*************************************************************");
    $display("%t - Finishing Test Program", $time);
    $display("*************************************************************");
    $stop;
  end

  final begin

    $display("*********************************");
    $display("*                               *");
    $display("* \tAssertion Errors: %0d\t  *", TbErrorCnt + uin_hdlc.ErrCntAssertions);
    $display("*                               *");
    $display("*********************************");

  end

  task Init();
    uin_hdlc.Clk         =   1'b0;
    uin_hdlc.Rst         =   1'b0;
    uin_hdlc.Address     = 3'b000;
    uin_hdlc.WriteEnable =   1'b0;
    uin_hdlc.ReadEnable  =   1'b0;
    uin_hdlc.DataIn      =     '0;
    uin_hdlc.TxEN        =   1'b1;
    uin_hdlc.Rx          =   1'b1;
    uin_hdlc.RxEN        =   1'b1;

    TbErrorCnt = 0;

    #1000ns;
    uin_hdlc.Rst         =   1'b1;
  endtask

  task WriteAddress(input logic [2:0] Address ,input logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address     = Address;
    uin_hdlc.WriteEnable = 1'b1;
    uin_hdlc.DataIn      = Data;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.WriteEnable = 1'b0;
  endtask

  task ReadAddress(input logic [2:0] Address ,output logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address    = Address;
    uin_hdlc.ReadEnable = 1'b1;
    #100ns;
    Data                = uin_hdlc.DataOut;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.ReadEnable = 1'b0;
  endtask

  task InsertFlagOrAbort(flag);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b0;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    if(flag)
      uin_hdlc.Rx = 1'b0;
    else
      uin_hdlc.Rx = 1'b1;
  endtask


task Transmit(int Size, int Abort, int Overflow);
     logic [127:0][7:0] TransmitData;
     logic       [15:0] FCSBytes;
     logic     [7:0] ReadData;
     string msg;

     if(Abort)
       msg = "- Abort";
     else if(Overflow)
       msg = "- Overflow";
     else
       msg = "- Normal";

     $display("*************************************************************");
     $display("%t - Starting task Transmit %s", $time, msg);
     $display("*************************************************************");

     for (int i = 0; i < Size; i++) begin
       TransmitData[i] = $urandom;
     end

     TransmitData[Size]   = '0;
     TransmitData[Size+1] = '0;

     GenerateFCSBytes(TransmitData, Size, FCSBytes);

    TransmitData[Size]   = FCSBytes[7:0];
    TransmitData[Size+1] = FCSBytes[15:8];

     
	  for (int i = 0; i < Size; i++) begin

		WriteAddress(3'b001, TransmitData[i]);
     end

    WriteAddress(3'b000, 8'h02);

    VerifyOverflowTransmit ( Size);

   if (Abort) begin
     @(posedge uin_hdlc.Clk);
      WriteAddress(3'b000, 8'h04);
      
   end

    if (Abort) 
    VerifyAbortTransmit (TransmitData, Size);
    else if (!Overflow)
     
     VerifyNormalTransmit ( TransmitData, Size);
     
    

// Specification 17: Tx_Done should be asserted when the entire TX buffer has been read for transmission.

     wait(uin_hdlc.Tx_Done);
     ReadAddress(3'h0, ReadData);

    assert(ReadData[0] == 1'b1)
      $display("PASS: TX_Done flag asserted");
    else begin
      $display("FAIL: TX_Done flag not asserted");
      TbErrorCnt++;
    end

//#500ns;
 endtask


  
  task MakeRxStimulus(logic [127:0][7:0] Data, int Size);
    logic [4:0] PrevData;
    PrevData = '0;
    for (int i = 0; i < Size; i++) begin
      for (int j = 0; j < 8; j++) begin
        if(&PrevData) begin
          @(posedge uin_hdlc.Clk);
          uin_hdlc.Rx = 1'b0;
          PrevData = PrevData >> 1;
          PrevData[4] = 1'b0;
        end

        @(posedge uin_hdlc.Clk);
        uin_hdlc.Rx = Data[i][j];

        PrevData = PrevData >> 1;
        PrevData[4] = Data[i][j];
      end
    end
  endtask


  task Receive(int Size, int Abort, int FCSerr, int NonByteAligned, int Overflow, int Drop, int SkipRead);
    logic [127:0][7:0] ReceiveData;
    logic       [15:0] FCSBytes;
    logic   [2:0][7:0] OverflowData;
    string msg;
  
    if(Abort)
      msg = "- Abort";
    else if(FCSerr)
      msg = "- FCS error";
    else if(NonByteAligned)
      msg = "- Non-byte aligned";
    else if(Overflow)
      msg = "- Overflow";
    else if(Drop)
      msg = "- Drop";
    else if(SkipRead)
      msg = "- Skip read";
    else
      msg = "- Normal";
    $display("*************************************************************");
    $display("%t - Starting task Receive %s", $time, msg);
    $display("*************************************************************");

    for (int i = 0; i < Size; i++) begin
      ReceiveData[i] = $urandom;
    end
    ReceiveData[Size]   = '0;
    ReceiveData[Size+1] = '0;

    //Calculate FCS bits;

    GenerateFCSBytes(ReceiveData, Size, FCSBytes);
    ReceiveData[Size]   = FCSBytes[7:0];
    ReceiveData[Size+1] = FCSBytes[15:8];

    if (FCSerr) begin

    ReceiveData[Size]   = 8'h2F;
    ReceiveData[Size+1] = 8'h99;

    end

    //Enable FCS
    if(!Overflow && !NonByteAligned)
      WriteAddress(3'b010, 8'h20);
    else
      WriteAddress(3'b010, 8'h00);

    //Generate stimulus
    InsertFlagOrAbort(1);
    
    MakeRxStimulus(ReceiveData, Size + 2);

    if (NonByteAligned) begin
            @(posedge uin_hdlc.Clk);
                uin_hdlc.Rx = 1'b1;
            @(posedge uin_hdlc.Clk);
                uin_hdlc.Rx = 1'b0;
        end
  
    if(Overflow) begin
      OverflowData[0] = 8'h44;
      OverflowData[1] = 8'hBB;
      OverflowData[2] = 8'hCC;
      MakeRxStimulus(OverflowData, 3);
    end

    if(Abort ) begin
      InsertFlagOrAbort(0);
    end else begin
      InsertFlagOrAbort(1);
    end

    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;

    repeat(8)
      @(posedge uin_hdlc.Clk);
    if(Abort)
      VerifyAbortReceive(ReceiveData, Size);
    else if(Overflow)
      VerifyOverflowReceive(ReceiveData, Size);
    else if(Drop)
      VerifyDroppedFrame(ReceiveData, Size);
    else if(FCSerr || NonByteAligned)
       VerifyFrameError(ReceiveData, Size); 
    else if(!SkipRead)
      VerifyNormalReceive(ReceiveData, Size);
    #5000ns;
  endtask

  task GenerateFCSBytes(logic [127:0][7:0] data, int size, output logic[15:0] FCSBytes);
    logic [23:0] CheckReg;
    CheckReg[15:8]  = data[1];
    CheckReg[7:0]   = data[0];
    for(int i = 2; i < size+2; i++) begin
      CheckReg[23:16] = data[i];
      for(int j = 0; j < 8; j++) begin
        if(CheckReg[0]) begin
          CheckReg[0]    = CheckReg[0] ^ 1;
          CheckReg[1]    = CheckReg[1] ^ 1;
          CheckReg[13:2] = CheckReg[13:2];
          CheckReg[14]   = CheckReg[14] ^ 1;
          CheckReg[15]   = CheckReg[15];
          CheckReg[16]   = CheckReg[16] ^1;
        end
        CheckReg = CheckReg >> 1;
      end
    end
    FCSBytes = CheckReg;
  endtask

endprogram

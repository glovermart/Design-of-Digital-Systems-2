//////////////////////////////////////////////////
// Title:   assertions_hdlc
// Author:  
// Date:    
//////////////////////////////////////////////////

/* The assertions_hdlc module is a test module containing the concurrent
   assertions. It is used by binding the signals of assertions_hdlc to the
   corresponding signals in the test_hdlc testbench. This is already done in
   bind_hdlc.sv 

   For this exercise you will write concurrent assertions for the Rx module:
   - Verify that Rx_FlagDetect is asserted two cycles after a flag is received
   - Verify that Rx_AbortSignal is asserted after receiving an abort flag
*/

module assertions_hdlc (
  output int           ErrCntAssertions,

  input  logic  [2:0]  Address,
  input  logic         WriteEnable,
  input  logic         ReadEnable,
  input  logic  [7:0]  DataIn,
  input  logic  [7:0]  DataOut,

  input  logic         Clk,
  input  logic         Rst,
  input  logic         Rx,
  input  logic         Rx_FlagDetect,
  input  logic         Rx_ValidFrame,
  input  logic         Rx_AbortDetect,
  input  logic         Rx_AbortSignal,
  input  logic         Rx_Overflow,
  input  logic         Rx_WrBuff,
  input  logic         Rx_EoF,
  input  logic         Rx_StartZeroDetect,
  input  logic         Rx_FrameError,
  input  logic         Rx_StartFCS,
  input  logic         Rx_StopFCS,
  input  logic [7:0]   Rx_Data,
  input  logic         Rx_NewByte,
  input  logic         RxD,
  input  logic         Rx_FCSerr,
  input  logic         Rx_Ready,
  input  logic [7:0]   Rx_FrameSize,
  input  logic [7:0]   Rx_DataBuffOut,
  input  logic         Rx_FCSen,
  input  logic         Rx_RdBuff,
  input  logic         Rx_Drop,
  input  logic               Tx_ValidFrame,
  input  logic               Tx_AbortedTrans,
  input  logic               Tx_WriteFCS,
  input  logic               Tx_InitZero,
  input  logic               Tx_StartFCS,
  input  logic               Tx_RdBuff,
  input  logic               Tx_NewByte,
  input  logic               Tx_FCSDone,
  input  logic [7:0]         Tx_Data,
  input  logic               Tx_Done,
  input  logic               Tx_Full,
  input  logic               Tx_DataAvail,
  input  logic [7:0]         Tx_FrameSize,
  input  logic [127:0][7:0]  Tx_DataArray,
  input  logic [7:0]         Tx_DataOutBuff,
  input  logic               Tx_WrBuff,
  input  logic               Tx_Enable,
  input  logic [7:0]         Tx_DataInBuff,
  input  logic               Tx_AbortFrame,

  input  logic               Tx,
  input  logic               TxEN

);

  initial begin
    ErrCntAssertions  =  0;
  end

  /*******************************************
   *  SEQUENCES  *
   *******************************************/
sequence Rx_flag;
    Rx == 0 ##1 Rx[*6] ##1 Rx == 0;
endsequence

sequence StartEndFrameFlag;
	Tx == 0 ##1 Tx [*6] ##1 Tx == 0;
endsequence

sequence IdlePatternGenerationAndChecking;
        Tx[*8];
endsequence

sequence AbortPatternGenerationAndChecking;
	Rx == 0 ##1 Rx [*7]; 
endsequence

sequence abort_pattern;
        Tx == 0 ##1 Tx [*7];
endsequence
/*
sequence;

endsequence
*/

  /*******************************************
   *  PROPERTIES  *
   *******************************************/
  // Check if flag sequence is detected
property RX_FlagDetect;
        @(posedge Clk) Rx_flag |-> ##2 Rx_FlagDetect;
endproperty

  //If abort is detected during valid frame. then abort signal should go high
property RX_AbortSignal;
        @(posedge Clk)  Rx_AbortDetect && Rx_ValidFrame |=> Rx_AbortSignal;
endproperty


//Specification 5
property StartEndPatternGenerator;
	@(posedge Clk) disable iff (!Rst) !$stable(Tx_ValidFrame) ##0 !Tx_AbortedTrans |-> ##[1:2] StartEndFrameFlag;   // Error  // probs from no stimuli to detect from task transmit
endproperty

/*
//Specification 6
property InsertZeros;
	@(posedge Clk) disable iff (!Rst) 
endproperty

property RemoveZeros;
	@(posedge Clk) disable iff (!Rst)
endproperty
*/

//Specification 7
property Idle_Pattern_Generator_And_Checker;
	@(posedge Clk) disable iff (!Rst) !Tx_ValidFrame && Tx_FrameSize == 8'b0 |-> IdlePatternGenerationAndChecking;
endproperty

//Specification 8
property AbortPatternGeneratorAndCheckerRX;
	@(posedge Clk) disable iff (!Rst) AbortPatternGenerationAndChecking ##0 Rx_ValidFrame |-> ##2 Rx_AbortDetect;
endproperty

property AbortPatternGeneratorAndCheckerTX;
       // @(posedge Clk) disable iff (!Rst) abort_pattern ##0 Tx_ValidFrame  |=> Tx_AbortFrame;
	@(posedge Clk) disable iff (!Rst)  $rose(Tx_AbortedTrans) |-> ##2 abort_pattern;
endproperty

//Specification 10
property GenerateRx_AbortSignal;
	@(posedge Clk) disable iff (!Rst) Rx_ValidFrame && Rx_AbortDetect |=> Rx_AbortSignal;
endproperty

//Specification 12
property EndOfFrameDetected;
	@(posedge Clk) disable iff (!Rst) $fell(Rx_ValidFrame) |=> Rx_EoF;
endproperty

//Specification 13
property Rx_OverflowAt129Byte;
	@(posedge Clk) disable iff (!Rst|| !Rx_ValidFrame)( $rose(Rx_ValidFrame)) ##0 ($rose(Rx_NewByte)[->129]) |=>$rose(Rx_Overflow);
endproperty

//Specification 15
property RxBufferReadyToBeRead;
	@(posedge Clk) disable iff (!Rst) $rose(Rx_Ready) |-> $rose(Rx_EoF) and !Rx_ValidFrame;
endproperty

/* //Specification 16
property FCSCheckResultFrameError;
	@(posedge Clk) disable iff (!Rst) $rose(Rx_FCSerr) &&  Rx_FCSen |=> $rose(Rx_FrameError);
endproperty */

//Specification 17
property TxDoneAssert;
	@(posedge Clk) disable iff (!Rst) $fell(Tx_DataAvail) |=> $past(Tx_Done);
endproperty

//Specification 18
property TxFullAssertAfter126Bytes;
	@(posedge Clk) disable iff (!Rst) Tx_FrameSize == 8'b01111110 |=> Tx_Full;  
endproperty

  /*******************************************
   *  ASSERTIONS  *
   *******************************************/
RX_FlagDetect_Assert : assert property (RX_FlagDetect) begin
    $display("PASS: Flag detect");
end else begin
    $error("Flag sequence did not generate FlagDetect");
    ErrCntAssertions++;
end

RX_AbortSignal_Assert : assert property (RX_AbortSignal) begin
    $display("PASS: Abort signal");
end else begin
    $error("AbortSignal did not go high after AbortDetect during validframe");
    ErrCntAssertions++;
end


// Specification_5_Assert: assert property (StartEndPatternGenerator) begin 
//     $display("PASS:Start and End Frame Genereated");
// end else begin
//     $error("FAIL: Start and End Frame was not Generated");
//     ErrCntAssertions++;
// end


// Specification_6_Assert_ZeroInsert: assert property (InsertZeros) begin $display("PASS:Zeros Inserted!");
// 	end else begin $error("FAIL:Zeros were not inserted!!"); 
// 	ErrCntAssertions++;end

// Specification_6_Assert_ZeroRemove: assert property (RemoveZeros) begin  $display("PASS:Zeros Removed!");
//         end else begin $error("FAIL:Zeros were not removed!!");
//         ErrCntAssertions++;end


// Specification_7_Assert: assert property (Idle_Pattern_Generator_And_Checker) begin           //Repeats too much :check why!
//     $display("PASS:RX Logic in IDLE state");
// end else begin
//     $error("FAIL: Idle pattern was not detected!");
//     ErrCntAssertions++;
// end

Specification_8_Assert_RX: assert property (AbortPatternGeneratorAndCheckerRX) begin  $display("PASS: RX Abort Pattern Detected");                
        end else begin $error("FAIL:RX Abort Pattern NoT Detected!");
	ErrCntAssertions++;end

//  Specification_8_Assert_TX: assert property (AbortPatternGeneratorAndCheckerTX) begin $display("PASS:TX Abort Pattern Detected");           //stimuli not generated? it's not firing!
//         end else begin $error("FAIL: TX Abort Pattern NoT Detected!");
//          ErrCntAssertions++;end 

Specification_10_Assert:  assert property (GenerateRx_AbortSignal) begin $display("PASS:Rx_Frame was Aborted");
        end else begin $error("FAIL:Rx_Abort Signal not asserted! ");
        ErrCntAssertions++;end

// Specification_11_Assert: assert property () begin $display("PASS:");     // Must this be immediate assertion instead?
//         end else begin $error("FAIL:");
//         ErrCntAssertions++;end

Specification_12_Assert: assert property (EndOfFrameDetected) begin  $display("PASS: Whole Rx Frame has been received- EoF!");             
        end else begin $error("FAIL:Rx_EoF not generated!");
        ErrCntAssertions++;end

Specification_13_Assert: assert property (Rx_OverflowAt129Byte) begin  $display("PASS:RX buffer is full:More than 128 bytes!");           
        end else begin $error("FAIL:RX Overflow was not asserted");
        ErrCntAssertions++;end 

// Specification_14_Assert: assert property () begin $display("PASS:");
//         end else begin $error("FAIL:");
//         ErrCntAssertions++;end

Specification_15_Assert:  assert property (RxBufferReadyToBeRead) begin  $display("PASS:Data is READY in RX Buffer!");                       
        end else begin $error("FAIL:Rx_Ready has not been asserted!");                                                                
        ErrCntAssertions++;end


endmodule

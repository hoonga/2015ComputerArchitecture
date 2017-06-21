import ProcTypes::*;
import Proc::*;
import Types::*;

typedef enum{Start, Run} TestState deriving (Bits, Eq);

(*synthesize*)

module mkTestBench();
  Proc proc <- mkProc;

  Reg#(Bit#(32))     cycle  <- mkReg(0);
  Reg#(TestState)    tState <- mkReg(Start);

  //Initialize the PC and make it run
  rule start(tState == Start);
    proc.hostToCpu(32'h0000); // start address
    tState <= Run;
  endrule

  rule countCycle(tState == Run);
    cycle <= cycle + 1;
    $display("\ncycle %d", cycle);
  endrule

  rule run(tState == Run);
    match {.idx, .data, .numInst} <- proc.cpuToHost;
	match {.reqCnt, .missCnt} <- proc.getCounts;
    if(idx == 12)
      $fwrite(stderr, "%d", data);
    else if (idx == 13) 
      $fwrite(stderr, "%c", data);
    else if(idx == 14)
    begin
	  $fwrite(stderr, "===========================\n");

  	  if(data == 0)
        $fwrite(stderr, "Result                :     PASSED\n");
      else
        $fwrite(stderr, "Result                :     FAILED %d\n", data);
	
	  $fwrite(stderr, "Number of Cycles      : %d\n", cycle);
	  $fwrite(stderr, "Executed Instructions : %d\n", numInst);
	  $fwrite(stderr, "Cache Req Count       : %d\n", reqCnt);
	  $fwrite(stderr, "Cache Miss Count      : %d\n", missCnt);
	  $fwrite(stderr, "===========================\n");

      $finish;
    end
  endrule
endmodule

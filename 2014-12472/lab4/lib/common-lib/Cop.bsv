/*

Copyright (C) 2012 Muralidaran Vijayaraghavan <vmurali@csail.mit.edu>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/


import Types::*;
import ProcTypes::*;
import ConfigReg::*;
import Fifo::*;


typedef enum {Ctr, Mem} InstCntType deriving(Bits, Eq);

interface Cop;
  method Action start;
  method Bool started;
  method Data rd(RIndx idx);
  method Action wr(Maybe#(FullIndx) idx, Data val);
  method Action incInstTypeCnt(InstCntType idx);
  method Action incBPMissCnt();

  method ActionValue#(Tuple3#(RIndx, Data, Data)) cpuToHost;
endinterface

(* synthesize *)
module mkCop(Cop);
  Reg#(Bool) startReg <- mkConfigReg(False);
  Reg#(Data) numInsts <- mkConfigReg(0);
  Reg#(Data) timeReg <- mkConfigReg(?);
  Reg#(Bool) finishReg <- mkConfigReg(False);
  Reg#(Data) finishCode <- mkConfigReg(0);

  Reg#(Data) numCtr  <- mkConfigReg(0);
  Reg#(Data) numMem  <- mkConfigReg(0);
  Reg#(Data) numBPMiss <- mkConfigReg(0);

  Fifo#(2, Tuple3#(RIndx, Data, Data)) copFifo <- mkCFFifo;

  Reg#(Data) cycles <- mkReg(0);

  rule count;
     cycles <= cycles + 1;
     $display("\nCycle %d ----------------------------------------------------", cycles);
  endrule

  method Action start;
    startReg <= True;
  endmethod

  method Bool started;
    return startReg;
  endmethod

  method Data rd(RIndx idx);
    return (case(idx)
      10: cycles;
      11: numInsts;
      14: finishCode;
    endcase);
  endmethod

  /*
    Register 10: (Read only) current time
    Register 11: (Read only) returns current number of instructions
    Register 12: (Write only) Write an integer to stderr
    Register 13: (Write only) Write a char to stderr
    Register 14: Finish code
    Register 22: (Write only) Finished executing
  */
  method Action wr(Maybe#(FullIndx) idx, Data val);
    if(isValid(idx) && validValue(idx).regType == CopReg)
    begin
      case (validRegValue(idx))
        12: copFifo.enq(tuple3(12, val, numInsts+1));
        13: copFifo.enq(tuple3(13, val, numInsts+1));
		14: begin
	  			$fwrite(stderr, "===========================\n");
//				$fwrite(stderr, "Specific type of executed instructions\n");
//				$fwrite(stderr, "Ctr 		      : %d\n", numCtr);
//				$fwrite(stderr, "Mem 		      : %d\n", numMem);
//				$fwrite(stderr, "\nMispredicted	      : %d\n", numBPMiss);
				copFifo.enq(tuple3(14, val, numInsts+1));
			end	

      endcase
    end
    numInsts <= numInsts + 1;
  endmethod

  method Action incInstTypeCnt(InstCntType idx);
	  case(idx)
		  Ctr : numCtr <= numCtr + 1; // call, ret, Jmp
		  Mem : numMem <= numMem + 1; // rmmovl, mrmovl, Push, Pop
	  endcase
  endmethod

  method Action incBPMissCnt();
	  numBPMiss <= numBPMiss + 1;
  endmethod

  method ActionValue#(Tuple3#(RIndx, Data, Data)) cpuToHost;
    copFifo.deq;
    return copFifo.first;
  endmethod
endmodule

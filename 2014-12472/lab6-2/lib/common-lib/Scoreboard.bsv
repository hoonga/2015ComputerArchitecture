/*

Copyright (C) 2012 Muralidaran Vijayaraghavan <vmurali@csail.mit.edu>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/


import Fifo::*;
import ProcTypes::*;

interface Scoreboard#(numeric type size);
	method Action insertE(Maybe#(FullIndx) rIndx);
	method Action insertM(Maybe#(FullIndx) rIndx);
	
	method Bool search1(Maybe#(FullIndx) rIndx);
	method Bool search2(Maybe#(FullIndx) rIndx);
	method Bool search3(Maybe#(FullIndx) rIndx);
	method Bool search4(Maybe#(FullIndx) rIndx);
	
	method Action remove;
endinterface

function Bool isFound(Maybe#(FullIndx) x, Maybe#(FullIndx) k);
	if(x matches tagged Valid .xv &&& k matches tagged Valid .kv &&& kv == xv)
	begin
		return True;
	end
	else
	begin
		return False;
	end
endfunction

module mkPipelineScoreboard(Scoreboard#(size));
	SFifo#(size, Maybe#(FullIndx), Maybe#(FullIndx))  fifoE <- mkPipelineSFifo(isFound);
	SFifo#(size, Maybe#(FullIndx), Maybe#(FullIndx))  fifoM <- mkPipelineSFifo(isFound);

	method Action insertE(Maybe#(FullIndx) rIndx);
	   	fifoE.enq(rIndx);
	endmethod

	method Action insertM(Maybe#(FullIndx) rIndx);
		fifoM.enq(rIndx);
	endmethod
	
	method Bool search1(Maybe#(FullIndx) rIndx); 
		return (fifoE.search(rIndx) || fifoM.search(rIndx));
	endmethod

	method Bool search2(Maybe#(FullIndx) rIndx); 
		return (fifoE.search(rIndx) || fifoM.search(rIndx));
	endmethod
		
	method Bool search3(Maybe#(FullIndx) rIndx); 
		return (fifoE.search(rIndx) || fifoM.search(rIndx));
	endmethod

	method Bool search4(Maybe#(FullIndx) rIndx); 
		return (fifoE.search(rIndx) || fifoM.search(rIndx));
	endmethod

	method Action remove;
		fifoE.deq;
		fifoM.deq;
	endmethod
endmodule

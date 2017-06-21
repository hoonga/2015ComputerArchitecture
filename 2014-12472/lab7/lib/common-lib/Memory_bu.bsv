/*

Copyright (C) 2012 Muralidaran Vijayaraghavan <vmurali@csail.mit.edu>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/



import Types::*;
import MemTypes::*;
import CacheTypes::*;
import RegFile::*;
import Fifo::*;

interface Memory;
	method Action iReq(CacheMemReq r);
	method ActionValue#(MemResp) iResp;
	method Action dReq(CacheMemReq r);
	method ActionValue#(MemResp) dResp;
endinterface

(* synthesize *)
module mkMemory(Memory);
	RegFile#(Bit#(20), Data) mem <- mkRegFileWCFLoad("memory.vmh", 0, maxBound);

	Fifo#(2, CacheMemReq) 	iMemReqQ <- mkCFFifo;
	Fifo#(2, MemResp) 	iMemRespQ <- mkCFFifo;

	Fifo#(2, CacheMemReq) dMemReqQ <- mkCFFifo;
	Fifo#(2, MemResp) dMemRespQ <- mkCFFifo;

	Reg#(Bit#(TLog#(MaxBurstLength))) iMemCnt <- mkReg(0);
	Reg#(Bit#(TLog#(MaxBurstLength))) dMemCnt <- mkReg(0);

	Reg#(MemResp) iMemTempData <- mkRegU;
	Reg#(MemResp) dMemTempData <- mkRegU;

	Reg#(MemStatus) iMemStatus <- mkReg(Idle);
	Reg#(MemStatus) dMemStatus <- mkReg(Idle);

	rule getDResp(dMemStatus == DBusy);
		let req = dMemReqQ.first;
		let idx = truncate((req.addr >> 2) + zeroExtend(dMemCnt));
		let data = mem.sub(idx);
		if(dMemCnt == req.burstLength)
		begin
			dMemCnt <= 0;
			dMemStatus <= Idle;
			dMemReqQ.deq;

			if(req.op == Ld)
			begin
				dMemRespQ.enq(dMemTempData);
			end
		end
		else
		begin
			if(req.op == St)
			begin
				mem.upd(idx, req.data[dMemCnt]);
			end
			else
			begin
				let tempData = dMemTempData;
				tempData[dMemCnt] = data;
				dMemTempData <= tempData;
			end
			dMemCnt <= dMemCnt + 1;
			dMemStatus <= DBusy;
		end
	endrule
/*
	rule getIResp(iMemStatus != Idle);
		let req = iMemReqQ.first;
		let idx = truncate((req.addr >> 2) + zeroExtend(iMemCnt));
		let data = mem.sub(idx);

		if(iMemCnt == req.burstLength)
		begin
			iMemCnt <= 0;
			iMemStatus <= Idle;
			iMemReqQ.deq;
			iMemRespQ.enq(iMemTempData);
		end
		else
		begin
			let tempData = iMemTempData;
			tempData[fromInteger(valueOf(WordsPerBlock))-iMemCnt-1] = data;
			iMemTempData <= tempData;
			iMemCnt <= iMemCnt + 1;
//			iMemStatus <= Busy;
		end
	endrule
*/
	method Action dReq(CacheMemReq r) if (dMemStatus == Idle);
		dMemReqQ.enq(r);
		dMemStatus <= DBusy;
		dMemCnt <= 0;
	endmethod

	method Action iReq(CacheMemReq r) if (iMemStatus == Idle);
		iMemReqQ.enq(r);
		if(dMemStatus == DBusy)
			iMemStatus <= BothBusy;
		else
			iMemStatus <= IBusy;
		iMemCnt <= 0;
	endmethod

	method ActionValue#(MemResp) dResp;
		dMemRespQ.deq;
		return dMemRespQ.first;
	endmethod

	method ActionValue#(MemResp) iResp;
		iMemRespQ.deq;
		return iMemRespQ.first;
	endmethod
endmodule

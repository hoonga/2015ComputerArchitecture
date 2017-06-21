/*

Copyright (C) 2012 Muralidaran Vijayaraghavan <vmurali@csail.mit.edu>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/


import Types::*;
import MemTypes::*;
import CacheTypes::*;
import Fifo::*;
import RegFile::*;
import Vector::*;

interface Cache;
	method Action req(MemReq r);
	method ActionValue#(Data) resp;

  	method ActionValue#(CacheMemReq) memReq;
  	method Action memResp(Line r);
	
	method Data getMissCnt;
	method Data getTotalReq;
endinterface


typedef enum {Ready, StartMiss, SendFillReq, WaitFillResp} CacheStatus deriving (Bits, Eq);

//*
typedef Bit#(TSub#(TSub#(AddrSz, TLog#(CacheRows)),2)) CacheTagS;
module mkCacheDirectMap(Cache);
	RegFile#(CacheIndex, Data) 				dataArray <- mkRegFileFull;
	RegFile#(CacheIndex, Maybe#(CacheTagS))  tagArray <- mkRegFileFull;
	RegFile#(CacheIndex, Bool) 				dirtyArray <- mkRegFileFull;

	Reg#(Bit#(TAdd#(SizeOf#(CacheIndex), 1))) init <- mkReg(0);
	Reg#(CacheStatus) 						  status <- mkReg(Ready);

	Fifo#(1, Data) hitQ <- mkBypassFifo;
	Reg#(MemReq)   missReq <- mkRegU;

	Fifo#(2, CacheMemReq) memReqQ  <- mkCFFifo;
	Fifo#(2, Line) 		  memRespQ <- mkCFFifo;

	Reg#(Data) missCnt <- mkReg(0);
	Reg#(Data) reqCnt <- mkReg(0);

	// Two bits from LSB is always 2'b0 ; because PC has 4-alligned address. So ignore the two bits.
	function CacheIndex getIdx(Addr addr) = truncate(addr >> 2);
	function CacheTagS getTag(Addr addr) = truncateLSB(addr);

	function Addr getBlockAddr(CacheTagS tag, CacheIndex idx);
		Addr addr = {tag, idx, 2'b0};
		return addr;
	endfunction

  	let inited = truncateLSB(init) == 1'b1;

	rule initialize(!inited);
		init <= init + 1;
		tagArray.upd(truncate(init), Invalid);
		dirtyArray.upd(truncate(init), False);
	endrule

	rule startMiss(status == StartMiss);
        let idx = getIdx(missReq.addr);
        let tag = getTag(missReq.addr);
        if(isValid(tagArray.sub(idx))&&dirtyArray.sub(idx))
        begin
            let data = dataArray.sub(idx);
            Line line = newVector;
            line[0] = data;
            memReqQ.enq(CacheMemReq{op:St,addr:getBlockAddr(validValue(tagArray.sub(idx)),idx),data:line,burstLength:1});
        end
        status <= SendFillReq;
	endrule

	rule sendFillReq(status == SendFillReq);
        memReqQ.enq(CacheMemReq{op:Ld,addr:missReq.addr,data:?,burstLength:1});
        status <= WaitFillResp;
	endrule

	rule waitFillResp(status == WaitFillResp && inited);
        memRespQ.deq;
        let data = memRespQ.first;
        let tag = getTag(missReq.addr);
        let idx = getIdx(missReq.addr);
        dataArray.upd(idx,data[0]);
        tagArray.upd(idx,tagged Valid tag);
        dirtyArray.upd(idx,False);
        hitQ.enq(data[0]);
        status <= Ready;
	endrule

	method Action req(MemReq r) if (status == Ready && inited);
        let idx = getIdx(r.addr);
        let tag = getTag(r.addr);
        let cachedTag = tagArray.sub(idx);
        let hit = isValid(cachedTag)?validValue(cachedTag)==tag:False;
        if(r.op==Ld)
        begin
            if(hit)
            begin
                hitQ.enq(dataArray.sub(idx));
            end
            else
            begin
                status <= StartMiss;
                missReq <= r;
            end
        end
        else
        begin
            if(hit)
            begin
                dataArray.upd(idx,r.data);
                dirtyArray.upd(idx, True);
            end
            else
            begin
                Line line = newVector;
                line[0] = r.data;
                memReqQ.enq(CacheMemReq{op:St,addr:r.addr,data:line,burstLength:1});
            end
        end


		if(!hit)
		begin
			missCnt <= missCnt + 1;
		end
		reqCnt <= reqCnt + 1;
	endmethod

	method ActionValue#(Data) resp;
		hitQ.deq;
		return hitQ.first;
	endmethod

	method ActionValue#(CacheMemReq) memReq;
		memReqQ.deq;
		return memReqQ.first;
	endmethod

	method Action memResp(Line r);
		memRespQ.enq(r);
	endmethod

	method Data getMissCnt;
		return missCnt;	
	endmethod

	method Data getTotalReq;
		return reqCnt;	
	endmethod
endmodule
//*/

/*
module mkCacheDirectMap(Cache);
	RegFile#(CacheIndex, Line) 				dataArray <- mkRegFileFull;
	RegFile#(CacheIndex, Maybe#(CacheTag))  tagArray <- mkRegFileFull;
	RegFile#(CacheIndex, Bool) 				dirtyArray <- mkRegFileFull;

	Reg#(Bit#(TAdd#(SizeOf#(CacheIndex), 1))) init <- mkReg(0);
	Reg#(CacheStatus) 						  status <- mkReg(Ready);

	Fifo#(1, Data) hitQ <- mkBypassFifo;
	Reg#(MemReq)   missReq <- mkRegU;

	Fifo#(2, CacheMemReq) memReqQ  <- mkCFFifo;
	Fifo#(2, Line) 		  memRespQ <- mkCFFifo;

	Reg#(Data) missCnt <- mkReg(0);
	Reg#(Data) reqCnt <- mkReg(0);

	// Two bits from LSB is always 2'b0 ; because PC has 4-alligned address. So ignore the two bits.
	function CacheIndex getIdx(Addr addr) = truncate(addr >> (2+fromInteger(valueOf(SizeOf#(CacheBlockOffset)))));
	function CacheTag getTag(Addr addr) = truncateLSB(addr);
	function CacheBlockOffset getOffset(Addr addr) = truncate(addr>>2);

	function Addr getBlockAddr(CacheTag tag, CacheIndex idx);
		CacheBlockOffset def_offset = 0;
		Addr addr = {tag, idx, def_offset, 2'b0};
		return addr;
	endfunction

  	let inited = truncateLSB(init) == 1'b1;

	rule initialize(!inited);
		init <= init + 1;
		tagArray.upd(truncate(init), Invalid);
		dirtyArray.upd(truncate(init), False);
	endrule

	rule startMiss(status == StartMiss);
        let idx = getIdx(missReq.addr);
        if(isValid(tagArray.sub(idx))&&dirtyArray.sub(idx))
        begin
            let addr = getBlockAddr(validValue(tagArray.sub(idx)),idx);
            let data = dataArray.sub(idx);
            memReqQ.enq(CacheMemReq{op:St,addr:addr,data:data,burstLength:fromInteger(valueOf(WordsPerBlock))});
        end
        status <= SendFillReq;
	endrule

	rule sendFillReq(status == SendFillReq);
        let tag = getTag(missReq.addr);
        let idx = getIdx(missReq.addr);
        memReqQ.enq(CacheMemReq{op:Ld,addr:getBlockAddr(tag,idx),data:?,burstLength:fromInteger(valueOf(WordsPerBlock))});
        status <= WaitFillResp;
	endrule

	rule waitFillResp(status == WaitFillResp && inited);
        memRespQ.deq;
        let data = memRespQ.first;
        let tag = getTag(missReq.addr);
        let idx = getIdx(missReq.addr);
        dataArray.upd(idx,data);
        tagArray.upd(idx,tagged Valid tag);
        dirtyArray.upd(idx,False);
        hitQ.enq(data[getOffset(missReq.addr)]);
        status <= Ready;
	endrule

	method Action req(MemReq r) if (status == Ready && inited);
        let idx = getIdx(r.addr);
        let tag = getTag(r.addr);
        let cachedTag = tagArray.sub(idx);
        let hit = isValid(cachedTag)?validValue(cachedTag)==tag:False;
        if(r.op==Ld)
        begin
            if(hit)
            begin
                Line line = dataArray.sub(idx); 
                hitQ.enq(line[getOffset(r.addr)]);
            end
            else
            begin
                status <= StartMiss;
                missReq <= r;
            end
        end
        else
        begin
            if(hit)
            begin
                Line line = dataArray.sub(idx);
                line[getOffset(r.addr)] = r.data;
                dataArray.upd(idx,line);
                dirtyArray.upd(idx, True);
            end
            else
            begin
                Line line = newVector;
                line[0] = r.data;
                memReqQ.enq(CacheMemReq{op:St,addr:r.addr,data:line,burstLength:1});
            end
        end


		if(!hit)
		begin
			missCnt <= missCnt + 1;
		end
		reqCnt <= reqCnt + 1;
	endmethod

	method ActionValue#(Data) resp;
		hitQ.deq;
		return hitQ.first;
	endmethod

	method ActionValue#(CacheMemReq) memReq;
		memReqQ.deq;
		return memReqQ.first;
	endmethod

	method Action memResp(Line r);
		memRespQ.enq(r);
	endmethod

	method Data getMissCnt;
		return missCnt;	
	endmethod

	method Data getTotalReq;
		return reqCnt;	
	endmethod
endmodule
//*/

module mkCacheSetAssociative (Cache);
        
	Vector#(CacheSets, RegFile#(CacheIndex, Line))              dataArray <- replicateM(mkRegFileFull);
	Vector#(CacheSets, RegFile#(CacheIndex, Maybe#(CacheTag)))  tagArray <- replicateM(mkRegFileFull);
	Vector#(CacheSets, RegFile#(CacheIndex, Bool))              dirtyArray <- replicateM(mkRegFileFull);
	RegFile#(CacheIndex, Maybe#(CacheSetOffset)) ruArray <- mkRegFileFull;

	Reg#(Bit#(TAdd#(SizeOf#(CacheIndex), 1))) init <- mkReg(0);
	Reg#(CacheStatus) status <- mkReg(Ready);
	Reg#(Maybe#(CacheSetOffset)) targetSet <- mkReg(Invalid);
	
	Fifo#(1, Data) hitQ <- mkBypassFifo;
	Reg#(MemReq) missReq <- mkRegU;

	Fifo#(2, CacheMemReq) memReqQ <- mkCFFifo;
	Fifo#(2, Line) memRespQ <- mkCFFifo;

	Reg#(Data) missCnt <- mkReg(0);
	Reg#(Data) reqCnt <- mkReg(0);

	function CacheIndex getIdx(Addr addr) = truncate(addr >> (2+fromInteger(valueOf(SizeOf#(CacheBlockOffset)))));
	function CacheTag getTag(Addr addr) = truncateLSB(addr);
	function CacheBlockOffset getOffset(Addr addr) = truncate(addr>>2);

	function Addr getBlockAddr(CacheTag tag, CacheIndex idx);
		CacheBlockOffset def_offset = 0;
		Addr addr = {tag, idx, def_offset, 2'b0};
		return addr;
	endfunction

	function Maybe#(CacheSetOffset) checkHit(CacheTag tag, CacheIndex idx);
	//Determine if cache hit or not using the validity and the value of corresponding cache entries.
		Maybe#(CacheSetOffset) ret = Invalid;

		for(Integer i = 0; i< valueOf(CacheSets); i = i+1)
		begin
			let tagArrayVal = tagArray[i].sub(idx);

			if(isValid(tagArrayVal) && (fromMaybe(?,tagArrayVal) == tag))
			begin
				ret = tagged Valid fromInteger(i);
			end
		end

		return ret;
	endfunction

	function Maybe#(CacheSetOffset) checkInvalid(CacheTag tag, CacheIndex idx);
	//If a set is invalid, return the set number with valid data	
		Maybe#(CacheSetOffset) ret = Invalid;

		for(Integer i = 0; i < valueOf(CacheSets); i = i+1)
		begin
			if(!isValid(tagArray[i].sub(idx)))
			begin
				ret = tagged Valid fromInteger(i);
			end
		end

		return ret;
	endfunction

	function Maybe#(CacheSetOffset) findLRU(CacheTag tag, CacheIndex idx);
	//Approximate LRU Logic. Check the ruArray(Recently Used Array), find a set which is not most recently used(NRU policy).
		Maybe#(CacheSetOffset) ret = tagged Valid fromInteger(0); 

		for(Integer i = 0; i< valueOf(CacheSets); i = i+1)
		begin
			if(fromMaybe(?,ruArray.sub(idx)) == fromInteger(i))
			begin
				ret = tagged Valid fromInteger(i);
			end
		end

		return ret;
	endfunction	

  	let inited = truncateLSB(init) == 1'b1;

	rule initialize(!inited);
		init <= init + 1;

		for(Integer i = 0; i< valueOf(CacheSets);i = i+1)
		begin	
			tagArray[i].upd(truncate(init), Invalid);
			dirtyArray[i].upd(truncate(init), False);
		end

		ruArray.upd(truncate(init), Invalid);
	endrule

	/* Implement rules */

	rule startMiss(status == StartMiss);
		/* Implement here */
        let idx = getIdx(missReq.addr);
        let tag = getTag(missReq.addr);
        let set = checkInvalid(tag,idx);
        if(!isValid(checkInvalid(tag,idx)))
        begin
            set = findLRU(tag,idx);
            if(dirtyArray[validValue(set)].sub(idx))
            begin
                memReqQ.enq(CacheMemReq{op:St, addr:getBlockAddr(validValue(tagArray[validValue(set)].sub(idx)),idx), data:dataArray[validValue(set)].sub(idx),burstLength:fromInteger(valueOf(WordsPerBlock))});
            end
        end
        targetSet <= set;
        status <= SendFillReq;
	endrule

	rule sendFillReq(status == SendFillReq);
		/* Implement here */
        let tag = getTag(missReq.addr);
        let idx = getIdx(missReq.addr);
        memReqQ.enq(CacheMemReq{op:Ld, addr:getBlockAddr(tag,idx), data:?, burstLength:fromInteger(valueOf(WordsPerBlock))});
        status <= WaitFillResp;
	endrule

	rule waitFillResp(status == WaitFillResp && inited);
		/* Implement here */
        memRespQ.deq;
        let data = memRespQ.first;
        let idx = getIdx(missReq.addr);
        let tag = getTag(missReq.addr);
        dataArray[validValue(targetSet)].upd(idx,data);
        tagArray[validValue(targetSet)].upd(idx,tagged Valid tag);
        dirtyArray[validValue(targetSet)].upd(idx,False);
        ruArray.upd(idx,targetSet);
        hitQ.enq(data[getOffset(missReq.addr)]);
        status<=Ready;
	endrule

	method Action req(MemReq r) if (status == Ready && inited);
		/* Implement here */
        let idx = getIdx(r.addr);
        let tag = getTag(r.addr);
        let hit = checkHit(tag,idx);
        if(r.op==Ld)
        begin
            if(isValid(hit))
            begin
                ruArray.upd(idx,hit);
                hitQ.enq(dataArray[validValue(hit)].sub(idx)[getOffset(r.addr)]);
            end
            else
            begin
                missReq <= r;
                status <= StartMiss;
            end
        end
        else
        begin
            if(isValid(hit))
            begin
                ruArray.upd(idx,hit);
                Line line = dataArray[validValue(hit)].sub(idx);
                line[getOffset(r.addr)] = r.data;
                dataArray[validValue(hit)].upd(idx,line);
                dirtyArray[validValue(hit)].upd(idx,True);
            end
            else
            begin
                Line line = newVector;
                line[0] = r.data;
                memReqQ.enq(CacheMemReq{op:St,addr:r.addr,data:line,burstLength:1});
            end
        end
	
		/* Do not modify below here */
		if(!isValid(hit))
		begin
			missCnt <= missCnt + 1;
		end
		reqCnt <= reqCnt + 1;
	endmethod

	method ActionValue#(Data) resp;
		hitQ.deq;
		return hitQ.first;
	endmethod

	method ActionValue#(CacheMemReq) memReq;
		memReqQ.deq;
		return memReqQ.first;
	endmethod

	method Action memResp(Line r);
		memRespQ.enq(r);
	endmethod

	method Data getMissCnt;
		return missCnt;	
	endmethod

	method Data getTotalReq;
		return reqCnt;	
	endmethod
endmodule



module mkCache (Cache);
	
	//Use these two lines to make the cache direct mapped cache
	Cache cacheDirectMap <- mkCacheDirectMap;
	return cacheDirectMap;
	
	//Use these two lines to make the cache Set associative cache

//	Cache cacheSetAssociative <- mkCacheSetAssociative;
//	return cacheSetAssociative;

endmodule

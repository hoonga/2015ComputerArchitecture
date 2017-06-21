import Types::*;
import ProcTypes::*;
import RegFile::*;
import Vector::*;

typedef 64 BtbEntries;
typedef Bit#(TLog#(BtbEntries)) BtbIndex;
typedef Bit#(TSub#(TSub#(AddrSz, TLog#(BtbEntries)),2)) BtbTag;


interface AddrPred;
	method Addr predPc(Addr pc, Bit#(4) iCode);
	method Action update(Redirect rd);
endinterface

function ICode getICode(Inst inst);
	return inst[47:44];
endfunction	

function OpCode getOpCode(Inst inst);
	return inst[47:40];
endfunction

function Addr pcIncrement(Addr pc, Bit#(4) iCode);	
	let offset = case(iCode) 
					halt, nop, ret : 1;
					cmov, opl, push, pop, copinst : 2;
					jmp,call : 5;
					irmovl, rmmovl, mrmovl : 6;
				  endcase;
	return pc + offset;
endfunction

(*synthesize*)
module mkBtb(AddrPred);
  RegFile#(BtbIndex, Addr) ppcArr <- mkRegFileFull;
  RegFile#(BtbIndex, Maybe#(BtbTag)) tagArr <- mkRegFileFull;

  function BtbIndex getIndex(Addr addr) 	= truncate(addr>>2);
  function BtbTag	getTag(Addr addr)	  	= truncateLSB(addr);


  method Addr predPc(Addr pc, Bit#(4) iCode);
  	let idx  	 = getIndex(pc);
	let tag	   	 = getTag(pc);
	let matchTag = tagArr.sub(idx);

	let ret  = ?;
	let valP = pcIncrement(pc, iCode);

	if(isValid(matchTag) && (tag == fromMaybe(?,matchTag)))
		ret = ppcArr.sub(idx);
	else
		ret = valP;

	return ret;
  endmethod

  method Action update(Redirect rd);
  	if(rd.taken)
	begin
		let idx = getIndex(rd.pc);
		let tag = getTag(rd.pc);
		tagArr.upd(idx, Valid(tag));
		ppcArr.upd(idx, rd.nextPc);
	end
  endmethod
endmodule



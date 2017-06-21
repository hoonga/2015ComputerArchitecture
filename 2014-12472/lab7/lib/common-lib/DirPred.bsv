import Types::*;
import ProcTypes::*;
import RegFile::*;

typedef Bit#(2) BhtEntry;
typedef 8 BhtTagSize;
typedef Bit#(BhtTagSize) BhtTag;
typedef Bit#(TSub#(AddrSz,BhtTagSize)) BhtIndex;


interface DirPred;
	method Bool predDir(Addr pc);
	method Action update(Redirect rd);
endinterface


module mkBHT(DirPred);
	
	RegFile#(BhtIndex, Bit#(2)) 	   counters <- mkRegFileFull;
	RegFile#(BhtIndex, Maybe#(BhtTag)) tags  	<- mkRegFileFull;
	
	function BhtIndex getIndex(Addr addr) = truncateLSB(addr);
	function BhtTag getTag(Addr addr) = truncate(addr);

	method Bool predDir(Addr pc);
		// Default : Predict that brnach is not taken
		Bool ret = False;

		let ctVal  = counters.sub(getIndex(pc));
		let tagVal = tags.sub(getIndex(pc));
		let tag    = getTag(pc);

		if(isValid(tagVal) && tag == fromMaybe(?,tagVal) && ctVal >= 2)
			ret = True;

		return ret;	
	endmethod

	method Action update(Redirect rd);
		//It doesn't check if it is overwriting information or not.
		//	Becuase it assumes that case will occur rarely

		let idx = getIndex(rd.pc);
		tags.upd(idx, Valid(getTag(rd.pc)));
		let ctVal = counters.sub(idx);

		if(rd.taken && ctVal != maxBound)
			counters.upd(idx, ctVal+1);
		else if(!rd.taken && ctVal !=0)
			counters.upd(idx, ctVal-1);
	endmethod

endmodule

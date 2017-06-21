import Types::*;
import ProcTypes::*;
import Vector::*;
import Ehr::*;
import Fifo::*;
import ConfigReg::*;

interface RFile;
	method Action wrE(RIndx rindx, Data data);
	method Action wrM(RIndx rindx, Data data);
	method Data rdA(RIndx rindx);
	method Data rdB(RIndx rindx);
endinterface

(*synthesize*)
module mkRFile(RFile);
	Vector#(8,Reg#(Data)) rfile <- replicateM(mkConfigReg(0)); // We have 8 registers

	Fifo#(1,Tuple2#(RIndx, Data)) bypassE <- mkBypassFifo;
	Fifo#(1,Tuple2#(RIndx, Data)) bypassM <- mkBypassFifo;
	
	function Data read(RIndx rindx);
		return rfile[rindx];
	endfunction
/*	
	function Data read(RIndx rindx);
			
		let eFull = bypassE.notEmpty;
		let mFull = bypassM.notEmpty;

		if(eFull && mFull)
		begin
			let eDst  = tpl_1(bypassE.first);
			let eData = tpl_2(bypassE.first);
			let mDst  = tpl_1(bypassM.first);
			let mData = tpl_2(bypassM.first);
		
			if(rindx == eDst)
				return eData;
			else if(rindx == mDst)
				return mData;
			else
				return rfile[rindx];
		end
		else if(eFull)
		begin
			let eDst  = tpl_1(bypassE.first);
			let eData = tpl_2(bypassE.first);

			if(rindx == eDst)
				return eData;
			else
				return rfile[rindx];
		end
		else if(mFull)
		begin
			let mDst  = tpl_1(bypassM.first);
			let mData = tpl_2(bypassM.first);

			if(rindx == mDst)
				return mData;
			else return rfile[rindx];
		end
		else
			return rfile[rindx];
	endfunction
*/

	rule update;
		let eFull = bypassE.notEmpty;
		let mFull = bypassM.notEmpty;

		if(eFull && mFull)
		begin
			bypassE.deq;
			bypassM.deq;

			let eDst  = tpl_1(bypassE.first);
			let eData = tpl_2(bypassE.first);
			let mDst  = tpl_1(bypassM.first);
			let mData = tpl_2(bypassM.first);


			if(eDst == mDst)
				rfile[eDst] <= eData;
			else
			begin
				rfile[eDst] <= eData;
				rfile[mDst] <= mData;
			end
		end
		else if(eFull)
		begin
			bypassE.deq;
			
			let eDst  = tpl_1(bypassE.first);
			let eData = tpl_2(bypassE.first);

			rfile[eDst] <= eData;
		end
		else if(mFull)
		begin
			bypassM.deq;

			let mDst = tpl_1(bypassM.first);
			let mData = tpl_2(bypassM.first);

			rfile[mDst] <= mData;
		end

	endrule
	
	method Action wrE(RIndx rindx, Data data);
		bypassE.enq(tuple2(rindx, data));
	endmethod

	method Action wrM(RIndx rindx, Data data);
		bypassM.enq(tuple2(rindx,data));
	endmethod



	method Data rdA(RIndx rindx) = read(rindx);
	method Data rdB(RIndx rindx) = read(rindx);

endmodule

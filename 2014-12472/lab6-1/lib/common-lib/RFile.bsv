import Types::*;
import ProcTypes::*;
import Vector::*;
import CReg::*;
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
	Vector#(8,CReg#(2,Data)) rFile <- replicateM(mkCReg(0));

	function Data read(RIndx rIdx) = rFile[rIdx][0];

	// wrM < wrE
	method Action wrE(RIndx rIdx, Data data);
		rFile[rIdx][0] <= data;
	endmethod

	method Action wrM(RIndx rIdx, Data data);
		rFile[rIdx][1] <= data;
	endmethod

	method Data rdA(RIndx rindx) = read(rindx);
	method Data rdB(RIndx rindx) = read(rindx);
endmodule

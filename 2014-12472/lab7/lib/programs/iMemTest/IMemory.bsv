import Types::*;
import MemTypes::*;
import RegFile::*;
import Vector::*;

interface IMemory;
	method FullInst req(Addr a);
endinterface

/*
(*synthesize*)
module mkIMemory(IMemory);
	RegFile#(MemIndx, InstPacket) iMem <- mkRegFileFullLoad("memory.vmh"); 
    
    method FullInst req(Addr a);
	    let indx   = a[31:1];
    	let offset = a[0];
		
    	Vector#(4, InstPacket) tempRegVec = newVector;
		
    	for(Integer i = 0 ; i < 4 ; i = i + 1)
    	    tempRegVec[i] = iMem.sub(truncate(indx + fromInteger(i)));

        let rdata = {tempRegVec[0], tempRegVec[1], tempRegVec[2], tempRegVec[3]};
    
	    return (offset == 0) ? rdata[63:16] : rdata[55:8];
    endmethod

endmodule
*/

(*synthesize*)
module mkIMemory(IMemory);
	Vector#(2, RegFile#(MemIndx, Bit#(8))) iMem = newVector;

	iMem[0] <- mkRegFileFullLoad("memory0.vmh"); 
	iMem[1] <- mkRegFileFullLoad("memory1.vmh"); 
    
    method FullInst req(Addr newAddr);
	    let idx   = newAddr[31:1];
    	let offset = newAddr[0];
		
    	Vector#(4, InstPacket) tempRegVec = newVector;
		
    	for(Integer i = 0 ; i < 4 ; i = i + 1)
    	    tempRegVec[i] = {	iMem[0].sub(truncate(idx + fromInteger(i))), 
								iMem[1].sub(truncate(idx + fromInteger(i)))};

        let rdata = {tempRegVec[0], tempRegVec[1], tempRegVec[2], tempRegVec[3]};
    
	    return (offset == 0) ? rdata[63:16] : rdata[55:8];
    endmethod
endmodule

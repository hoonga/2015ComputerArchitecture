import Types::*;
import MemTypes::*;
import RegFile::*;
import Vector::*;

interface IMemory;
	method Inst req(Addr a);
endinterface

(*synthesize*)
/*
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
*/

module mkIMemory(IMemory);
	RegFile#(MemIndx, Data) iMem <- mkRegFileFullLoad("memory.vmh");
	
	method req(Addr a);
		let idx = a >> 2;
		let offset = a[1:0];

		Vector#(3, Data) tempRegVec = newVector;

		for(Integer i = 0 ; i< 3 ; i = i +1)
			tempRegVec[i] = iMem.sub(truncate(idx + fromInteger(i)));

		let line = {tempRegVec[0], tempRegVec[1], tempRegVec[2]};
		

		case(offset) matches
			0:
				return line[95:48];
			1: 
				return line[87:40];
			2:
				return line[79:32];
			3:
				return line[71:24];
		endcase
	endmethod

endmodule


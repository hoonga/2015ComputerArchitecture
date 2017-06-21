

import Types::*;
import MemTypes::*;
import RegFile::*;
import Vector::*;

interface DMemory;
	method ActionValue#(MemResp) req(MemReq r);
endinterface

(*synthesize*)
module mkDMemory(DMemory);

  //Bit-wise memory
  RegFile#(MemIndx, Data) dMem <- mkRegFileFullLoad("memory.vmh"); 

  method ActionValue#(MemResp) req(MemReq r);
  	let idx = truncate(r.addr>>2);
	
	let data = dMem.sub(idx);

	if(r.op == St)
		dMem.upd(idx,r.data);

	return data;

  endmethod

endmodule



import Types::*;
import MemTypes::*;
import RegFile::*;

interface IMemory;
	method MemResp req(Addr a);
endinterface

(*synthesize*)
module mkIMemory(IMemory);
	RegFile#(Bit#(26), Data) mem <- mkRegFileFullLoad("memory.vmh"); // need to implement file

	method MemResp req(Addr a);
		return mem.sub(truncate(a>>2)); // Shifting is not essential(depends on config)
	endmethod
endmodule

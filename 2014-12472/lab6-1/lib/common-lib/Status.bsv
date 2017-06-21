
import ProcTypes::*;


/*
interface Status;
	method ActionValue#(Stat) req;	
	method Action set_AOK;
	method Action set_HLT;
	method Action set_ADR;
	method Action set_INS;
endinterface

(*synthesize*)
module mkstatus(Status);
	Reg#(Stat) stat <- mkReg(AOK);

	method ActionValue#(Stat) req;
		return stat;
	endmethod

	method Action set_AOK;
		stat <= AOK;
	endmethod

	method Action set_HLT;
		stat <= HLT;
	endmethod

	method Action set_ADR;
		stat <= ADR;
	endmethod

	method Action set_INS;
		stat <= INS;
	endmethod

endmodule
*/
function Bool isValidInst(Bit#(8) opCode);
  let iCode = opCode[7:4];
  let fCode = opCode[3:0];

  let res = case(iCode)
  				halt, nop, irmovl, rmmovl, mrmovl, call, ret, push, pop : (fCode == 0);
				cmov, jmp : ((fCode >=0) && (fCode <7));
				opl : ((fCode >= 0) && (fCode <4));
				copinst : ((fCode ==0) || (fCode ==1));
				default : False;
			endcase;

  return res;
endfunction
       	

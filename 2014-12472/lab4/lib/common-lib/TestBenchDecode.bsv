import ProcTypes::*;
import IMemory::*;
import Decode::*;
import Types::*;

typedef enum {Start, Run} State deriving (Bits, Eq);


(* synthesize *)
module mkTestBenchDecode();
  PrintDecode printD <- mkPrintDecode;

  Reg#(Bit#(32)) cycle <- mkReg(0);
  Reg#(Addr) pc <- mkRegU;
  Reg#(State)    state <- mkReg(Start);
  IMemory  iMem <- mkIMemory;

  rule start(state == Start);
    pc <= 32'h0000;
    state <= Run;
  endrule

  rule countCycle(state == Run);
    cycle <= cycle + 1;
    $display("\ncycle %d\n", cycle);
  endrule

  rule getstaus(state == Run);
	  if(cycle == 30)
	  begin
		  $fwrite(stderr, "Decode Test End");
		  $fwrite(stderr, "\n");
		  $finish;
	  end
	  else
	  begin
		  let inst = iMem.req(pc); 
		  let dInst = decode(inst,pc);
		  printD.printDecode(dInst);
		  pc <= nextAddr(pc,getICode(inst));
	  end
  endrule
endmodule

interface PrintDecode;
  method Action printDecode( DecodedInst item );
endinterface

module mkPrintDecode(PrintDecode);
	method Action printDecode(DecodedInst dInst);
		let iTypeString = case (dInst.iType)
							  Hlt   : "halt";
							  Nop    : "nop";
							  Rmov : "irmovl";
							  RMmov : "rmmovl";
							  MRmov : "mrmovl";
							  Cmov   : "cmov";
							  Opl	 : "opl";
							  Jmp    : "jmp";
							  Push   : "push";
							  Pop    : "pop";
							  Call   : "call";
							  Ret    : "ret";
							  Mtc0   : "mtc0";
							  Mfc0   : "mfc0";
							  Unsupported:	"Unsupported";
						  endcase;
		let funcString = case (dInst.oplFunc)
							FAdd:	"Add";
							FSub:	"Sub";
							FAnd:	"And";
							FXor:	"Xor";
							FNop:   "Nop";
						 endcase;

	    let condUsedString = case(dInst.condUsed)
								  Al  : "always";
								  Eq  : "equal";
								  Neq : "not equal";
								  Lt  : "less than";
								  Le  : "less than or equal";
								  Gt  : "greater than";
								  Ge  : "greater than or equal";
						    endcase;


		$display("===========Instruction Decoding===========");
		$display("Instruction Type:\t\t%s", iTypeString);
		$display("Opl Function:\t\t\t%s", funcString);
		$display("Condition Type:\t\t\t%s", condUsedString);
		$fwrite(stdout, "Destination Register:\t");
		if(isValid(dInst.dstE))
		begin
			$fwrite(stdout, "dstE : %d\n", fromMaybe(?, dInst.dstE));
		end
		else
		begin
			$fwrite(stdout, "dstE : Invalid\n");
		end
		if(isValid(dInst.dstM))
		begin
			$fwrite(stdout, "\t\t\t\t\t\tdstM : %d\n", fromMaybe(?, dInst.dstM));
		end
		else
		begin
			$fwrite(stdout, "\t\t\t\t\t\tdstM : Invalid\n");
		end
		$fwrite(stdout, "Source Register A:\t\t");
		if(isValid(dInst.regA))
		begin
			$fwrite(stdout, "%d\n", fromMaybe(?, dInst.regA));
		end
		else
		begin
			$fwrite(stdout, "Invalid\n");
		end
		$fwrite(stdout, "Source Register B:\t\t");
		if(isValid(dInst.regB))
		begin
			$fwrite(stdout, "%d\n", fromMaybe(?, dInst.regB));
		end
		else
		begin
			$fwrite(stdout, "Invalid\n");
		end
		$fwrite(stdout, "Constant Value:\t\t");
		if(isValid(dInst.valC))
		begin
			$fwrite(stdout, "%d\n", fromMaybe(?, dInst.valC));
		end
		else
		begin
			$fwrite(stdout, "	Invalid\n");
		end
		$display("==========================================\n");
	endmethod
endmodule

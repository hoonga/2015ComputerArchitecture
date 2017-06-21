import Types::*;
import ProcTypes::*;
import MemTypes::*;
import RFile::*;
import IMemory::*;
import DMemory::*;
import Decode::*;
import Exec::*;
import Cop::*;
import Fifo::*;

typedef struct {
	Inst inst;
	Addr pc;
	Addr ppc;
	Bool epoch;
} Fetch2Decode deriving(Bits, Eq);

typedef struct {
    DecodedInst dInst;
    Addr ppc;
    Bool epoch;
} Decode2Execute deriving(Bits, Eq);

(*synthesize*)
module mkProc(Proc);
  Reg#(Addr)    pc  <- mkRegU;
  RFile         rf  <- mkRFile;
  IMemory     iMem  <- mkIMemory;
  DMemory     dMem  <- mkDMemory;
  Cop          cop  <- mkCop;

  Reg#(CondFlag) 	    condFlag	 <- mkRegU;
  Reg#(ProcStatus)      stat		 <- mkRegU;

  Fifo#(1,Addr)         execRedirect <- mkCFFifo;
  Fifo#(1,ProcStatus)   statRedirect <- mkBypassFifo;

  Fifo#(2,Fetch2Decode)	 f2d  	     <- mkCFFifo;
  Fifo#(2,Decode2Execute)d2e         <- mkCFFifo;

  Reg#(Bool) fEpoch <- mkRegU;
  Reg#(Bool) eEpoch <- mkRegU;

  rule doFetch(cop.started && stat == AOK);	

      Addr tpc = execRedirect.notEmpty?execRedirect.first:pc;
      let epoch = execRedirect.notEmpty?!fEpoch:fEpoch;
	  let inst = iMem.req(tpc);
      let iCode = getICode(inst);
      let ppc = nextAddr(tpc,iCode);	  
	  if(execRedirect.notEmpty)
	  begin
		  execRedirect.deq;
          fEpoch <= !fEpoch;
	  end
	  pc <= ppc;

	f2d.enq(Fetch2Decode{inst:inst, pc:tpc, ppc:ppc, epoch:epoch});
	$display("Fetch : from Pc %d , expanded inst : %x, \n", tpc, inst, showInst(inst)); 
  endrule

  rule doDecode(cop.started && stat == AOK);
      let inst   = f2d.first.inst;
      let pc     = f2d.first.pc;
	  let ppc    = f2d.first.ppc;
	  let iEpoch = f2d.first.epoch;
	  f2d.deq;

      if(iEpoch == eEpoch)
      begin
          let dInst = decode(inst,pc);
          d2e.enq(Decode2Execute{dInst:dInst, ppc:ppc, epoch:iEpoch});
      end
  endrule


  rule doRest(cop.started && stat == AOK);
      let dinst  = d2e.first.dInst;
      let iEpoch = d2e.first.epoch;
      let ppc    = d2e.first.ppc;
      d2e.deq;

	  if(iEpoch == eEpoch)
	  begin
          //Decode
          dinst.valA   = isValid(dinst.regA)? tagged Valid rf.rdA(validRegValue(dinst.regA)) : Invalid;
   		  dinst.valB   = isValid(dinst.regB)? tagged Valid rf.rdB(validRegValue(dinst.regB)) : Invalid;
		  dinst.copVal = isValid(dinst.regA)? tagged Valid cop.rd(validRegValue(dinst.regA)) : Invalid;
 
		  //Exec
		  let eInst = exec(dinst, condFlag, ppc);
		  condFlag <= eInst.condFlag;

		  //Memory 
	      let iType = eInst.iType;
	      case(iType)
	 		MRmov, Pop, Ret :
   	 		begin
	   			let ldData <- (dMem.req(MemReq{op: Ld, addr: eInst.memAddr, data:?}));
		   		eInst.valM = Valid(little2BigEndian(ldData));
				if(iType == Ret)//Return address is known here
				begin
					eInst.nextPc = eInst.valM;
				end
	   		end

			RMmov, Call, Push :
			begin
				let stData = (iType == Call)? eInst.valP : validValue(eInst.valA); 
		  		let dummy <- dMem.req(MemReq{op: St, addr: eInst.memAddr, data: big2LittleEndian(stData)});
			end
	  	  endcase

		  //Update Status
		  let newStatus = case(iType)
		  				      Unsupported : INS;
							  Hlt 		  : HLT;
							  default     : AOK;
						  endcase;

		  if(eInst.mispredict)			
		  begin
		  	  eEpoch <= !eEpoch;
			  let redirPc = validValue(eInst.nextPc);
			  $display("mispredicted, redirect %d ", redirPc);
			  execRedirect.enq(redirPc);
              cop.incBPMissCnt();
              case(eInst.iType)
                  Call: cop.incMissInstTypeCnt(MCall);
                  Ret: cop.incMissInstTypeCnt(MRet);
                  Jmp: cop.incMissInstTypeCnt(MJmp);
              endcase
	 	  end
          else
          begin
              case(eInst.iType)
                  Call: cop.incMissInstTypeCnt(Call);
                  Jmp: cop.incMissInstTypeCnt(Jmp);
                  Ret: cop.incMissInstTypeCnt(Ret);
              endcase
          end
		statRedirect.enq(newStatus);

		  //WriteBack
		if(isValid(eInst.dstE))
		begin
			rf.wrE(validRegValue(eInst.dstE), validValue(eInst.valE));
		end
		if(isValid(eInst.dstM))
		begin
			rf.wrM(validRegValue(eInst.dstM), validValue(eInst.valM));
		end
		cop.wr(eInst.dstE, validValue(eInst.valE));


        case(eInst.iType)
            Call, Ret, Jmp: cop.incInstTypeCnt(Ctr);
            MRmov, RMmov, Push, Pop: cop.incInstTypeCnt(Mem);
        endcase
		/*	Exercise 3
			1. Use cop.incInstTypeCnt(instType) to count number of each instruciton type
			   - instType list
				Ctr(Control) 	 : call, ret, jump
				Mov(Move)		 : mrmovl, rmmovl, push, call
            
			2. Use cop.incBPMissCnt() to count number of mispredictions.
			
			Excercise 4
			1. Implement incInstTypeCnt(InstCntType inst) method in Cop.bsv
			2. Use cop.incInstTypeCnt(inst) to count number of mispredictions for each instruction types.
			
		*/
	end
  endrule



  rule upd_Stat(cop.started);
  	statRedirect.deq;
    stat <= statRedirect.first;
  endrule

  rule statHLT(cop.started && stat == HLT);
	$fwrite(stderr,"Program Finished by halt\n");
    $finish;
  endrule 

  rule statINS(cop.started && stat == INS);
	$fwrite(stderr,"Executed unsupported instruction. Exiting\n");
	$finish;
  endrule
  method ActionValue#(Tuple3#(RIndx, Data, Data)) cpuToHost;
    let retV <- cop.cpuToHost;
    return retV;
  endmethod

  method Action hostToCpu(Bit#(32) startpc) if (!cop.started);
    cop.start;
	eEpoch <= False;
	fEpoch <= False;
    pc <= startpc;
	stat <= AOK;
  endmethod

endmodule

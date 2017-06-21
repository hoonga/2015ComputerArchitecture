import Types::*;
import ProcTypes::*;
import MemTypes::*;
import BypassRFile::*;
import CacheTypes::*;
import Memory::*;
import IMemory::*;
import Decode::*;
import Exec::*;
import BypassCop::*;
import Fifo::*;
import Scoreboard::*;
import AddrPred::*;
import DirPred::*;
import Connectable::*;
import LocalCache::*; // Include it to use Cache


import Vector::*;

typedef struct {
	Inst inst;
	Addr pc;
	Addr ppc;
	Bool dEpoch;
	Bool eEpoch;
	Maybe#(Redirect) redir;
} Fetch2Decode deriving(Bits, Eq);

typedef struct {
	DecodedInst dInst;
	Addr pc;
	Addr ppc;
	Bool epoch;
} Decode2Exec deriving(Bits, Eq);

typedef struct {
	Addr pc;
 	Maybe#(ExecInst) eInst;
} Exec2Memory deriving(Bits, Eq);

typedef Maybe#(ExecInst) Memory2WriteBack;

(*synthesize*)
module mkProc(Proc);
  Reg#(Addr)    pc  <- mkRegU;
  RFile         rf  <- mkBypassRFile;
  Memory	   mem	<- mkMemory;
  IMemory     iMem  <- mkIMemory;
  Cop          cop  <- mkBypassCop;
  AddrPred   pcPred <- mkBtb;
  DirPred   dirPred <- mkBHT;

  Cache		dCache <- mkCache;

  Reg#(CondFlag) 	 condFlag	<- mkRegU;
  Reg#(ProcStatus)   stat		<- mkRegU;

  Reg#(Bool) fdEpoch <- mkRegU;
  Reg#(Bool) feEpoch <- mkRegU;
  Reg#(Bool) dEpoch  <- mkRegU;
  Reg#(Bool) deEpoch <- mkRegU;
  Reg#(Bool) eEpoch  <- mkRegU;


  Scoreboard#(8)  sb <- mkPipelineScoreboard;

  Fifo#(1,Redirect)       exeRedirect 	<- mkBypassFifo;
  Fifo#(1,Redirect)       memRedirect 	<- mkBypassFifo;
  Fifo#(1,ProcStatus) 	  statRedirect 	<- mkBypassFifo;
  Fifo#(1,Tuple2#(Bool,Addr)) dirPredictRedirect <- mkBypassFifo;

  
  Fifo#(1,Tuple4#(Addr, Bool, Bool, Maybe#(Redirect)))			f12f2	<- mkBypassFifo;
  Fifo#(1,Fetch2Decode)			f2d    	<- mkPipelineFifo;
  Fifo#(1,Decode2Exec)      	d2e     <- mkPipelineFifo;
  Fifo#(1,Exec2Memory)      	e2m		<- mkPipelineFifo;
  Fifo#(1,Exec2Memory)			m12m2	<- mkBypassFifo;
  Fifo#(1,Memory2WriteBack) 	m2w		<- mkPipelineFifo;

  rule doFetch(cop.started && stat == AOK);
	  $display("Fetch1");
	  Bool redirected;
	  Maybe#(Redirect) redir;
	  Maybe#(Addr) updatedPc;
	  let nextDEpoch = fdEpoch;
	  let nextEEpoch = feEpoch;

	  let exeR = exeRedirect.notEmpty;
	  let memR = memRedirect.notEmpty;
	  let dirR = dirPredictRedirect.notEmpty;


	  if(memR) memRedirect.deq;
	  if(exeR) exeRedirect.deq;
	  if(dirR) dirPredictRedirect.deq;

	  if(memR)
	  begin
		  pcPred.update(memRedirect.first);
		  redir = Valid(memRedirect.first);
	  end
	  else if(exeR)
	  begin
		  pcPred.update(exeRedirect.first);
		  redir = Valid(exeRedirect.first);
	  end
	  else
	  begin
		  redir = Invalid;
	  end

	  if(memR && memRedirect.first.mispredict)
	  begin
		  feEpoch <= !feEpoch;
		  nextEEpoch = !feEpoch;
		  redirected = True;
		  updatedPc = Valid(memRedirect.first.nextPc);
	  end
	  else if(exeR && exeRedirect.first.mispredict)
	  begin
		  feEpoch <= !feEpoch;
		  nextEEpoch = !feEpoch;
		  redirected = True;
		  updatedPc = Valid(exeRedirect.first.nextPc);
	  end
	  else if(dirR && tpl_1(dirPredictRedirect.first) == feEpoch)
	  begin
		  fdEpoch <= !fdEpoch;
		  nextDEpoch = !fdEpoch;
		  redirected = True;
		  updatedPc = Valid(tpl_2(dirPredictRedirect.first));
	  end
	  else
	  begin
		  redirected = False;
		  updatedPc = Invalid;
	  end

	  let realPc = fromMaybe(pc,updatedPc);
	  let inst =  iMem.req(realPc);
	
	  let ppc = pcPred.predPc(realPc,getICode(inst));
	  pc <= ppc;

	  $display("Fetch : from Pc %d , expanded inst : %x, \n", realPc, inst, showInst(inst)); 
	  f2d.enq(Fetch2Decode{inst: inst, pc: realPc, ppc: ppc, dEpoch: nextDEpoch, eEpoch: nextEEpoch, redir: redir});
  endrule

  rule doDecode(cop.started && stat == AOK);
	  let x 	  = f2d.first;
	  let inst    = x.inst;
	  let ipc      = x.pc;
	  let ppc     = x.ppc;
	  let fdEpoch = x.dEpoch;
	  let feEpoch = x.eEpoch;
	  let redir   = x.redir;

	  let dInst = decode(inst, ipc);
	  let predNextPc = ppc;

	  let stall = sb.search1(dInst.regA) || sb.search2(dInst.regB);

	  if(!stall)
	  begin
	  	  f2d.deq;

		  let dEpochLocal = dEpoch;

		  if(isValid(redir))
			  dirPred.update(validValue(redir));

		  if(feEpoch != deEpoch)
		  begin
			  deEpoch <= feEpoch;
			  dEpochLocal = fdEpoch;
		  end

		  if(fdEpoch == dEpochLocal)
		  begin
			  Bool dir = dirPred.predDir(ipc);

			  predNextPc = case(dInst.iType)
			  					Jmp  : (dir? validValue(dInst.valC):dInst.valP);
								Call : validValue(dInst.valC);
								default : dInst.valP;
						  	   endcase;

			  if(predNextPc != ppc)
			  begin
				  dirPredictRedirect.enq(tuple2(feEpoch, predNextPc));
				  dEpochLocal = !dEpochLocal;
			  end
		  end

		  dEpoch <= !dEpochLocal;

		  sb.insertE(dInst.dstE);
		  sb.insertM(dInst.dstM);

  		  dInst.valA   = isValid(dInst.regA)? tagged Valid rf.rdA(validRegValue(dInst.regA)) : Invalid;
	   	  dInst.valB   = isValid(dInst.regB)? tagged Valid rf.rdB(validRegValue(dInst.regB)) : Invalid;
		  dInst.copVal = isValid(dInst.regA)? tagged Valid cop.rd(validRegValue(dInst.regA)) : Invalid;

		  d2e.enq(Decode2Exec{dInst: dInst, pc: ipc, ppc: predNextPc, epoch: feEpoch}); 
	  end
	  else
		  $display("stall occured");

  endrule

  rule doExec(cop.started && stat == AOK);

	  d2e.deq;
	  let x = d2e.first;
	  let dInst = x.dInst;
	  let ipc = x.pc;
	  let ppc = x.ppc;
	  let iEpoch = x.epoch;


	  if(iEpoch == eEpoch)
	  begin
	  	  $display("Exec on pc %d",ipc);
		  let eInst = exec(dInst, condFlag, ppc);
		  condFlag <= eInst.condFlag;

  		  if(eInst.mispredict)
		  begin
			  eEpoch <= !eEpoch;
			  if(eInst.iType != Ret)
			  begin
			  	  $display("ExecRedirect : addr %d", validValue(eInst.addr));
				  exeRedirect.enq(Redirect{pc: ipc, nextPc: validValue(eInst.addr), taken: eInst.condSatisfied, mispredict: eInst.mispredict});
			  end
		  end

		  e2m.enq(Exec2Memory{pc: ipc, eInst: Valid(eInst)});
	  end
	  else
	  begin
		  $display("Exec : Invalidated on pc %d",ipc);
		  e2m.enq(Exec2Memory{pc: ipc, eInst: Invalid});
	  end
  endrule


  rule doMem1(cop.started && stat == AOK);
		  e2m.deq;
		  let ipc   = e2m.first.pc;
		  if(isValid(e2m.first.eInst))
		  begin
		  $display("Mem on pc %d",ipc);
		  	  let eInst = validValue(e2m.first.eInst);

			  let newStatus = case(eInst.iType)
			  				      Unsupported : INS;
								  Hlt 		  : HLT;
								  default     : AOK;
							  endcase;

			  statRedirect.enq(newStatus);

			  //Memory 
		      let iType = eInst.iType;
		      case(iType)
		 		MRmov, Pop, Ret :
   		 		begin
					/* Change this part */
		   			dCache.req(MemReq{op: Ld, addr: eInst.memAddr, data:?});
		   		end

				RMmov, Call, Push :
				begin
					let stData = (iType == Call)? eInst.valP : validValue(eInst.valA); 
					/* Change this part */
			  		dCache.req(MemReq{op: St, addr: eInst.memAddr, data: big2LittleEndian(stData)});
					$display("Store %d on %d",stData,eInst.memAddr);
				end
		  	  endcase


			  m12m2.enq(Exec2Memory{pc: ipc, eInst: Valid(eInst)});
		end
		else
		begin
			$display("Mem invalidated on pc %d",ipc);
			m12m2.enq(Exec2Memory{pc: ipc, eInst: Invalid});
		end

  endrule

  rule doMem2(cop.started && stat ==AOK);
	m12m2.deq;
    if(isValid(m12m2.first.eInst))
	begin
		let eInst = validValue(m12m2.first.eInst);
		let ipc = m12m2.first.pc;
		Data ldData =?;
		case(eInst.iType)
			MRmov, Pop, Ret :
			begin

				/* Change this part */
				ldData <- dCache.resp;
				eInst.valM = Valid(little2BigEndian(ldData));
				$display("Loaded %d from %d",little2BigEndian(ldData),eInst.memAddr);
			end
		endcase

		//Update Status
		if(eInst.iType == Ret)
		begin
			memRedirect.enq(Redirect{pc:ipc, nextPc: validValue(eInst.valM), taken: eInst.condSatisfied, mispredict: eInst.mispredict});
			$display("memRedirect : addr %d", validValue(eInst.valM));
		end

		m2w.enq(Valid(eInst));
	end
	else
	begin
		m2w.enq(Invalid);
	end
  endrule

  rule doWriteBack(cop.started && stat == AOK);
	  $display("Write Back");
	  m2w.deq;
	  sb.remove;
	  if(isValid(m2w.first))
	  begin
		let eInst = validValue(m2w.first);

		if(isValid(eInst.dstE))
		begin
			rf.wrE(validRegValue(eInst.dstE), validValue(eInst.valE));
			$display("WriteE writes %d on %d",validValue(eInst.valE), validRegValue(eInst.dstE));
		end
		if(isValid(eInst.dstM))
		begin
			rf.wrM(validRegValue(eInst.dstM), validValue(eInst.valM));
			$display("WriteM writes %d on %d",validValue(eInst.valM), validRegValue(eInst.dstM));
		end
		cop.wr(eInst.dstE, validValue(eInst.valE));
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

  /* Activate these two lines for cache */  
  mkConnection(mem.dReq, dCache.memReq);
  mkConnection(mem.dResp, dCache.memResp);

  method ActionValue#(Tuple2#(Data, Data)) getCounts;
      return tuple2(dCache.getTotalReq, dCache.getMissCnt);
  endmethod

  method ActionValue#(Tuple3#(RIndx, Data, Data)) cpuToHost;
    let retV <- cop.cpuToHost;
    return retV;
  endmethod

  method Action hostToCpu(Bit#(32) startpc) if (!cop.started);
    cop.start;
	fdEpoch <= False;
	feEpoch <= False;
	dEpoch <= False;
	deEpoch <= False;
	eEpoch <= False;
    pc <= startpc;
	stat <= AOK;
  endmethod

endmodule

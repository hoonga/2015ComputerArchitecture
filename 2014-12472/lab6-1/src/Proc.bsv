import Types::*;
import ProcTypes::*;
import MemTypes::*;
import BypassRFile::*; 
import IMemory::*;
import DMemory::*;
import Decode::*;
import Exec::*;
import Cop::*;
import Fifo::*;
import Scoreboard::*;

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
} Decode2Exec deriving(Bits, Eq);

typedef struct {
    ExecInst eInst;
    Bool v;
} Exec2Mem deriving(Bits, Eq);

typedef struct {
    ExecInst eInst;
    Bool v;
} Mem2Write deriving(Bits, Eq);


(*synthesize*)
module mkProc(Proc);
    Reg#(Addr)    pc  <- mkRegU;
    RFile         rf  <- mkBypassRFile;
    IMemory     iMem  <- mkIMemory;
    DMemory     dMem  <- mkDMemory;
    Cop          cop  <- mkCop;

    Reg#(CondFlag) 	 	condFlag	<- mkRegU;
    Reg#(ProcStatus)   	stat		<- mkRegU;

    Fifo#(1,Addr)       execRedirect <- mkBypassFifo;
    Fifo#(1,Addr)       memRedirect  <- mkBypassFifo;
    Fifo#(1,ProcStatus) statRedirect <- mkBypassFifo;

    Fifo#(1,Fetch2Decode)	f2d    	   <- mkPipelineFifo;
    Fifo#(1,Decode2Exec)    d2e        <- mkPipelineFifo;
    Fifo#(1,Exec2Mem)       e2m        <- mkPipelineFifo;
    Fifo#(1,Mem2Write)      m2w        <- mkPipelineFifo;

    Scoreboard#(3) sb <- mkPipelineScoreboard;


    Reg#(Bool) fEpoch <- mkRegU;
    Reg#(Bool) eEpoch <- mkRegU;

    rule doFetch(cop.started && stat == AOK);
        $display("=====fetch=====");

        if(memRedirect.notEmpty)
        begin
            memRedirect.deq;
        end
        if(execRedirect.notEmpty)
        begin
            execRedirect.deq;
        end		 
        let ipc = memRedirect.notEmpty?memRedirect.first:execRedirect.notEmpty?execRedirect.first:pc;
        let inst = iMem.req(ipc);
        let ppc = nextAddr(ipc, getICode(inst));
        let iEpoch = fEpoch;
        iEpoch = memRedirect.notEmpty ? !iEpoch : iEpoch;
        iEpoch = execRedirect.notEmpty ? !iEpoch : iEpoch;

        $display("Fetch : from Pc %d , expanded inst : %x, \n", ipc, inst, showInst(inst));
        fEpoch <= iEpoch;
        pc <= ppc;

        f2d.enq(Fetch2Decode{inst:inst, pc:ipc, ppc:ppc, epoch:iEpoch});
    endrule

    rule doDecode(cop.started && stat == AOK);
        $display("=====decode=====");
        let inst   = f2d.first.inst;
        let ipc    = f2d.first.pc;
        let ppc    = f2d.first.ppc;
        let iEpoch = f2d.first.epoch;

        let dInst = decode(inst, ipc);
        let stall = sb.search1(dInst.regA)||sb.search2(dInst.regB)||sb.search3(dInst.dstE)||sb.search4(dInst.dstM);
        if (!stall)
        begin
            //Decode 
            $display("Decode : from Pc %d , expanded inst : %x, \n", ipc, inst, showInst(inst)); 
            dInst.valA   = isValid(dInst.regA)? tagged Valid rf.rdA(validRegValue(dInst.regA)) : Invalid;
            dInst.valB   = isValid(dInst.regB)? tagged Valid rf.rdB(validRegValue(dInst.regB)) : Invalid;
            dInst.copVal = isValid(dInst.regA)? tagged Valid cop.rd(validRegValue(dInst.regA)) : Invalid; 
            d2e.enq(Decode2Exec{dInst:dInst, ppc:ppc, epoch:iEpoch});
            sb.insertE(dInst.dstE);
            sb.insertM(dInst.dstM);
            f2d.deq;
        end
        else
            $display("Stalled :(");
    endrule

    rule doExecute(cop.started && stat == AOK);
        $display("=====execute=====");
        let dInst = d2e.first.dInst;
        let ppc = d2e.first.ppc;
        let iEpoch = d2e.first.epoch;
        d2e.deq;

        let eInst = exec(dInst, condFlag, ppc);
        if (iEpoch == eEpoch)
        begin
            condFlag <= eInst.condFlag;
 
            if(eInst.mispredict)			
            begin
                eEpoch <= !eEpoch;
                if (eInst.iType != Ret)
                begin
                    let redirPc = validValue(eInst.nextPc);
                    $display("mispredicted, redirect %d ", redirPc);
                    execRedirect.enq(redirPc);
                end
            end
            e2m.enq(Exec2Mem{eInst:eInst, v:True});
        end
        else
            e2m.enq(Exec2Mem{eInst:eInst, v:False});
    endrule

    rule doMemory(cop.started && stat == AOK);
        $display("=====memory=====");
        let eInst = e2m.first.eInst;
        let v = e2m.first.v;
        e2m.deq;
        if (v)
        begin
            let iType = eInst.iType;
            case(iType)
                MRmov, Pop, Ret :
                begin
                    let ldData <- (dMem.req(MemReq{op: Ld, addr: eInst.memAddr, data:?}));
                    eInst.valM = Valid(little2BigEndian(ldData));
                    $display("Loaded %d from %d",little2BigEndian(ldData), eInst.memAddr);
                    if(iType == Ret)
                    begin
                        eInst.nextPc = eInst.valM;
                        memRedirect.enq(validValue(eInst.nextPc));
                    end
                end

                RMmov, Call, Push : begin let stData = (iType == Call)? eInst.valP : validValue(eInst.valA); 
                    let dummy <- dMem.req(MemReq{op: St, addr: eInst.memAddr, data: big2LittleEndian(stData)});
                    $display("Stored %d into %d",stData, eInst.memAddr);
                end
            endcase
            m2w.enq(Mem2Write{eInst:eInst,v:True});
        end
        else
            m2w.enq(Mem2Write{eInst:eInst,v:False});
    endrule

    rule doWriteBack(cop.started && stat == AOK);
        $display("=====writeback=====");
        let eInst = m2w.first.eInst;
        let v = m2w.first.v;
        m2w.deq;

        if(v)
        begin
            let newStatus = case(eInst.iType)
                Unsupported : INS;
                Hlt 		: HLT;
                default     : AOK;
            endcase;
            statRedirect.enq(newStatus);

            //WriteBack
            if(isValid(eInst.dstE))
            begin
                $display("On %d, writes %d   (wrE)",validRegValue(eInst.dstE), validValue(eInst.valE));
                rf.wrE(validRegValue(eInst.dstE), validValue(eInst.valE));
            end

            if(isValid(eInst.dstM))
            begin
                $display("On %d, writes %d   (wrM)",validRegValue(eInst.dstM), validValue(eInst.valM));
                rf.wrM(validRegValue(eInst.dstM), validValue(eInst.valM));
            end
           
            cop.wr(eInst.dstE, validValue(eInst.valE));
        end
        sb.remove;
    endrule

    rule upd_Stat(cop.started);
        $display("Stat update");
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

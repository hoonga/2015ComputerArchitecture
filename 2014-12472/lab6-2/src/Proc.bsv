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

typedef struct {
   Maybe#(FullIndx) dstE;
   Maybe#(FullIndx) dstM;
   Maybe#(Data) valE;
   Maybe#(Data) valM;
} Forward deriving(Bits, Eq);

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

    Fifo#(1,Forward)        e2d        <- mkBypassFifo;
    Fifo#(1,Forward)        m2d        <- mkBypassFifo;

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
        Forward f[2];
        
        if(e2d.notEmpty)
        begin
            e2d.deq;
            f[1] = e2d.first;
        end
        else
            f[1] = Forward{dstE:Invalid,dstM:Invalid,valE:Invalid,valM:Invalid};
        if(m2d.notEmpty)
        begin
            m2d.deq;
            f[0] = m2d.first;
        end
        else
            f[0] = Forward{dstE:Invalid,dstM:Invalid,valE:Invalid,valM:Invalid};

        DecodedInst dInst = decode(inst, ipc);
        Bool stall = False;
         
        $display("Decode : from Pc %d , expanded inst : %x, \n", ipc, inst, showInst(inst));

        Bool forwardA = False;
        Bool forwardB = False;
        if(isValid(dInst.regA))
        begin
            if(isValid(f[0].dstE)&&validValue(f[0].dstE)==validValue(dInst.regA))
            begin
                dInst.valA = f[0].valE;
                forwardA = True;
            end
            else if(isValid(f[0].dstM)&&validValue(f[0].dstM)==validValue(dInst.regA))
            begin
                if(f[0].valM==Invalid)
                begin
                    stall =True;
                end
                else
                begin
                    dInst.valA = f[0].valM;
                    forwardA = True;
                end
            end
            if(isValid(f[1].dstE)&&validValue(f[1].dstE)==validValue(dInst.regA))
            begin
                dInst.valA = f[1].valE;
                forwardA = True;
            end
            else if(isValid(f[1].dstM)&&validValue(f[1].dstM)==validValue(dInst.regA))
            begin
                if(f[1].valM==Invalid)
                begin
                    stall =True;
                end
                else
                begin
                    dInst.valA = f[1].valM;
                    forwardA = True;
                end
            end
            if(!forwardA)
            begin
                dInst.valA = tagged Valid rf.rdA(validRegValue(dInst.regA));
            end
        end
        else
            dInst.valA = Invalid;

        if(isValid(dInst.regB))
        begin
            if(isValid(f[0].dstE)&&validValue(f[0].dstE)==validValue(dInst.regB))
            begin
                dInst.valB = f[0].valE;
                forwardB = True;
            end
            else if(isValid(f[0].dstM)&&validValue(f[0].dstM)==validValue(dInst.regB))
            begin
                if(f[0].valM==Invalid)
                begin
                    stall =True;
                end
                else
                begin
                    dInst.valB = f[0].valM;
                    forwardB = True;
                 end
            end
            if(isValid(f[1].dstE)&&validValue(f[1].dstE)==validValue(dInst.regB))
            begin
                dInst.valB = f[1].valE;
                forwardB = True;
            end
            else if(isValid(f[1].dstM)&&validValue(f[1].dstM)==validValue(dInst.regB))
            begin
                if(f[1].valM==Invalid)
                begin
                    stall =True;
                end
                else
                begin
                    dInst.valB = f[1].valM;
                    forwardB = True;
                end
            end
            if(!forwardB)
            begin
                dInst.valB = tagged Valid rf.rdB(validRegValue(dInst.regB));
            end
        end
        else
            dInst.valB = Invalid;
        
        dInst.copVal = isValid(dInst.regA)? tagged Valid cop.rd(validRegValue(dInst.regA)) : Invalid; 
        if(!stall)
        begin
            d2e.enq(Decode2Exec{dInst:dInst, ppc:ppc, epoch:iEpoch});
            f2d.deq;
        end
        else
            $display("stall");
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
            e2d.enq(Forward{dstE:eInst.dstE, dstM:eInst.dstM, valE:eInst.valE, valM:eInst.valM});
            $display("dstE: %d, valE: %d", validRegValue(eInst.dstE),validValue(eInst.valE));
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

                RMmov, Call, Push : 
                begin 
                let stData = (iType == Call)? eInst.valP : validValue(eInst.valA); 
                    let dummy <- dMem.req(MemReq{op: St, addr: eInst.memAddr, data: big2LittleEndian(stData)});
                    $display("Stored %d into %d",stData, eInst.memAddr);
                end
            endcase
            m2w.enq(Mem2Write{eInst:eInst,v:True});
            m2d.enq(Forward{dstE:eInst.dstE, dstM:eInst.dstM, valE:eInst.valE, valM:eInst.valM});
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

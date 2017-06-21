
import Types::*; 
import IMemory::*;


interface TestIMem;

endinterface

function Addr getOffSet(Inst inst);
//function Addr getOffSet(Data inst);
    let iCode = inst[47:44];
//    let iCode = inst[31:28];
    let ofs = case(iCode) matches
                   0  : 1; //halt
                   1  : 1; //nop
                   2  : 2; //cmov
                   3  : 6; //irmov
                   4  : 6; //rmmov
                   5  : 6; //mrmov
                   6  : 2; //opl
                   7  : 5; //jmp
                   8  : 5; //call
                   9  : 1; //ret
                   10 : 2; //push
                   11 : 2; //pop
              endcase;
    return ofs;
endfunction 


(*synthesize*)
module mkTest(TestIMem);

  IMemory iMem <- mkIMemory;

//Reg#(MemIndx) pointer <- mkReg(1);
  Reg#(Addr)    pc      <- mkReg(0);

  


  rule run(pc < 100); //truncate(eoa)-6);
//  rule run(pc<8000);
    let fInst  = iMem.req(pc);
    let offset = getOffSet(fInst);
    
    case(offset) matches
        1 : $display("Instruction code at pc %d : %x", pc, fInst[47:40]);
        2 : $display("Instruction code at pc %d : %x", pc, fInst[47:32]);
        5 : $display("Instruction code at pc %d : %x", pc, fInst[47:8]);
        6 : $display("Instruction code at pc %d : %x", pc, fInst[47:0]);
    endcase
    
//   $display("Instruction code at pc %d : %x", pc, fInst);
    pc <= pc + offset;
//      pc <= pc +4;
  endrule 


//  rule finish(pc >= truncate(eoa)-6);
  rule finish(pc >= 100); //truncate(eoa));
    $display("End of test: %x\n", 26);
    $finish;
  endrule

endmodule

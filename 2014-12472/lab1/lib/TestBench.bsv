import BarrelShifterRight::*;
import Multiplexer::*;
import Rand::*;

(* synthesize *)
module mkTbMultiplexer();
  Reg#(Bit#(32)) cycle <- mkReg(0);
  Rand#(32) randomVal1 <- mkRand('hdeadbeef);
  Rand#(32) randomVal2 <- mkRand('hcafebabe);
  Rand#(1)   randomSel <- mkRand('hf01dab1e);

  rule test;
    if(cycle == 128)
    begin
      $display("PASSED");
      $finish;
    end
    else
    begin
      let val1 <- randomVal1.get;
      let val2 <- randomVal2.get;
      let sel <- randomSel.get;
      let test = multiplexer32(sel, val1, val2);
      let realAns = sel == 0? val1: val2;
      if(test != realAns)
      begin
        $display("FAILED Sel %b from %d, %d gave %d instead of %d", sel, val1, val2, test, realAns);
        $finish;
      end
      cycle <= cycle + 1;
    end
  endrule
endmodule

(* synthesize *)
module mkTbRightLogical();
  BarrelShifterRightLogical bsrl <- mkBarrelShifterRightLogical;

  Reg#(Bit#(32)) cycle <- mkReg(0);
  Rand#(32) randomVal <- mkRand('hdeadbeef);
  Rand#(5) randomShift <- mkRand('hcafebabe);

  rule test;
    if(cycle == 128)
    begin
      $display("PASSED");
      $finish;
    end
    else
    begin
      let val <- randomVal.get;
      let shift <- randomShift.get;
      let implResultL <- bsrl.rightShift(val, shift);
      let trueResultL = val >> shift;
      if(implResultL != trueResultL)
      begin
        $display("FAILED Logical Shift %b >> %d gave %b instead of %b", val, shift, implResultL, trueResultL);
        $finish;
      end
      cycle <= cycle + 1;
    end
  endrule
endmodule

(* synthesize *)
module mkTbRightArith();
  BarrelShifterRightArithmetic bsra <- mkBarrelShifterRightArithmetic;

  Reg#(Bit#(32)) cycle <- mkReg(0);
  Rand#(32) randomVal <- mkRand('hdeadbeef);
  Rand#(5) randomShift <- mkRand('hcafebabe);

  rule test;
    if(cycle == 128)
    begin
      $display("PASSED");
      $finish;
    end
    else
    begin
      let val <- randomVal.get;
      let shift <- randomShift.get;
      let implResultA <- bsra.rightShift(val, shift);
      Int#(32) valNew = unpack(val);
      let trueResultA = pack(valNew >> shift);
      if(implResultA != trueResultA)
      begin
        $display("FAILED Arithmetic Shift %b >> %d gave %b instead of %b", val, shift, implResultA, trueResultA);
        $finish;
      end
      cycle <= cycle + 1;
    end
  endrule
endmodule

import Multiplexer::*;

interface BarrelShifterRight;
  method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt, Bit#(1) shiftValue);
endinterface

module mkBarrelShifterRight(BarrelShifterRight);
  method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt, Bit#(1) shiftValue);
  Bit#(32) a = val;
  Bit#(32) tmp = 0;
  for (Integer i = 0; i < 5; i = i + 1) begin
	  for (Integer j = 0; j < 32 - 2**i; j = j + 1)
          tmp[j] = a[j+2**i];
	  for (Integer j = 32 - 2**i; j < 32; j = j + 1)
          tmp[j] = shiftValue;
      a = multiplexer32(shiftAmt[i],a,tmp);
  end
  	  return a;
  endmethod
endmodule

interface BarrelShifterRightLogical;
  method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt);
endinterface

module mkBarrelShifterRightLogical(BarrelShifterRightLogical);
  let bsr <- mkBarrelShifterRight;
  method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt);
    Bit#(32) r <- bsr.rightShift(val,shiftAmt,0);
	return r;
  endmethod
endmodule

typedef BarrelShifterRightLogical BarrelShifterRightArithmetic;

module mkBarrelShifterRightArithmetic(BarrelShifterRightArithmetic);
  let bsr <- mkBarrelShifterRight;
  method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt);
	  Bit#(32) r <- bsr.rightShift(val,shiftAmt,val[31]);
    return r;
  endmethod
endmodule


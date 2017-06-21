import BarrelShifterRight::*;

interface BarrelShifterLeft;
	method ActionValue#(Bit#(32)) leftShift(Bit#(32) val, Bit#(5) shiftAmt);
endinterface

module mkBarrelShifterLeft(BarrelShifterLeft);
	let bsr <- mkBarrelShifterRightLogical;
	method ActionValue#(Bit#(32)) leftShift(Bit#(32) val, Bit#(5) shiftAmt);
		val = reverseBits(val);
		Bit#(32)out <- bsr.rightShift(val,shiftAmt);
		return reverseBits(out);
	endmethod
endmodule

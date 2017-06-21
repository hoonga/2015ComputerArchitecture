import Multiplexer::*;

interface BarrelShifterRight;
	method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt, Bit#(1) shiftValue);
endinterface

module mkBarrelShifterRight(BarrelShifterRight);
	method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt, Bit#(1) shiftValue);
		return ?;
	endmethod
endmodule

interface BarrelShifterRightLogical;
	method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt);
endinterface

module mkBarrelShifterRightLogical(BarrelShifterRightLogical);
//	let bsr <- mkBarrelShifterRight;
	method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt);
		return (val >> shiftAmt);
	endmethod
endmodule

typedef BarrelShifterRightLogical BarrelShifterRightArithmetic;

module mkBarrelShifterRightArithmetic(BarrelShifterRightArithmetic);
//	let bsr <- mkBarrelShifterRight;
	method ActionValue#(Bit#(32)) rightShift(Bit#(32) val, Bit#(5) shiftAmt);
		Int#(32) newVal = unpack(val);
		return pack(newVal >> shiftAmt);
	endmethod
endmodule

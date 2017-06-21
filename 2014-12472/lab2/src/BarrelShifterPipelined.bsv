import Multiplexer::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import SpecialFIFOs::*;

/* Interface of the basic right shifter module */
interface BarrelShifterRightPipelined;
	method Action shift_request(Bit#(32) operand, Bit#(5) shamt, Bit#(1) val);
	method ActionValue#(Bit#(32)) shift_response();
endinterface

/* Interface of the three shifter modules
 *
 * They have the same interface.
 * So, we just copy it using typedef declarations.
 */
interface BarrelShifterRightLogicalPipelined;
	method Action shift_request(Bit#(32) operand, Bit#(5) shamt);
	method ActionValue#(Bit#(32)) shift_response();
endinterface

typedef BarrelShifterRightLogicalPipelined BarrelShifterRightArithmeticPipelined;
typedef BarrelShifterRightLogicalPipelined BarrelShifterLeftPipelined;

module mkBarrelShifterLeftPipelined(BarrelShifterLeftPipelined);
	/* Implement left shifter using the pipelined right shifter. */
	let bsrp <- mkBarrelShifterRightPipelined;

	method Action shift_request(Bit#(32) operand, Bit#(5) shamt);
		bsrp.shift_request(reverseBits(operand), shamt, 0);
	endmethod

	method ActionValue#(Bit#(32)) shift_response();
		Bit#(32) out <- bsrp.shift_response();
		return reverseBits(out);
	endmethod
endmodule

module mkBarrelShifterRightLogicalPipelined(BarrelShifterRightLogicalPipelined);
	/* Implement right logical shifter using the pipelined right shifter. */
	let bsrp <- mkBarrelShifterRightPipelined;

	method Action shift_request(Bit#(32) operand, Bit#(5) shamt);
		bsrp.shift_request(operand, shamt, 0);
	endmethod

	method ActionValue#(Bit#(32)) shift_response();
		Bit#(32) out <- bsrp.shift_response();
		return out;
	endmethod
endmodule

module mkBarrelShifterRightArithmeticPipelined(BarrelShifterRightArithmeticPipelined);
	/* Implement right arithmetic shifter using the pipelined right shifter. */
	let bsrp <- mkBarrelShifterRightPipelined;

	method Action shift_request(Bit#(32) operand, Bit#(5) shamt);
		bsrp.shift_request(operand, shamt, operand[31]);
	endmethod

	method ActionValue#(Bit#(32)) shift_response();
		Bit#(32) out <- bsrp.shift_response();
		return out;
	endmethod

endmodule

module mkBarrelShifterRightPipelined(BarrelShifterRightPipelined);

	let inFifo <- mkFIFOF;
	let outFifo <- mkFIFOF;
	Reg#(Tuple4#(Bit#(1),Bit#(32),Bit#(5),Bit#(1))) s[4];
	for (int i = 0; i < 4; i=i+1)
		s[i] <- mkRegU;
	rule shift;
		/* Implement a pipelined right shift logic. */
		if (inFifo.notEmpty()) begin
			let {op,sa,v} = inFifo.first();
			inFifo.deq();
			op = sa[0]==1?{v,op[31:1]}:op;
			s[0] <= tuple4(1,op,sa,v);
		end
		else begin
			s[0] <= tuple4(0,0,0,0);
		end
		for (Integer i = 0; i < 3; i=i+1) begin
			let {f,op,sa,v} = s[i];
			Bit#(32) t;
			for (Integer j = 31; j > 31 - (2**(i+1)); j=j-1)
				t[j] = v;
			for (Integer j = 31 - (2**(i+1)); j > -1; j=j-1)
				t[j] = op[j + (2**(i+1))];
			op = (sa[i+1]==1)?t:op;
			s[i+1]<=tuple4(f,op,sa,v);
		end
		if (outFifo.notFull()) begin
			let {f,op,sa,v} = (s[3]);
			Bit#(32) t;
			for(Integer j = 31; j > 31 - 16; j = j-1)
				t[j] = v;
			for (Integer j = 31 - 16; j > -1; j = j-1)
				t[j] = op[j+16];
			op = sa[4]==1?t:op;
			if (f==1) begin
				outFifo.enq(op);
			end
		end
	endrule
	
	method Action shift_request(Bit#(32) operand, Bit#(5) shamt, Bit#(1) val);
		inFifo.enq(tuple3(operand, shamt, val));
	endmethod

	method ActionValue#(Bit#(32)) shift_response();
		outFifo.deq;
		return outFifo.first;
	endmethod
endmodule

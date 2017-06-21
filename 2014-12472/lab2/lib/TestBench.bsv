import BarrelShifterPipelined::*;
import BarrelShifterLeft::*;
import Rand::*;
import FIFO::*;

(* synthesize *)
module mkTbLeft();
	BarrelShifterLeft bsl <- mkBarrelShifterLeft;

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
			let implResultL <- bsl.leftShift(val, shift);
			let trueResultL = (val << shift);
			if(implResultL != trueResultL)
			begin
				$display("FAILED Left Shift %b << %d gave %b instead of %b", val, shift, implResultL, trueResultL);
				$finish;
			end
			cycle <= cycle + 1;
		end
	endrule
endmodule

(* synthesize *)
module mkTbLeftPipelined();
	BarrelShifterLeftPipelined bslp <- mkBarrelShifterLeftPipelined;

	Reg#(Bit#(32)) input_cycle <- mkReg(0);
	Reg#(Bit#(32)) output_cycle <- mkReg(0);
	Rand#(32) randomVal <- mkRand('hdeadbeef);
	Rand#(5) randomShift <- mkRand('hcafebabe);

	let valFifo <- mkSizedFIFO(10);

	rule test_request(input_cycle < 128);
		let val <- randomVal.get;
		let shift <- randomShift.get;
		valFifo.enq(tuple2(val, shift));
		bslp.shift_request(val, shift);
		input_cycle <= input_cycle + 1;
	endrule

	rule test_response;
		if(output_cycle == 128)
		begin
			$display("PASSED");
			$finish;
		end
		else
		begin
			let implResult <- bslp.shift_response();
			match {.val, .shift} = valFifo.first;
			let trueResult = val << shift;
			if(implResult != trueResult)
			begin
				$display("FAILED Left Shift %b << %d gave %b instead of %b", val, shift, implResult, trueResult);
				$finish;
			end
			valFifo.deq;

			output_cycle <= output_cycle + 1;
		end
	endrule
endmodule

(* synthesize *)
module mkTbRightLogicalPipelined();
	BarrelShifterRightLogicalPipelined bsrlp <- mkBarrelShifterRightLogicalPipelined;

	Reg#(Bit#(32)) input_cycle <- mkReg(0);
	Reg#(Bit#(32)) output_cycle <- mkReg(0);
	Rand#(32) randomVal <- mkRand('hdeadbeef);
	Rand#(5) randomShift <- mkRand('hcafebabe);

	let valFifo <- mkSizedFIFO(10);

	rule test_request(input_cycle < 128);
		let val <- randomVal.get;
		let shift <- randomShift.get;
		valFifo.enq(tuple2(val, shift));
		bsrlp.shift_request(val, shift);
		input_cycle <= input_cycle + 1;
	endrule

	rule test_response;
		if(output_cycle == 128)
		begin
			$display("PASSED");
			$finish;
		end
		else
		begin
			let implResult <- bsrlp.shift_response();
			match {.val, .shift} = valFifo.first;
			let trueResult = val >> shift;

			if(implResult != trueResult)
			begin
				$display("FAILED Right Logical Shift %b >> %d gave %b instead of %b", val, shift, implResult, trueResult);
				$finish;
			end
			valFifo.deq;

			output_cycle <= output_cycle + 1;
		end
	endrule
endmodule

(* synthesize *)
module mkTbRightArithmeticPipelined();
	BarrelShifterRightArithmeticPipelined bsrap <- mkBarrelShifterRightArithmeticPipelined;

	Reg#(Bit#(32)) input_cycle <- mkReg(0);
	Reg#(Bit#(32)) output_cycle <- mkReg(0);
	Rand#(32) randomVal <- mkRand('hdeadbeef);
	Rand#(5) randomShift <- mkRand('hcafebabe);

	let valFifo <- mkSizedFIFO(10);

	rule test_request(input_cycle < 128);
		let val <- randomVal.get;
		let shift <- randomShift.get;
		valFifo.enq(tuple2(val, shift));
		bsrap.shift_request(val, shift);
		input_cycle <= input_cycle + 1;
	endrule

	rule test_response;
		if(output_cycle == 128)
		begin
			$display("PASSED");
			$finish;
		end
		else
		begin
			let implResult <- bsrap.shift_response();
			match {.val, .shift} = valFifo.first;
			Int#(32) valNew = unpack(val);
			let trueResult = pack(valNew >> shift);

			if(implResult != trueResult)
			begin
				$display("FAILED Right Arithmetic Shift %b >> %d gave %b instead of %b", val, shift, implResult, trueResult);
				$finish;
			end
			valFifo.deq;

			output_cycle <= output_cycle + 1;
		end
	endrule
endmodule

(* synthesize *)
module mkTbDisplayCycle();
	BarrelShifterLeftPipelined bslp <- mkBarrelShifterLeftPipelined;

	Reg#(Bit#(32)) input_cycle <- mkReg(0);
	Reg#(Bit#(32)) output_cycle <- mkReg(0);
	Reg#(Bit#(32)) cycle <- mkReg(0);
	Rand#(32) randomVal <- mkRand('hdeadbeef);
	Rand#(5) randomShift <- mkRand('hcafebabe);

	let valFifo <- mkSizedFIFO(10);

	rule cycle_display;
		$display("==========================");
    $display("cycle         : %d",cycle+1);
    cycle <= cycle + 1;
	endrule

	rule test_request(input_cycle < 10);
		let val <- randomVal.get;
		let shift <- randomShift.get;
		valFifo.enq(tuple2(val, shift));
		bslp.shift_request(val, shift);
    $display("input_request : %d",val);
		input_cycle <= input_cycle + 1;
	endrule

	rule test_response;
		if(output_cycle == 10)
		begin
			$display("PASSED");
			$finish;
		end
		else
		begin
			let implResult <- bslp.shift_response();
			match {.val, .shift} = valFifo.first;
			let trueResult = val << shift;
			if(implResult != trueResult)
			begin
				$display("FAILED Left Shift %b << %d gave %b instead of %b", val, shift, implResult, trueResult);
				$finish;
			end
      else
      begin
      		$display("response      : %d", implResult);
      end
			valFifo.deq;

			output_cycle <= output_cycle + 1;
		end
	endrule
endmodule
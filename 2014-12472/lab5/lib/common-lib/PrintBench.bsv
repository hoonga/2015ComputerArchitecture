
import Types::*;

interface PrintBench;
	method Action reqPrint(Data call, Data ret, Data jmp, Data mem);


endinterface


module mkPrintBench(PrintBench);


	method Action reqPrint(Data call, Data ret, Data jmp, Data mem);
		$display("Call	:%d",call);


	endmethod


endmodule


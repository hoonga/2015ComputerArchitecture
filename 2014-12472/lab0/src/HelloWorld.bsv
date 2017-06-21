package HelloWorld;
	String hello = "HelloWorld";
	String bye = "Bye";
	(* synthesize *)
	module mkHelloWorld(Empty);
	Reg#(Bit#(3))c<-mkReg(0);
		rule say_hello(c<5);
			$display(hello);
			c<=c+1;
		endrule
		rule say_goodbye(c==5);
			$display(bye);
			$finish;
		endrule
	endmodule
endpackage

import Vector::*;
import Complex::*;
import Real::*;

import FftCommon::*;
import Fft::*;
import Rand::*;

module mkTestBench#(Fft fft)();
  let fft_comb <- mkFftCombinational;
  
  Vector#(FftPoints, Rand#(DataSz)) randomVal1 <- replicateM(mkRand('hdeadbeef));
  Vector#(FftPoints, Rand#(DataSz)) randomVal2 <- replicateM(mkRand('hcafebabe));

  Reg#(Bit#(8)) stream_count <- mkReg(0);
  Reg#(Bit#(8)) feed_count <- mkReg(0);

  rule feed(feed_count < 128);
    Vector#(FftPoints, ComplexData) d;
    for (Integer i = 0; i < fftPoints; i = i + 1 )
    begin
      let rv <- randomVal1[i].get;
      let iv <- randomVal2[i].get;
      d[i] = cmplx(rv, iv);
    end
    fft_comb.enq(d);
    fft.enq(d);
    feed_count <= feed_count + 1;
  endrule

  rule stream;
    stream_count <= stream_count + 1;
    let rc <- fft_comb.deq;
    let rf <- fft.deq;
    if ( rc != rf ) 
    begin
      $display("FAILED!");
      for (Integer i = 0; i < fftPoints; i = i + 1)
        $display ("\t(%x, %x) != (%x, %x)", rc[i].rel, rc[i].img, rf[i].rel, rf[i].img);
      $finish;
    end
  endrule

  rule pass (stream_count == 128);
    $display("PASSED");
    $finish;
  endrule
endmodule

`ifdef Folded
(* synthesize *)
module mkTbFftFolded();
  let fft <- mkFftFolded;
  mkTestBench(fft);
endmodule
`endif

`ifdef Pipelined
(* synthesize *)
module mkTbFftPipelined();
  let fft <- mkFftPipelined;
  mkTestBench(fft);
endmodule
`endif

`ifdef SuperFolded1
(* synthesize *)
module mkTbFftSuperFolded1();
  SuperFoldedFft#(1) sfFft <- mkFftSuperFolded;
  mkTestBench(getFft(sfFft));
endmodule
`endif

`ifdef SuperFolded2
(* synthesize *)
module mkTbFftSuperFolded2();
  SuperFoldedFft#(2) sfFft <- mkFftSuperFolded;
  mkTestBench(getFft(sfFft));
endmodule
`endif

`ifdef SuperFolded4
(* synthesize *)
module mkTbFftSuperFolded4();
  SuperFoldedFft#(4) sfFft <- mkFftSuperFolded;
  mkTestBench(getFft(sfFft));
endmodule
`endif

`ifdef SuperFolded8
(* synthesize *)
module mkTbFftSuperFolded8();
  SuperFoldedFft#(8) sfFft <- mkFftSuperFolded;
  mkTestBench(getFft(sfFft));
endmodule
`endif

`ifdef SuperFolded16
(* synthesize *)
module mkTbFftSuperFolded16();
  SuperFoldedFft#(16) sfFft <- mkFftSuperFolded;
  mkTestBench(getFft(sfFft));
endmodule
`endif

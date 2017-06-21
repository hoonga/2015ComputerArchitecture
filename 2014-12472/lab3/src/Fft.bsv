import Vector::*;

import FftCommon::*;
import Fifo::*;

interface Fft;
  method Action enq(Vector#(FftPoints, ComplexData) in);
  method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
endinterface

(* synthesize *)
module mkFftCombinational(Fft);
  Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
  Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
  Vector#(NumStages, Vector#(BflysPerStage, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));

  function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
    Vector#(FftPoints, ComplexData) stage_temp, stage_out;
    for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)
    begin
      FftIdx idx = i * 4;
      Vector#(4, ComplexData) x;
      Vector#(4, ComplexData) twid;
      for (FftIdx j = 0; j < 4; j = j + 1 )
      begin
        x[j] = stage_in[idx+j];
        twid[j] = getTwiddle(stage, idx+j);
      end
      let y = bfly[stage][i].bfly4(twid, x);

      for(FftIdx j = 0; j < 4; j = j + 1 )
        stage_temp[idx+j] = y[j];
    end

    stage_out = permute(stage_temp);

    return stage_out;
  endfunction
  
  rule doFft;
    inFifo.deq;
    Vector#(4, Vector#(FftPoints, ComplexData)) stage_data;
    stage_data[0] = inFifo.first;

    for (StageIdx stage = 0; stage < 3; stage = stage + 1)
      stage_data[stage+1] = stage_f(stage, stage_data[stage]);
    outFifo.enq(stage_data[3]);
  endrule
  
  method Action enq(Vector#(FftPoints, ComplexData) in);
    inFifo.enq(in);
  endmethod

  method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
    outFifo.deq;
    return outFifo.first;
  endmethod
endmodule

(* synthesize *)
module mkFftFolded(Fft);
  Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
  Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
  Vector#(16, Bfly4) bfly <- replicateM(mkBfly4);
  // You can copy & paste the stage_f function in the combinational implementation. 
  function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
    Vector#(FftPoints, ComplexData) stage_temp, stage_out;
    for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)
    begin
      FftIdx idx = i * 4;
      Vector#(4, ComplexData) x;
      Vector#(4, ComplexData) twid;
      for (FftIdx j = 0; j < 4; j = j + 1 )
      begin
        x[j] = stage_in[idx+j];
        twid[j] = getTwiddle(stage, idx+j);
      end
      let y = bfly[i].bfly4(twid, x);

      for(FftIdx j = 0; j < 4; j = j + 1 )
        stage_temp[idx+j] = y[j];
    end

    stage_out = permute(stage_temp);

    return stage_out;
  endfunction
 
  Reg#(Vector#(FftPoints, ComplexData)) r <- mkRegU;
  Reg#(StageIdx) i <- mkReg(0);
  rule doFft;
    //TODO: Remove below two lines and Implement the rest of this module
    Vector#(FftPoints,ComplexData) inbuf;
    if(i==0)begin
        inbuf = inFifo.first();
        inFifo.deq();
    end else inbuf = r;
    let outbuf = stage_f(i,inbuf);
    if (i==2)
        outFifo.enq(outbuf);
    else r <= outbuf;
    i <= (i==2)?0:(i+1);
  endrule

  method Action enq(Vector#(FftPoints, ComplexData) in);
    inFifo.enq(in);
  endmethod

  method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
    outFifo.deq;
    return outFifo.first;
  endmethod
endmodule

(* synthesize *)
module mkFftPipelined(Fft);
  Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
  Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
  Vector#(3, Vector#(16, Bfly4)) bfly <- replicateM(replicateM(mkBfly4));
  // You can copy & paste the stage_f function in the combinational implementation.
  function Vector#(FftPoints, ComplexData) stage_f(StageIdx stage, Vector#(FftPoints, ComplexData) stage_in);
    Vector#(FftPoints, ComplexData) stage_temp, stage_out;
    for (FftIdx i = 0; i < fromInteger(valueOf(BflysPerStage)); i = i + 1)
    begin
      FftIdx idx = i * 4;
      Vector#(4, ComplexData) x;
      Vector#(4, ComplexData) twid;
      for (FftIdx j = 0; j < 4; j = j + 1 )
      begin
        x[j] = stage_in[idx+j];
        twid[j] = getTwiddle(stage, idx+j);
      end
      let y = bfly[stage][i].bfly4(twid, x);

      for(FftIdx j = 0; j < 4; j = j + 1 )
        stage_temp[idx+j] = y[j];
    end

    stage_out = permute(stage_temp);

    return stage_out;
  endfunction

  Reg#(Maybe#(Vector#(FftPoints, ComplexData))) r[2];
  r[1] <- mkRegU; r[0] <- mkRegU;
  rule doFft;
    //TODO: Remove below two lines Implement the rest of this module
    if (inFifo.notEmpty()) begin
        r[0] <= Valid(stage_f(0,inFifo.first()));
        inFifo.deq();
    end else r[0] <= Invalid;
    case(r[0]) matches
        tagged Valid .a : r[1] <= Valid(stage_f(1,a));
        tagged Invalid : r[1] <= Invalid;
    endcase
    case(r[1]) matches
        tagged Valid .b : outFifo.enq(stage_f(2,b));
    endcase
  endrule

  method Action enq(Vector#(FftPoints, ComplexData) in);
    inFifo.enq(in);
  endmethod

  method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
    outFifo.deq;
    return outFifo.first;
  endmethod
endmodule

interface SuperFoldedFft#(numeric type radix);
  method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
  method Action enq(Vector#(FftPoints, ComplexData) in);
endinterface

module mkFftSuperFolded(SuperFoldedFft#(radix)) provisos(Div#(TDiv#(FftPoints, 4), radix, times), Mul#(radix, times, TDiv#(FftPoints, 4)));
  Fifo#(2,Vector#(FftPoints, ComplexData)) inFifo <- mkCFFifo;
  Fifo#(2,Vector#(FftPoints, ComplexData)) outFifo <- mkCFFifo;
  Vector#(radix, Bfly4) bfly <- replicateM(mkBfly4);
  // You can copy & paste the stage_f function in the combinational implementation. 
  // but some modification would be needed to stage_f function in this implementation.
  // or divide stage_f function into doFft rule with appropriate modification.

  Reg#(Vector#(FftPoints,ComplexData)) r <- mkRegU;
  Reg#(FftIdx) fi <- mkReg(0);
  Reg#(StageIdx) si <- mkReg(0);

  function Vector#(FftPoints,ComplexData) stage_f(StageIdx stage, Vector#(FftPoints,ComplexData) stage_in);
      Vector#(FftPoints,ComplexData) temp = stage_in;
      for(FftIdx i = 0; i < fromInteger(valueOf(radix)); i=i+1)begin
          FftIdx idx = (fi+i)*4;
          Vector#(4,ComplexData) x;
          Vector#(4,ComplexData) twid;
          for(FftIdx j = 0; j < 4; j = j + 1) begin
              x[j] = stage_in[idx+j];
              twid[j] = getTwiddle(stage,(idx+j));
          end
          let y = bfly[i].bfly4(twid,x);
          for (FftIdx j = 0; j < 4; j = j + 1) begin
              temp[idx+j] = y[j];
          end
      end
      if (fi == 16 - fromInteger(valueOf(radix)))
          temp=permute(temp);
      return temp;
  endfunction
        
  FftIdx rad = fromInteger(valueOf(radix));
  rule doFft;
    //TODO: Remove below two lines Implement the rest of this module
    Vector#(FftPoints,ComplexData) in;
    Vector#(FftPoints,ComplexData) bflyed;
    
    if(si==0&&fi==0)begin
      in = inFifo.first();
      inFifo.deq();
    end else in = r;    
    bflyed = stage_f(si,in);
    if(si==2&&fi==(16-rad))
        outFifo.enq(bflyed);
    else
        r<=bflyed;
    fi <= (fi==16-rad)?0:(fi+rad);
    if(fi==(16-rad))
        si <= (si==2)?0:(si+1);
  endrule

  method Action enq(Vector#(FftPoints, ComplexData) in);
    inFifo.enq(in);
  endmethod

  method ActionValue#(Vector#(FftPoints, ComplexData)) deq;
    outFifo.deq;
    return outFifo.first;
  endmethod
endmodule

function Fft getFft(SuperFoldedFft#(radix) f);
  return (interface Fft;
    method enq = f.enq;
    method deq = f.deq;
  endinterface);
endfunction

(* synthesize *)
module mkFftSuperFolded4(Fft);
  SuperFoldedFft#(2) sfFft <- mkFftSuperFolded;
  // TODO: Change the number at SuperFoldedFft#(x) by 1, 2, 4, 8 to test polymorphism of your super folded implementation.
  return (getFft(sfFft));
endmodule

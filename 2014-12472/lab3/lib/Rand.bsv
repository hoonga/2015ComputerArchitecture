import Vector::*;

import "BDPI"
function Action setSeed(Bit#(32) seed);
import "BDPI"
function ActionValue#(Bit#(32)) getRandom();

interface Rand#(numeric type n);
  method ActionValue#(Bit#(n)) get;
endinterface

module mkRand#(Bit#(32) seed)(Rand#(n)) provisos(Div#(n, 32, num), Add#(a, n, TMul#(num, 32)));
  Reg#(Bool) init <- mkReg(False);

  rule initialize(!init);
    setSeed(seed);
    init <= True;
  endrule

  method ActionValue#(Bit#(n)) get if(init);
    Vector#(num, Bit#(32)) rands = newVector;
    for(Integer i = 0; i < valueOf(num); i = i + 1)
      rands[i] <- getRandom;
    return truncate(pack(rands));
  endmethod
endmodule

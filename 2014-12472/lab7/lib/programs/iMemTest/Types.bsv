import Vector::*;

typedef 48 InstSz;
typedef Bit#(InstSz) Inst;

typedef 32 AddrSz;
typedef Bit#(AddrSz) Addr;

typedef 32 DataSz;
typedef Bit#(DataSz) Data;

Bit#(48) eoa = signExtend(2'b11); //End of address



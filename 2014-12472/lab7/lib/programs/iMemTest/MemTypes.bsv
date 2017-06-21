import Types::*;

//IMemory Types
typedef 26 AddrBits;
typedef Bit#(AddrBits) MemIndx;
typedef Bit#(26) Memorysize;
typedef Bit#(16) InstPacket;
typedef Bit#(48) FullInst;


//DMemory Types
typedef Data Line;
typedef Line MemResp;

typedef enum {Ld, St} MemOp deriving(Eq,Bits);

typedef struct {
	MemOp op;
	Addr addr;
	Data data;
} MemReq deriving(Eq, Bits);


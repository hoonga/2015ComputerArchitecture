import Types::*;
import ProcTypes::*;
import Vector::*;


function DecodedInst decode(Inst inst,Addr pc);
	DecodedInst dInst = ?;
	let iCode = inst[47:44];
	let ifun  = inst[43:40];
	let rA    = inst[39:36];
	let rB    = inst[35:32];
	let imm   = little2BigEndian(inst[31:0]);
	let dest  = little2BigEndian(inst[39:8]);
        
	case (iCode)
	halt, nop :
	begin
		dInst.iType = case(iCode)
					 	 halt : Hlt; 
						 nop  : Nop;
					  endcase;
		dInst.oplFunc = FNop;
		dInst.condUsed = Al;
		dInst.valP = pc + 1;
		dInst.dstE = Invalid;
		dInst.dstM = Invalid;
		dInst.regA = Invalid;
		dInst.regB = Invalid;
		dInst.valC = Invalid;
	end

	// rrmovel included in cmov 
	irmovl :
	begin
		dInst.iType    = Rmov;
		dInst.oplFunc  = FNop;
		dInst.condUsed = Al;
		dInst.valP     = pc + 6;
		dInst.dstE     = validReg(rB);
		dInst.dstM     = Invalid;
		dInst.regA     = Invalid;
		dInst.regB     = Invalid;
		dInst.valC     = Valid(imm);
	end
	
	rmmovl :
	begin
		dInst.iType    = RMmov;
		dInst.oplFunc  = FAdd;
		dInst.condUsed = Al;
		dInst.valP     = pc + 6;
		dInst.dstE     = Invalid;
		dInst.dstM     = Invalid;
		dInst.regA     = validReg(rA);
		dInst.regB     = validReg(rB);
		dInst.valC     = Valid(imm);
	end

	mrmovl :
	begin
		dInst.iType    = MRmov;
		dInst.oplFunc  = FAdd;
		dInst.condUsed = Al;
		dInst.valP     = pc+6;
		dInst.dstE     = Invalid;
		dInst.dstM     = validReg(rA);
		dInst.regA     = Invalid;
		dInst.regB     = validReg(rB);
		dInst.valC     = Valid(imm);
	end

	cmov : // includes rrmovl(cmov under no condition)
	begin
		dInst.iType    = Cmov;	
		dInst.oplFunc  = FNop;
		dInst.condUsed = case(ifun)
				  fNcnd : Al; 
				  fLe   : Le;
				  fLt   : Lt;
				  fEq   : Eq;
				  fNeq  : Neq;
				  fGe   : Ge;
				  fGt   : Gt;
				endcase;	
		dInst.valP = pc + 2;
		dInst.dstE = validReg(rB);
		dInst.dstM = Invalid;
		dInst.regA = validReg(rA);
		dInst.regB = Invalid;
		dInst.valC = Invalid;
	end		

	opl :
	begin
		dInst.iType = Opl;
		dInst.oplFunc = case(ifun)
				  		  addc : FAdd;
			 	  		  subc : FSub;
				  		  andc : FAnd;
				  		  xorc : FXor;
						endcase;
		dInst.condUsed = Al;
		dInst.valP = pc + 2;
		dInst.dstE = validReg(rB);
		dInst.dstM = Invalid;
		dInst.regA = validReg(rA);
		dInst.regB = validReg(rB);
		dInst.valC = Invalid;
	end
	
	jmp :
	begin
		dInst.iType    = Jmp;
		dInst.oplFunc  = FNop;
		dInst.condUsed = case(ifun)
				  		   fNcnd : Al; 
				 		   fLe   : Le;
				  		   fLt   : Lt;
				  		   fEq   : Eq;
				  		   fNeq  : Neq;
				  		   fGe   : Ge;
				  		   fGt   : Gt;
						 endcase;	
		dInst.valP = pc + 5;
		dInst.dstE = Invalid;
		dInst.dstM = Invalid;
	    dInst.regA = Invalid;
		dInst.regB = Invalid;
		dInst.valC = Valid(dest);
	end
	
	push :
	begin
		dInst.iType = Push;
		dInst.oplFunc = FSub;
		dInst.condUsed = Al;
		dInst.valP = pc + 2;
		dInst.dstE = validReg(esp); 
		dInst.dstM = Invalid;
		dInst.regA = validReg(rA);
		dInst.regB = validReg(esp); 
		dInst.valC = Invalid;
	end

	pop :
	begin
		dInst.iType = (rA == esp)? Unsupported:Pop;
		dInst.oplFunc = FAdd;
		dInst.condUsed = Al;
		dInst.valP = pc + 2;
		dInst.dstE = validReg(esp);
		dInst.dstM = validReg(rA);
		dInst.regA = validReg(esp);
		dInst.regB = validReg(esp);
		dInst.valC = Invalid;
	end

	call, ret :
	begin

		case(iCode)
			call : begin
					 dInst.iType   = Call;
					 dInst.oplFunc = FSub;
					 dInst.valP    = pc + 5;
					 dInst.valC    = Valid(dest);
					 dInst.regA    = Invalid;
				   end
			ret : begin
					dInst.iType   = Ret;
					dInst.oplFunc = FAdd;
					dInst.valP    = pc + 1;
					dInst.valC    = Invalid;
					dInst.regA    = validReg(esp);
				  end
		endcase
		
		dInst.condUsed = Al;
		dInst.dstE     = validReg(esp);
		dInst.dstM     = Invalid; 
		dInst.regB     = validReg(esp);
	end

	copinst:
	begin
		dInst.iType = case(ifun)
					  	mtc0 : Mtc0; //Mtc0
					  	mfc0 : Mfc0; //Mfc0
				  	  endcase;
		dInst.oplFunc = FNop;
		dInst.condUsed = Al;
		dInst.valP = pc + 2;
		dInst.dstE = case(ifun) 
						mtc0 : validCop(rB);
						mfc0 : validReg(rB);
					 endcase;
		dInst.dstM = Invalid;
		dInst.regA = case(ifun)
						mtc0 : validReg(rA);
						mfc0 : validCop(rA);
					 endcase;
		dInst.regB = Invalid;
		dInst.valC = Invalid;
	end

	default :
        begin
		dInst.iType = Unsupported;
		dInst.oplFunc = FNop;
		dInst.condUsed = Al;
		dInst.valP = pc + 1;
		dInst.dstE = Invalid;
		dInst.dstM = Invalid;
		dInst.regA = Invalid;
		dInst.regB = Invalid;
		dInst.valC = Invalid;
	end
	endcase
	return dInst;
endfunction

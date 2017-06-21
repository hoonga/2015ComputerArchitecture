import Types::*;
import ProcTypes::*;
import Vector::*;

function OplRes evalOpl(Data a, Data b, OplFunc oplFunc);
	  Data res = case(oplFunc)
					FAdd : (a + b);
					FSub : (a - b);
					FAnd : (a & b);
					FXor : (a ^ b);
				 endcase;

	  Bool zf = (res == 0);
	  Bool sf = (res[31] == 1);
	  Bool of = ((a[31] == 0) && (b[31] == 0) && (res[31] ==1)) // a>0, b>0, res<0
				|| ((a[31] == 1) && (b[31] == 1) && (res[31] == 0)); // a<0, b<0, res>0

	  CondFlag flags = CondFlag{zf:zf, sf:sf, of:of};
	  
  return tuple2(flags, res);
endfunction	

function Bool evalCond(CondUsed cmpFn, CondFlag condFlag);
  let zf = condFlag.zf;
  let sf = condFlag.sf;
  let of = condFlag.of;

  let res = case(cmpFn) matches
     	      Al  : True;
			  Eq  : (!of && zf);
			  Neq : !zf;
			  Lt  : (sf && !zf);
			  Le  : ((sf && !zf) || (!of && zf));
			  Gt  : (!sf && !zf);
			  Ge  : ((!sf && !zf) || (!of && zf));
  			endcase;
  
  return res;
endfunction

function ExecInst exec(DecodedInst dInst, CondFlag currentFlags, Addr ppc);
	//Analyze decoded instruction
	
	let iType    = dInst.iType;
	let oplFunc  = dInst.oplFunc;
	let condUsed = dInst.condUsed;
	let dstE     = dInst.dstE;
	let dstM     = dInst.dstM;
    let valP     = dInst.valP;	
	let valA     = dInst.valA;
	let valB	 = dInst.valB;
	let valC	 = dInst.valC;
	let copVal   = dInst.copVal;

	ExecInst eInst = ?;

	if (oplFunc == FNop)
	begin
		eInst.valE = (iType == Rmov)? valC:valA;
		eInst.condFlag = currentFlags;
	end
	else
	begin	
		let aluA = case(iType)
					 Opl, RMmov, MRmov, Push, Pop, Call, Ret : validValue(valB);
					 Cmov : validValue(valA);
				   endcase;
		let aluB = case(iType)
					 Opl : validValue(valA);
					 Rmov, RMmov, MRmov : validValue(valC);
					 Push, Pop, Call, Ret : 4;
				   endcase;

		match {.newCondFlags, .valE} = evalOpl(aluA, aluB, oplFunc);

		eInst.valE = Valid(valE);

		eInst.condFlag = case(iType)
							Opl : newCondFlags;
							default : currentFlags;
		 			     endcase;
	end
	
	let condSatisfied = evalCond(condUsed, currentFlags);

	eInst.iType = iType;
	eInst.dstE = (iType == Cmov && !condSatisfied)? Invalid:dstE;
	eInst.dstM = dstM;
	eInst.valA = valA;
	eInst.valC = valC;
	eInst.valP = valP;

	eInst.memAddr = case(iType)
					  MRmov, RMmov, Push, Call : validValue(eInst.valE);
	  				  Pop, Ret : validValue(valA);
					endcase;

	eInst.nextPc = case(iType)
					Call : valC;
					Jmp  : (condSatisfied? valC : Valid(valP));
					Ret  : Invalid;
					default : Valid(valP);
				 endcase;

	eInst.mispredict = (!isValid(eInst.nextPc)) || (valP != validValue(eInst.nextPc));

	eInst.condSatisfied = condSatisfied;

	return eInst;
endfunction 

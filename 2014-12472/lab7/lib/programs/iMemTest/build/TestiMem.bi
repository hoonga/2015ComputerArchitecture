signature TestiMem where {
import ¶List®¶;
	      
import ¶PrimArray®¶;
		   
import ¶RegFile®¶;
		 
import ¶Vector®¶;
		
import Types;
	    
import MemTypes;
	       
import IMemory;
	      
interface (TestiMem.TestIMem :: *) = {
};
 
instance TestiMem ¶Prelude®¶.¶PrimMakeUndefined®¶ TestiMem.TestIMem;
								   
instance TestiMem ¶Prelude®¶.¶PrimDeepSeqCond®¶ TestiMem.TestIMem;
								 
instance TestiMem ¶Prelude®¶.¶PrimMakeUninitialized®¶ TestiMem.TestIMem;
								       
TestiMem.getOffSet :: Types.Inst -> Types.Addr;
					      
TestiMem.mkTest :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ TestiMem.TestIMem
}

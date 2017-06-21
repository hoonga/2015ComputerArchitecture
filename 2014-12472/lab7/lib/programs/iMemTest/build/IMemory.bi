signature IMemory where {
import ¶List®¶;
	      
import ¶PrimArray®¶;
		   
import ¶RegFile®¶;
		 
import ¶Vector®¶;
		
import Types;
	    
import MemTypes;
	       
interface (IMemory.IMemory :: *) = {
    IMemory.req :: Types.Addr -> MemTypes.FullInst {-# arg_names = [a] #-}
};
 
instance IMemory ¶Prelude®¶.¶PrimMakeUndefined®¶ IMemory.IMemory;
								
instance IMemory ¶Prelude®¶.¶PrimDeepSeqCond®¶ IMemory.IMemory;
							      
instance IMemory ¶Prelude®¶.¶PrimMakeUninitialized®¶ IMemory.IMemory;
								    
IMemory.mkIMemory :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) => _m__ IMemory.IMemory
}

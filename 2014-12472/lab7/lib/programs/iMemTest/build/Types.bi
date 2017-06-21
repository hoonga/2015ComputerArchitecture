signature Types where {
import ¶List®¶;
	      
import ¶PrimArray®¶;
		   
import ¶Vector®¶;
		
type (Types.InstSz :: #) = 48;
			     
type (Types.Inst :: *) = ¶Prelude®¶.¶Bit®¶ Types.InstSz;
						       
type (Types.AddrSz :: #) = 32;
			     
type (Types.Addr :: *) = ¶Prelude®¶.¶Bit®¶ Types.AddrSz;
						       
type (Types.DataSz :: #) = 32;
			     
type (Types.Data :: *) = ¶Prelude®¶.¶Bit®¶ Types.DataSz;
						       
Types.eoa :: ¶Prelude®¶.¶Bit®¶ 48
}

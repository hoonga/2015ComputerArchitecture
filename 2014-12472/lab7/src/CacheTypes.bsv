import Types::*;
import Vector::*;



typedef 4 CacheSets;
typedef 4 WordsPerBlock;  // You can change this from 2 to 32. It must be a power of 2

// Do not modify below
typedef 32 CacheEntries;  // Do not modify this constant
typedef Vector#(WordsPerBlock, Data) Line;
typedef Line MemResp;

typedef Bit#(TLog#(WordsPerBlock)) CacheBlockOffset;
typedef Bit#(TLog#(CacheSets)) CacheSetOffset;

/* Rows and tag size of cache should be modified considering block size and set-associativity of the cache */
typedef CacheEntries CacheRows;
typedef Bit#(TLog#(CacheRows)) CacheIndex;
typedef Bit#(TSub#(TSub#(TSub#(AddrSz, TLog#(CacheRows)),SizeOf#(CacheBlockOffset)),2)) CacheTag;

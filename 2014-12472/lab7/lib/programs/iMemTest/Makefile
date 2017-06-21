complie:
	mkdir -p build
	mkdir -p sim
	bsc -u -sim -bdir build Types.bsv 	
	bsc -u -sim -bdir build MemTypes.bsv 
	bsc -u -sim -bdir build IMemory.bsv

tb:
	bsc -bdir build -sim -g mkTest TestiMem.bsv
	bsc -u -sim -e mkTest -bdir build -simdir sim -o simOut build/*.ba
all: complie tb

clean: 
	rm -rf build sim*
	

.PHONY: all compile tb clean
.DEFAULT_GOAL := all

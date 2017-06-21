buildbase=../build
bdir=$(buildbase)/bdir
simdir=$(buildbase)/simdir

compile:
	mkdir -p $(simdir)
	mkdir -p $(bdir)
	rm -f $(buildbase)/*.cpp
	ln -sf ../lib/*.cpp ./$(buildbase)
	bsc -u -sim -bdir $(bdir) -info-dir $(buildbase) -simdir $(simdir) -vdir $(buildbase) -aggressive-conditions -p +:../lib: ../lib/TestBench.bsv

mul: compile
	bsc -sim -e mkTbMultiplexer -bdir $(bdir) -info-dir $(buildbase) -simdir $(simdir) -o simMul  $(buildbase)/*.cpp
	
rl: compile
	bsc -sim -e mkTbRightLogical -bdir $(bdir) -info-dir $(buildbase) -simdir $(simdir) -o simRl  $(buildbase)/*.cpp
	
ra: compile
	bsc -sim -e mkTbRightArith -bdir $(bdir) -info-dir $(buildbase) -simdir $(simdir) -o simRa  $(buildbase)/*.cpp

all: ra rl mul

clean:
	rm -rf $(buildbase) sim*

.PHONY: clean all ra rl mul compile
.DEFAULT_GOAL := all

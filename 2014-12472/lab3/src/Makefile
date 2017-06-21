buildbase = ../build
bdir = $(buildbase)/bdir
bindir = $(buildbase)/bindir
simdir = $(buildbase)/simdir
libbase = ../lib

compile:
	mkdir -p $(simdir)
	mkdir -p $(bdir)
	mkdir -p $(bindir)


fold: compile
	rm -rf $(bdir)/mkTbFftFolded* $(simdir)/* $(bindir)/simFold.so $(bindir)/simFold $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -D Folded -bdir $(bdir) -simdir $(simdir) -vdir $(buildbase) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -D Folded -bdir $(bdir) -simdir $(simdir) -p $(libbase):+ -o $(bindir)/simFold -e mkTbFftFolded $(bdir)/*.ba $(libbase)/*.cpp
	
pipe: compile
	rm -rf $(bdir)/mkTbFftPipelined* $(simdir)/* $(bindir)/simPipe.so $(bindir)/simPipe $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -D Pipelined -bdir $(bdir) -simdir $(simdir) -vdir $(buildbase) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -D Pipelined -e mkTbFftPipelined -bdir $(bdir) -simdir $(simdir) -p $(libbase):+ -o $(bindir)/simPipe $(bdir)/*.ba $(libbase)/*.cpp

sfol1: compile
	rm -rf $(bdir)/mkTbFftSuperFolded* $(simdir)/* $(bindir)/simSfol.so $(bindir)/simSfol $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -D SuperFolded1 -bdir $(bdir) -simdir $(simdir) -vdir $(buildbase) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -D SuperFolded1 -e mkTbFftSuperFolded1 -bdir $(bdir) -simdir $(simdir) -p $(libbase):+ -o $(bindir)/simSfol $(bdir)/*.ba $(libbase)/*.cpp

sfol2: compile
	rm -rf $(bdir)/mkTbFftSuperFolded* $(simdir)/* $(bindir)/simSfol.so $(bindir)/simSfol $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -D SuperFolded2 -bdir $(bdir) -simdir $(simdir) -vdir $(buildbase) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -D SuperFolded2 -e mkTbFftSuperFolded2 -bdir $(bdir) -simdir $(simdir) -p $(libbase):+ -o $(bindir)/simSfol $(bdir)/*.ba $(libbase)/*.cpp

sfol4: compile
	rm -rf $(bdir)/mkTbFftSuperFolded* $(simdir)/* $(bindir)/simSfol.so $(bindir)/simSfol $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -D SuperFolded4 -bdir $(bdir) -simdir $(simdir) -vdir $(buildbase) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -D SuperFolded4 -e mkTbFftSuperFolded4 -bdir $(bdir) -simdir $(simdir) -p $(libbase):+ -o $(bindir)/simSfol $(bdir)/*.ba $(libbase)/*.cpp

sfol8: compile
	rm -rf $(bdir)/mkTbFftSuperFolded* $(simdir)/* $(bindir)/simSfol.so $(bindir)/simSfol $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -D SuperFolded8 -bdir $(bdir) -simdir $(simdir) -vdir $(buildbase) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -D SuperFolded8 -e mkTbFftSuperFolded8 -bdir $(bdir) -simdir $(simdir) -p $(libbase):+ -o $(bindir)/simSfol $(bdir)/*.ba $(libbase)/*.cpp

sfol16: compile
	rm -rf $(bdir)/mkTbFftSuperFolded* $(simdir)/* $(bindir)/simSfol.so $(bindir)/simSfol $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -D SuperFolded16 -bdir $(bdir) -simdir $(simdir) -vdir $(buildbase) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -D SuperFolded16 -e mkTbFftSuperFolded16 -bdir $(bdir) -simdir $(simdir) -p $(libbase):+ -o $(bindir)/simSfol $(bdir)/*.ba $(libbase)/*.cpp

sfol: sfol4

all: fold pipe sfol

clean:
	rm -rf $(bdir)/* $(simdir)/* $(bindir)/* $(libbase)/*.o

.PHONY: clean all comb compile
.DEFAULT_GOAL := all

buildbase = ../build
bdir = $(buildbase)/bdir
bindir = $(buildbase)/bindir
simdir = $(buildbase)/simdir
libbase = ../lib

left:
	rm -rf $(bdir)/mkBarrelShifterLeft* $(simdir)/* $(bindir)/simLeft.so $(bindir)/simLeft $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ -o $(bindir)/simLeft -e mkTbLeft $(bdir)/*.ba $(libbase)/*.cpp

lp:
	rm -rf $(bdir)/mkBarrelShifterLeftPipelined* $(simdir)/* $(bindir)/simLP.so $(bindir)/simLP $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ -o $(bindir)/simLP -e mkTbLeftPipelined $(bdir)/*.ba $(libbase)/*.cpp

rlp:
	rm -rf $(bdir)/mkBarrelShifterRightLogicalPipelined* $(simdir)/* $(bindir)/simRLP.so $(bindir)/simRLP $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ -o $(bindir)/simRLP -e mkTbRightLogicalPipelined $(bdir)/*.ba $(libbase)/*.cpp
rap:
	rm -rf $(bdir)/mkBarrelShifterRightArithmeticPipelined* $(simdir)/* $(bindir)/simRAP.so $(bindir)/simRAP $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ -o $(bindir)/simRAP -e mkTbRightArithmeticPipelined $(bdir)/*.ba $(libbase)/*.cpp

cycle:
	rm -rf $(bdir)/mkBarrelShifterLeftPipelined* $(simdir)/* $(bindir)/simLP.so $(bindir)/simLP $(libbase)/*.o
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ $(libbase)/TestBench.bsv
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ -o $(bindir)/simCYCLE -e mkTbDisplayCycle $(bdir)/*.ba $(libbase)/*.cpp


all: left lp rlp rap

clean:
	rm -rf $(bdir)/* $(simdir)/* $(bindir)/* $(libbase)/*.o

.PHONY: clean all left lp rlp rap
.DEFAULT_GOAL := all

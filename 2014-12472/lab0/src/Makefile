buildbase = ../build
bdir = $(buildbase)/bdir
simdir = $(buildbase)/simdir
libbase = ../lib

hello:
	rm -rf $(bdir)/* $(simdir)/* $(buildbase)/*.so 
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ ./HelloWorld.bsv
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ -o $(buildbase)/test_hello -e mkHelloWorld

hihihoho: 
	rm -rf $(bdir)/* $(simdir)/* $(buildbase)/*.so 
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ ./HiHiHoHo.bsv
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ -o $(buildbase)/test_hihihoho -e mkHiHiHoHo 

hihohiho:
	rm -rf $(bdir)/* $(simdir)/* $(buildbase)/*.so 
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ ./HiHoHiHo.bsv
	bsc -u -sim -aggressive-conditions -simdir $(simdir) -bdir $(bdir) -p $(libbase):+ -o $(buildbase)/test_hihohiho -e mkHiHoHiHo 

clean:
	rm -rf $(bdir)/* $(simdir)/* $(buildbase)/*.so $(buildbase)/test

.PHONY: a.out

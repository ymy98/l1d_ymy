RTL_COMPILE_OUTPUT 				= $(L1D_PATH)/work/rtl_compile
SIM_FILELIST 					= $(L1D_PATH)/l1d_filelist.f

.PHONY: compile

compile:
	mkdir -p $(RTL_COMPILE_OUTPUT)
	cd $(RTL_COMPILE_OUTPUT) ;vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -lca -kdb -debug_access -sverilog -f $(SIM_FILELIST) +lint=PCWM +lint=TFIPC-L +define+TOY_SIM -l compile.log

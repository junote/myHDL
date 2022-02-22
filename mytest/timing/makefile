all:compile elab sim

compile:
	xvlog --sv *.sv

elab:
	xelab -debug typical -top timing_tb -snapshot timing_tb

sim:
	xsim timing_tb --tclbatch tcl_xsim.tcl

gui:
	xsim --gui timing_tb.wdb

clean:
	rm xsim* -rf
	rm webtalk* -rf
	rm xvlog.*
	rm .Xil -rf
	rm wave* -rf
	rm xelab.*
	rm *.wdb

all:compile elab sim

compile:
	xvlog --sv *.sv

elab:
	xelab -debug typical -top wdg_tb -snapshot wdg_tb

sim:
	xsim wdg_tb --tclbatch tcl_xsim.tcl

gui:
	xsim --gui wdg_tb.wdb

clean:
	rm xsim* -rf
	rm webtalk* -rf
	rm xvlog.*
	rm .Xil -rf
	rm wave* -rf
	rm xelab.*
	rm *.wdb
	rm *.log

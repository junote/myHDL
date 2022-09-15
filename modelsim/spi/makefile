all:compile elab sim

compile:
	xvlog --sv *.sv

elab:
	xelab -debug typical -top spi_ctrl_tb -snapshot spi_ctrl_tb

sim:
	xsim spi_ctrl_tb --tclbatch tcl_xsim.tcl

gui:
	xsim --gui spi_ctrl_tb.wdb

clean:
	rm xsim* -rf
	rm webtalk* -rf
	rm xvlog.*
	rm .Xil -rf
	rm wave* -rf
	rm xelab.*
	rm *.wdb

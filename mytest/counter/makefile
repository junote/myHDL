all:
	# iverilog -o wave 19_pattern_moore.v PatternMoore.v PatternMealy.v fsm_tb.v
	iverilog -o wave counter_tb.v counter.v
	vvp wave
	gtkwave wave.vcd

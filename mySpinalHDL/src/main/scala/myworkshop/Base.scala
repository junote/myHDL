package myworkshop

import spinal.core._
import spinal.lib._
import spinal.lib.io.{TriState, TriStateArray, TriStateOutput}
import spinal.lib.fsm._
import javax.swing.text.html.parser.Entity

import spinal.sim._
import spinal.core.sim._
import scala.util.Random

class Inv(width: Int) extends Component {
  val io = new Bundle {
    val a = in Bits (width bits)
    val y = out Bits (width bits)
  }
  io.y := ~io.a;
}

class LogicGates extends Component {
  val io = new Bundle {
    val a, b = in Bits (4 bits)
    val y1, y2, y3, y4, y5 = out Bits (4 bits)

  }
  io.y1 := io.a & io.b;
  io.y2 := io.a | io.b;
  io.y3 := io.a ^ io.b; //xor
  io.y4 := ~(io.a & io.b); //nand
  io.y5 := ~(io.a | io.b); //nor
}

class ReduceN(width: Int) extends Component {
  val io = new Bundle {
    val a = in Bits (width bits)
    val y1, y2, y3 = out Bool
  }
  io.y1 := io.a.andR;
  io.y2 := io.a.orR;
  io.y3 := io.a.xorR;
}

class mux2(width: Int) extends Component {
  val io = new Bundle {
    val a, b = in Bits (width bits)
    val sel = in Bool
    val y1, y2, y3 = out Bits (width bits)
  }
  io.y1 := Mux(io.sel, io.a, io.b)
  io.y2 := io.sel ? io.a | io.b

  when(io.sel) {
    io.y3 := io.a
  }.otherwise {
    io.y3 := 0
  }
}

class TriExample extends Component {
  val io = new Bundle {
    val triPort = inout(Analog(Bool))
    val enout = in Bool
    val invalue = in Bool
    val outvalue = out Bool

  }

  // io.outvalue := io.triPort
  // when(io.enout) {
  //   io.triPort := io.invalue
  // }

  val triBus = TriState(Bool)
  triBus.read := io.triPort
  io.outvalue := triBus.read

  triBus.writeEnable := io.enout
  triBus.write := io.invalue
  when(triBus.writeEnable) {
    io.triPort := triBus.write
  }
}

class BitWise extends Component {
  val io = new Bundle {
    val a, b = in Bool
    val outab = out Bits (2 bits)

    val aa, bb = in Bits (3 bits)
    val outaabbc = out Bits (8 bits)

    val aaa, bbb = in UInt (3 bits)
    val out3 = out UInt (8 bits)

  }

  io.outab := (io.a ## io.b).asBits
  io.outaabbc := io.aa ## io.bb ## B"2'x3"
  io.out3 := io.aaa @@ io.bbb @@ U"2'x2"
}

class Inv2(width: Int) extends Component {
  val io = new Bundle {
    val a, b = in Bits (width bits)
    val y1, y2 = out Bits (width bits)
  }
  val inv1 = new Inv(width)
  inv1.io.a := io.a
  io.y1 := inv1.io.y
  val inv2 = new Inv(width)
  inv2.io.a := io.b
  io.y2 := inv2.io.y
}

class Flop(width: Int) extends Component {
  val io = new Bundle {
    val d = in UInt (width bits)
    val q = out UInt (width bits)
    val q2 = out UInt (width bits)
  }
  val tmp = Reg(UInt(width bits))
  tmp := io.d
  io.q := tmp

  io.q2 := RegNext(io.d)
}

class Flopr(width: Int) extends Component {
  val io = new Bundle {
    val d = in UInt (width bits)
    val q = out UInt (width bits)
  }
  io.q := RegNext(io.d) init (0)
}

class WhenExam(width: Int) extends Component {
  val io = new Bundle {
    val a, b, c = in UInt (width bits)
    val sel = in UInt (log2Up(width) bits)
    val outp = out UInt (width bits)
    val outp2 = out UInt (width bits)
    val outp3 = out UInt (width bits)
  }

  when(io.sel.resized === 2) {
    io.outp := io.a
  }.elsewhen(io.sel.resized === 1) {
    io.outp := io.b
  }.otherwise {
    io.outp := io.c
  }

  switch(io.sel.resize(8)) {
    is(U"8'x0") { io.outp2 := io.a }
    is(U"8'x1") { io.outp2 := io.b }
    default { io.outp2 := io.c }
  }

  //need to show all cases
  io.outp3 := io.sel
    .resize(2)
    .mux(
      U"2'x0" -> (io.a),
      U"2'x2" -> (io.b),
      U"2'x1" -> (io.c),
      U"2'x3" -> (io.c)
    )

}

class PatternMoore extends Component {
  val io = new Bundle {
    val a = in Bool
    val y = out Bool
  }
  val fsm = new StateMachine {
    io.y := False

    val state0: State = new State with EntryPoint {
      whenIsActive {
        when(io.a === True)(goto(state1))
        when(io.a === False)(goto(state0))
      }
    }

    val state1: State = new State {
      whenIsActive {
        when(io.a === True)(goto(state2))
        when(io.a === False)(goto(state0))
      }
    }

    val state2: State = new State {
      whenIsActive {
        when(io.a === True)(goto(state2))
        when(io.a === False)(goto(state3))
      }
    }
    val state3: State = new State {
      whenIsActive {
        when(io.a === True)(goto(state4))
        when(io.a === False)(goto(state0))
      }
    }
    val state4: State = new State {
      whenIsActive {
        when(io.a === True)(goto(state2))
        when(io.a === False)(goto(state0))
        io.y := True
      }
    }
  }
}


// not found how to use mealy machine
class PatternMealy extends Component {
  val io = new Bundle {
    val a = in Bool
    val y = out Bool
  }

  val fsm = new StateMachine {
    io.y := False

    val state0: State = new State with EntryPoint {
      whenIsActive {
        when(io.a === True)(goto(state1))
        when(io.a === False)(goto(state0))
      }

    }

    val state1: State = new State {
      whenIsActive {
        when(io.a === True)(goto(state2))
        when(io.a === False)(goto(state0))
      }
    }
    val state2: State = new State {
      whenIsActive {
        when(io.a === True)(goto(state2))
        when(io.a === False)(goto(state3))
      }
    }
    val state3: State = new State {
      whenIsActive {
        when(io.a === True){
          goto(state1)
          io.y := True
        }
        when(io.a === False)(goto(state0))
      }
    }
  }

}

//Generate the MyTopLevel's Verilog

/*
object MyBaseVerilog {
  def main(args: Array[String]) {
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new Inv(3))
    SpinalConfig(targetDirectory = "rtl").generateSystemVerilog(new LogicGates)
    SpinalConfig(targetDirectory = "rtl").generateSystemVerilog(new ReduceN(8))
    SpinalConfig(targetDirectory = "rtl").generateSystemVerilog(new mux2(8))
    SpinalConfig(targetDirectory = "rtl").generateSystemVerilog(new TriExample)
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new BitWise)
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new Inv2(4))
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new Flop(4))
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new Flopr(4))
    SpinalConfig(targetDirectory = "rtl").generateVerilog(
      new PatternMoore
    )
    SpinalConfig(targetDirectory = "rtl").generateVerilog(
      new PatternMealy
    )
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new WhenExam(4))
  }
}

object MySyncSpinalConfig
    extends SpinalConfig(
      defaultConfigForClockDomains =
        ClockDomainConfig(resetKind = SYNC, resetActiveLevel = LOW),
      targetDirectory = "rtl"
    )
object MySyncVerilogWithCustomConfig {
  def main(args: Array[String]) {
    MySyncSpinalConfig.generateVerilog(new Flopr(8))
  }
}

object MyFsmSim {
  def main(args: Array[String]) {
    SimConfig.withWave.doSim(new PatternMoore) { dut =>
      //Fork a process to generate the reset and the clock on the dut
      dut.clockDomain.forkStimulus(period = 10)

      var modelState = 0
      for (idx <- 0 to 99) {
        //Drive the dut inputs with random values
        dut.io.a #= Random.nextBoolean()

        //Wait a rising edge on the clock
        dut.clockDomain.waitRisingEdge()

      }
    }
  }
}

object MyFsmMealySim {
  def main(args: Array[String]) {
    SimConfig.withWave.doSim(new PatternMealy) { dut =>
      //Fork a process to generate the reset and the clock on the dut
      dut.clockDomain.forkStimulus(period = 10)

      var modelState = 0
      for (idx <- 0 to 99) {
        //Drive the dut inputs with random values
        dut.io.a #= Random.nextBoolean()

        //Wait a rising edge on the clock
        dut.clockDomain.waitRisingEdge()

      }
    }
  }
}
*/

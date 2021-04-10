package myworkshop

import spinal.core._
import spinal.lib._

class Adder(width: Int) extends Component {
  val io = new Bundle {
    val a, b = in UInt (width bits)
    val cin = in Bool
    val s = out UInt (width bits)
    val cout = out Bool
  }
  val tmp = UInt((width + 1) bits)
  tmp := io.a.resize(width + 1) + io.b.resize(width + 1) + io.cin.asUInt.resize(
    width + 1
  )
  io.s := tmp.resize(width)
  io.cout := tmp.msb
}

class Subtractor(width: Int) extends Component {
  val io = new Bundle {
    val a, b = in UInt (width bits)
    val y = out UInt (width bits)
  }
  io.y := io.a - io.b
}

class Comparator(width: Int) extends Component {
  val io = new Bundle {
    val a, b = in UInt (width bits)
    val eq, neq, lt, lte, gt, gte = out Bool
  }

  io.eq := (io.a === io.b)
  io.neq := (io.a =/= io.b)
  io.gt := (io.a > io.b)
  io.gte := (io.a >= io.b)
  io.lt := (io.a < io.b)
  io.lte := (io.a <= io.b)
}

class ShiftReg(width: Int) extends Component {
  val io = new Bundle {
    val load = in Bool
    val sin = in Bool
    val d = in UInt (width bits)
    val q = out UInt (width bits)
    val sout = out Bool
  }

  val tmp = Reg(UInt(width bits)) init (0)
  when(io.load) {
    tmp := io.d
  }.otherwise {
    tmp := (tmp((width - 2) downto 0) ## io.sin).asUInt
  }

  io.q := tmp
  io.sout := tmp.msb
}
class Counter(width: Int) extends Component {
  val io = new Bundle {
    val q = out UInt (width bits)
  }
  val qReg = Reg(UInt(width bits)) init (0)
  qReg := qReg + 1
  io.q := qReg
}

class RAM(dataWidth: Int, dataLenth: Int) extends Component {
  val io = new Bundle {
    val addr = in UInt (log2Up(dataLenth) bits)
    val dataIn = in UInt (dataWidth bits)
    val enWrite = in Bool
    val dataOut = out UInt (dataWidth bits)
    val enRead = in Bool
  }
  val mem = Mem(UInt(dataWidth bits), wordCount = dataLenth)
  mem.write(
    enable = io.enWrite,
    address = io.addr,
    data = io.dataIn
  )

  io.dataOut := mem.readSync(
    enable = io.enRead,
    address = io.addr
  )
}

class SinROM(resolutionWidth: Int, sampleCount: Int) extends Component {
  val io = new Bundle {
    val sin = out SInt (resolutionWidth bits)
  }

  def sinTable = for (sampleIndex <- 0 until sampleCount) yield {
    val sinValue = Math.sin(2 * Math.PI * sampleIndex / sampleCount)
    S((sinValue * ((1 << resolutionWidth) / 2 - 1)).toInt, resolutionWidth bits)
  }

  val rom = Mem(SInt(resolutionWidth bits), initialContent = sinTable)
  val phase = Reg(UInt(log2Up(sampleCount) bits)) init (0)
  phase := phase + 1

  io.sin := rom.readSync(phase)

}
object MyDigitalBlockVerilog {
  def main(args: Array[String]) {
    // SpinalConfig(targetDirectory = "rtl").generateVerilog(new Adder(4))
    // SpinalConfig(targetDirectory = "rtl").generateVerilog(new Subtractor(4))
    // SpinalConfig(targetDirectory = "rtl").generateVerilog(new Comparator(4))
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new ShiftReg(4))
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new Counter(4))
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new RAM(4, 16))
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new SinROM(8, 256))
  }
}

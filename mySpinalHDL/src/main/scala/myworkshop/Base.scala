package myworkshop

import spinal.core._
import spinal.lib._

class Inv(width:Int) extends Component {
  val io = new Bundle {
    val a = in  Bits(width bits)
    val y  = out Bits(width bits)
  }
  io.y := ~io.a;
}

class LogicGates extends Component {
  val io = new Bundle {
    val a,b = in  Bits(4 bits)
    val y1,y2,y3,y4,y5  = out Bits(4 bits)
    
  }
  io.y1 := io.a & io.b;
  io.y2 := io.a | io.b;
  io.y3 := io.a ^ io.b;//xor
  io.y4 := ~(io.a & io.b);//nand
  io.y5 := ~(io.a | io.b); //nor
}

class ReduceN(width:Int) extends Component {
  val io = new Bundle {
    val a = in  Bits(width bits)
    val y1,y2,y3  = out Bool
  }
  io.y1 := io.a.andR;
  io.y2 := io.a.orR;
  io.y3 := io.a.xorR;
}

class mux2(width:Int) extends Component {
  val io = new Bundle {
    val a,b = in  Bits(width bits)
    val sel = in Bool
    val y1,y2,y3  = out Bits(width bits)
  }
  io.y1 := Mux(io.sel,io.a,io.b)
  io.y2 := io.sel?io.a|io.b

  when(io.sel){
    io.y3 := io.a
  }.otherwise {
    io.y3 := 0
  }
}



//Generate the MyTopLevel's Verilog
object MyBaseVerilog {
  def main(args: Array[String]) {
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new Inv(3))
    SpinalConfig(targetDirectory = "rtl").generateSystemVerilog(new LogicGates)
    SpinalConfig(targetDirectory = "rtl").generateSystemVerilog(new ReduceN(8))
    SpinalConfig(targetDirectory = "rtl").generateSystemVerilog(new mux2(8))
  }
}

